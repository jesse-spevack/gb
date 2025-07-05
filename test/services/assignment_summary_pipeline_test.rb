# frozen_string_literal: true

require "test_helper"

class AssignmentSummaryPipelineTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
    @user = users(:teacher)

    # Setup sample student feedbacks
    @student_feedbacks = [
      {
        student_work: student_works(:student_essay_one),
        feedback: "Feedback provided",
        strengths: [ "Good understanding" ],
        areas_for_improvement: [ "Show more work" ]
      }
    ]
  end

  test "pipeline includes correct steps in proper sequence" do
    steps = AssignmentSummaryPipeline::STEPS

    # Check the proper sequence of steps
    assert_equal 5, steps.size, "Pipeline should have exactly 5 steps"

    # First step should be PromptInput::AssignmentSummary
    assert_equal PromptInput::AssignmentSummary, steps.first

    # Last step should be RecordMetricsService
    assert_equal RecordMetricsService, steps.last

    # Verify the LLM processing steps are included
    assert_includes steps, LLM::AssignmentSummary::Generator
    assert_includes steps, LLM::AssignmentSummary::ResponseParser

    # Verify storage step is included
    assert_includes steps, Pipeline::Storage::AssignmentSummaryService
  end

  test "pipeline structure follows standard pattern" do
    # Verify standard pipeline structure:
    # 1. Input preparation
    # 2. LLM generation
    # 3. Response parsing
    # 4. Storage
    # 5. Metrics recording

    steps = AssignmentSummaryPipeline::STEPS

    # Input step comes before LLM generation
    input_index = steps.index(PromptInput::AssignmentSummary)
    generator_index = steps.index(LLM::AssignmentSummary::Generator)
    assert input_index < generator_index

    # LLM generation comes before response parsing
    parser_index = steps.index(LLM::AssignmentSummary::ResponseParser)
    assert generator_index < parser_index

    # Response parsing comes before storage
    storage_index = steps.index(Pipeline::Storage::AssignmentSummaryService)
    assert parser_index < storage_index

    # Metrics recording is the final step
    metrics_index = steps.index(RecordMetricsService)
    assert_equal steps.size - 1, metrics_index
  end
end
