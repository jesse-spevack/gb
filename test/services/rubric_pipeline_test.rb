# frozen_string_literal: true

require "test_helper"

class RubricPipelineTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  def setup
    @assignment = assignments(:english_essay)
    @user = users(:teacher)
  end

  test "pipeline includes broadcast steps" do
    steps = RubricPipeline::STEPS

    # Check the standard service classes
    assert_equal PromptInput::Rubric, steps[0]
    assert_equal LLM::Rubric::Generator, steps[2]
    assert_equal LLM::Rubric::ResponseParser, steps[3]
    assert_equal Pipeline::Storage::RubricService, steps[4]
    assert_equal RecordMetricsService, steps[6]

    # Check the broadcast service steps separately - they're instances of ConfiguredBroadcastService
    assert_equal :rubric_started, steps[1].instance_variable_get(:@event)
    assert_equal :rubric_completed, steps[5].instance_variable_get(:@event)
  end
end
