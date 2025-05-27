# frozen_string_literal: true

# Pipeline for processing assignment summary generation via LLM
# Includes broadcast steps for real-time updates and metrics recording
class AssignmentSummaryPipeline
  STEPS = [
    PromptInput::AssignmentSummary,
    BroadcastService.with(event: :summary_started),
    LLM::AssignmentSummary::Generator,
    LLM::AssignmentSummary::ResponseParser,
    Pipeline::Storage::AssignmentSummaryService,
    BroadcastService.with(event: :summary_completed),
    RecordMetricsService
  ].freeze

  def self.call(assignment:, student_feedbacks:, user:)
    context = create_context(assignment: assignment, student_feedbacks: student_feedbacks, user: user)

    begin
      execute_pipeline(context)
      build_success_result(context)
    rescue => e
      build_failure_result(context, e)
    end
  end

  private

  def self.execute_pipeline(context)
    STEPS.each do |step|
      context = step.call(context: context)
    end
  end

  def self.create_context(assignment:, student_feedbacks:, user:)
    context = Pipeline::Context::AssignmentSummary.new
    context.assignment = assignment
    context.student_feedbacks = student_feedbacks
    context.user = user
    context
  end

  def self.build_success_result(context)
    Pipeline::ProcessingResult.new(
      success: true,
      data: extract_result_data(context),
      errors: [],
      metrics: context.metrics
    )
  end

  def self.build_failure_result(context, error)
    Rails.logger.error("AssignmentSummaryPipeline error: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n")) if error.backtrace

    Pipeline::ProcessingResult.new(
      success: false,
      data: nil,
      errors: [ error.message ],
      metrics: context&.metrics || {}
    )
  end

  def self.extract_result_data(context)
    context.saved_summary
  end
end
