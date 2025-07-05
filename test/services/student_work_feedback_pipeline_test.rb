# frozen_string_literal: true

require "test_helper"

class StudentWorkFeedbackPipelineTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
    @rubric = rubrics(:english_essay_rubric)
    @student_work = student_works(:student_essay_one)
    @user = users(:teacher)
  end

  test "pipeline includes correct steps in proper sequence" do
    steps = StudentWorkFeedbackPipeline::STEPS

    # Check the proper sequence of steps
    assert_equal 5, steps.size, "Pipeline should have exactly 5 steps"

    # First step should be PromptInput::StudentWork
    assert_equal PromptInput::StudentWork, steps.first

    # Last step should be RecordMetricsService
    assert_equal RecordMetricsService, steps.last

    # Verify the LLM processing steps are included
    assert_includes steps, LLM::StudentWork::Generator
    assert_includes steps, LLM::StudentWork::ResponseParser

    # Verify storage step is included
    assert_includes steps, Pipeline::Storage::StudentWorkService
  end


  test "pipeline structure follows standard pattern" do
    # Verify standard pipeline structure:
    # 1. Input preparation
    # 2. LLM generation
    # 3. Response parsing
    # 4. Storage
    # 5. Metrics recording

    steps = StudentWorkFeedbackPipeline::STEPS

    # Input step comes before LLM generation
    input_index = steps.index(PromptInput::StudentWork)
    generator_index = steps.index(LLM::StudentWork::Generator)
    assert input_index < generator_index

    # LLM generation comes before response parsing
    parser_index = steps.index(LLM::StudentWork::ResponseParser)
    assert generator_index < parser_index

    # Response parsing comes before storage
    storage_index = steps.index(Pipeline::Storage::StudentWorkService)
    assert parser_index < storage_index

    # Metrics recording is the final step
    metrics_index = steps.index(RecordMetricsService)
    assert_equal steps.size - 1, metrics_index
  end
end
