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
    assert_equal 7, steps.size, "Pipeline should have exactly 7 steps"

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

  test "pipeline includes broadcast steps at correct positions" do
    steps = AssignmentSummaryPipeline::STEPS

    # The second step should be a broadcast service for summary_started
    broadcast_started = steps[1]
    assert_kind_of BroadcastService.with(event: :test).class, broadcast_started
    assert_equal :summary_started, broadcast_started.instance_variable_get(:@event)

    # The second-to-last step should be a broadcast service for summary_completed
    broadcast_completed = steps[5]
    assert_kind_of BroadcastService.with(event: :test).class, broadcast_completed
    assert_equal :summary_completed, broadcast_completed.instance_variable_get(:@event)
  end

  test "pipeline structure follows standard pattern" do
    # Verify standard pipeline structure:
    # 1. Input preparation
    # 2. Start broadcast
    # 3. LLM generation
    # 4. Response parsing
    # 5. Storage
    # 6. Completion broadcast
    # 7. Metrics recording

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
