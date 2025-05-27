# frozen_string_literal: true

# Pipeline for processing rubric generation via LLM
# Includes broadcast steps for real-time updates and metrics recording
class RubricPipeline
  STEPS = [
    PromptInput::Rubric,
    BroadcastService.with(event: :rubric_started),
    LLM::Rubric::Generator,
    LLM::Rubric::ResponseParser,
    Pipeline::Storage::RubricService,
    BroadcastService.with(event: :rubric_completed),
    RecordMetricsService
  ].freeze

  def self.call(assignment:, user:)
    context = create_context(assignment: assignment, user: user)

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

  def self.create_context(assignment:, user:)
    context = Pipeline::Context::Rubric.new
    context.assignment = assignment
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
    Rails.logger.error("RubricPipeline error: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n")) if error.backtrace

    Pipeline::ProcessingResult.new(
      success: false,
      data: nil,
      errors: [ error.message ],
      metrics: context&.metrics || {}
    )
  end

  def self.extract_result_data(context)
    context.rubric
  end
end
