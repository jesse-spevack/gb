# frozen_string_literal: true

# Pipeline for processing student work feedback generation via LLM
# Includes broadcast steps for real-time updates and metrics recording
class StudentWorkFeedbackPipeline
  STEPS = [
    PromptInput::StudentWork,
    LLM::StudentWork::Generator,
    LLM::StudentWork::ResponseParser,
    Pipeline::Storage::StudentWorkService,
    RecordMetricsService
  ].freeze

  def self.call(student_work:, rubric:, user:)
    context = create_context(student_work: student_work, rubric: rubric, user: user)

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

  def self.create_context(student_work:, rubric:, user:)
    context = Pipeline::Context::StudentWork.new
    context.student_work = student_work
    context.rubric = rubric
    context.user = user
    context.assignment = student_work.assignment
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
    Rails.logger.error("StudentWorkFeedbackPipeline error: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n")) if error.backtrace

    Pipeline::ProcessingResult.new(
      success: false,
      data: nil,
      errors: [ error.message ],
      metrics: context&.metrics || {}
    )
  end

  def self.extract_result_data(context)
    context.saved_feedback
  end
end
