# frozen_string_literal: true

# Service for recording performance metrics from pipeline execution
# Captures timing data and persists it for reporting
class RecordMetricsService
  attr_reader :context

  def self.call(context:)
    new(context).call
  end

  def initialize(context)
    @context = context
  end

  def call
    ProcessingMetric.create!(
      processable: processable,
      assignment: assignment,
      user: assignment&.user,
      status: determine_status,
      total_duration_ms: total_duration_ms,
      llm_duration_ms: llm_request_ms,
      metrics_data: build_metrics_data,
      recorded_at: Time.current
    )

    context
  end

  private

  def processable
    if context.respond_to?(:processable) && context.processable
      # If the context has its own processable method, use that
      context.processable
    elsif context.respond_to?(:rubric) && context.rubric
      context.rubric
    elsif context.respond_to?(:student_work) && context.student_work
      context.student_work
    elsif context.respond_to?(:assignment_summary) && context.assignment_summary
      context.assignment_summary
    else
      context.assignment
    end
  end

  def assignment
    processable.is_a?(Assignment) ? processable : processable.assignment
  end

  def determine_status
    if context.respond_to?(:errors) && !context.errors.empty?
      :failed
    elsif context.respond_to?(:parsed_response) && context.parsed_response.present?
      :completed
    else
      :pending
    end
  end

  def total_duration_ms
    begin
      if context.respond_to?(:total_duration_ms) && context.total_duration_ms
        context.total_duration_ms.to_i
      elsif context.respond_to?(:started_at) && context.started_at
        ((Time.current - context.started_at) * 1000).to_i
      else
        0
      end
    rescue
      # Gracefully handle any errors that might occur when calculating duration
      0
    end
  end

  def llm_request_ms
    if context.respond_to?(:metrics) && context.metrics
      context.metrics[:llm_request_ms] || 0
    else
      0
    end
  end

  def build_metrics_data
    {
      pipeline_type: pipeline_type,
      timestamp: Time.current,
      tokens_used: context.respond_to?(:metrics) ? context.metrics[:tokens_used] : nil,
      raw_metrics: context.respond_to?(:metrics) ? context.metrics : {}
    }.compact
  end

  def pipeline_type
    case processable
    when Rubric then "rubric_generation"
    when StudentWork then "student_feedback"
    when AssignmentSummary then "summary_generation"
    when Assignment then "assignment_processing"
    else "unknown"
    end
  end
end
