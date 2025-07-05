# frozen_string_literal: true

require "ostruct"

# Main orchestrator for automating the entire grading process
# Coordinates sequential execution of RubricPipeline, StudentWorkFeedbackPipeline, and AssignmentSummaryPipeline
class AssignmentProcessor
  class PipelineFailureError < StandardError; end
  def initialize(assignment_id)
    @assignment = Assignment.find(assignment_id)
    @rubric_result = nil
    @rubric_context = nil
    @student_feedback_results = []
    @assignment_summary_result = nil
  end

  # Main entry point for processing an assignment
  # Returns a Pipeline::ProcessingResult object
  def process
    start_time = Time.current

    begin
      update_processing_step(step_key: "assignment_saved", status: "completed")
      update_processing_step(step_key: "creating_rubric", status: "in_progress")

      process_pipelines
      result = build_success_result

      # Record overall assignment processing metrics
      record_overall_metrics(start_time, true)

      result
    rescue => e
      result = build_failure_result(e)

      # Record overall assignment processing metrics even on failure
      record_overall_metrics(start_time, false)

      result
    end
  end

  private

  attr_reader :assignment, :rubric_result, :student_feedback_results, :assignment_summary_result

  # Orchestrates the execution of all three pipelines in sequence
  def process_pipelines
    # Execute RubricPipeline
    execute_rubric_pipeline
    # Stop processing if rubric generation failed
    raise PipelineFailureError, format_pipeline_errors("RubricPipeline", @rubric_result) unless @rubric_result.successful?

    update_processing_step(step_key: "creating_rubric", status: "completed")
    update_processing_step(step_key: "generating_feedback", status: "in_progress")

    # Execute StudentWorkFeedbackPipeline for each student work
    execute_student_feedback_pipelines if @rubric_context

    update_processing_step(step_key: "generating_feedback", status: "completed")
    update_processing_step(step_key: "summarizing_feedback", status: "in_progress")

    # Execute AssignmentSummaryPipeline
    execute_assignment_summary_pipeline

    update_processing_step(step_key: "summarizing_feedback", status: "completed")

    # Check if summary generation failed (critical failure)
    if @assignment_summary_result && !@assignment_summary_result.successful?
      raise PipelineFailureError, format_pipeline_errors("AssignmentSummaryPipeline", @assignment_summary_result)
    end
  end

  # Executes the RubricPipeline and stores the result
  def execute_rubric_pipeline
    @rubric_result = RubricPipeline.call(
      assignment: assignment,
      user: assignment.user
    )

    # Record metrics for rubric generation
    record_pipeline_metrics(assignment, "rubric_generation", @rubric_result)

    # Extract rubric context for use in subsequent pipelines
    @rubric_context = @rubric_result.data if @rubric_result.successful?
  end

  # Executes StudentWorkFeedbackPipeline for each student work sequentially
  def execute_student_feedback_pipelines
    total_count = assignment.student_works.count

    assignment.student_works.each_with_index do |student_work, index|
      begin
        result = StudentWorkFeedbackPipeline.call(
          student_work: student_work,
          rubric: @rubric_context,
          user: assignment.user
        )

        # Record metrics for student feedback generation
        record_pipeline_metrics(student_work, "student_feedback_generation", result)

        @student_feedback_results << result
      rescue => e
        # Log the error but continue processing other students
        Rails.logger.error("StudentWorkFeedbackPipeline error for student work #{student_work.id}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n")) if e.backtrace

        # Create a failure result for this student
        failure_result = Pipeline::ProcessingResult.new(
          success: false,
          data: nil,
          errors: [ e.message ],
          metrics: { "error_type" => e.class.name }
        )

        # Record metrics for the exception
        record_pipeline_metrics(student_work, "student_feedback_generation", failure_result)

        @student_feedback_results << failure_result
      end
    end
  end

  # Executes the AssignmentSummaryPipeline with aggregated student contexts
  def execute_assignment_summary_pipeline
    # Extract successful student feedback data
    student_feedbacks = @student_feedback_results
      .select(&:successful?)
      .map(&:data)
      .compact

    @assignment_summary_result = AssignmentSummaryPipeline.call(
      assignment: assignment,
      student_feedbacks: student_feedbacks,
      user: assignment.user
    )

    # Record metrics for assignment summary generation
    record_pipeline_metrics(assignment, "assignment_summary_generation", @assignment_summary_result)
  end

  # Builds a successful result with aggregated data from all pipelines
  def build_success_result
    Pipeline::ProcessingResult.new(
      success: true,
      data: aggregate_results,
      errors: [],
      metrics: aggregate_metrics
    )
  end

  # Formats pipeline errors for failure messages
  def format_pipeline_errors(pipeline_name, result)
    return "#{pipeline_name} failed" unless result&.errors&.any?
    "#{pipeline_name} failed: #{result.errors.join(', ')}"
  end

  # Builds a failure result with error information
  def build_failure_result(error)
    Rails.logger.error("AssignmentProcessor error: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n")) if error.backtrace

    Pipeline::ProcessingResult.new(
      success: false,
      data: aggregate_results,  # Include any successful results
      errors: [ error.message ],
      metrics: aggregate_metrics  # Include metrics from all executed pipelines
    )
  end

  # Aggregates results from all pipelines into a single data structure
  def aggregate_results
    {
      rubric: rubric_result&.data,
      student_feedbacks: student_feedback_results.compact.map(&:data).compact,
      assignment_summary: assignment_summary_result&.data
    }
  end

  # Aggregates metrics from all pipelines
  def aggregate_metrics
    metrics = {}

    # Add rubric pipeline metrics
    metrics.merge!(prefix_metrics(rubric_result&.metrics || {}, "rubric"))

    # Add student feedback metrics
    student_feedback_results.compact.each_with_index do |result, index|
      metrics.merge!(prefix_metrics(result.metrics || {}, "student_#{index}"))
    end

    # Add assignment summary metrics
    metrics.merge!(prefix_metrics(assignment_summary_result&.metrics || {}, "summary"))

    # Add total processing time
    metrics["total_duration_ms"] = calculate_total_duration

    metrics
  end

  # Prefixes metric keys to avoid collisions
  def prefix_metrics(metrics, prefix)
    metrics.transform_keys { |key| "#{prefix}_#{key}" }
  end

  # Calculates total processing duration across all pipelines
  def calculate_total_duration
    total = 0
    total += rubric_result&.timing_ms || 0
    total += student_feedback_results.compact.sum { |r| r.timing_ms || 0 }
    total += assignment_summary_result&.timing_ms || 0
    total
  end

  # Records metrics for a pipeline execution
  def record_pipeline_metrics(processable, process_type, result)
    # Create a context object that matches RecordMetricsService expectations
    context = OpenStruct.new(
      processable: processable,
      assignment: processable.is_a?(Assignment) ? processable : processable.assignment,
      metrics: result.metrics || {},
      errors: result.successful? ? [] : (result.errors || [])
    )

    RecordMetricsService.call(context: context)
  rescue => e
    # Log but don't fail if metrics recording fails
    Rails.logger.error("Failed to record metrics: #{e.message}")
  end

  # Records overall assignment processing metrics
  def record_overall_metrics(start_time, success)
    end_time = Time.current
    total_duration = ((end_time - start_time) * 1000).round # Convert to milliseconds

    # Calculate aggregated metrics
    total_tokens = 0
    pipeline_count = 0

    # Count rubric pipeline
    if rubric_result
      pipeline_count += 1
      total_tokens += (rubric_result.metrics || {})["tokens_used"] || 0
    end

    # Count student feedback pipelines
    student_feedback_results.compact.each do |result|
      pipeline_count += 1
      total_tokens += (result.metrics || {})["tokens_used"] || 0
    end

    # Count assignment summary pipeline
    if assignment_summary_result
      pipeline_count += 1
      total_tokens += (assignment_summary_result.metrics || {})["tokens_used"] || 0
    end

    overall_metrics = {
      "total_duration_ms" => total_duration,
      "total_tokens_used" => total_tokens,
      "pipeline_count" => pipeline_count,
      "student_count" => assignment.student_works.count,
      "started_at" => start_time.iso8601,
      "completed_at" => end_time.iso8601
    }

    record_pipeline_metrics(assignment, "assignment_processing",
      OpenStruct.new(metrics: overall_metrics, successful?: success))
  end

  def update_processing_step(step_key:, status:)
    step = assignment.processing_steps.find_by(step_key: step_key)
    return unless step

    case status
    when "in_progress"
      step.update!(status: "in_progress", started_at: Time.current)
    when "completed"
      step.update!(status: "completed", completed_at: Time.current)
    else
      step.update!(status: status)
    end

    # Check if all steps are completed after this update (reload to get fresh data)
    if assignment.processing_steps.reload.all?(&:completed?)
      # All steps complete - broadcast the assignment content
      Turbo::StreamsChannel.broadcast_replace_to(
        "assignment_#{assignment.id}_steps",
        target: "assignment-content-container",
        partial: "assignments/assignment_content",
        locals: { assignment: assignment }
      )
    else
      # Still processing - broadcast the processing steps
      Turbo::StreamsChannel.broadcast_replace_to(
        "assignment_#{assignment.id}_steps",
        target: "assignment-processing-steps",
        partial: "assignments/processing_steps",
        locals: { processing_steps: assignment.processing_steps.ordered }
      )
    end
  end
end
