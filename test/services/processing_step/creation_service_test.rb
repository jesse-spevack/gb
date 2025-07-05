require "test_helper"

class ProcessingStep::CreationServiceTest < ActiveSupport::TestCase
  test "creates processing steps for an assignment" do
    assignment = assignments(:history_essay)

    assert_difference "ProcessingStep.count", ProcessingStep::STEP_KEYS.count do
      result = ProcessingStep::CreationService.create(assignment: assignment)

      assert result.success?

      processing_steps = assignment.reload.processing_steps
      assert_equal ProcessingStep::STEP_KEYS, processing_steps.pluck(:step_key)
      assert processing_steps.pluck(:status).all? { |status| status == "pending" }
    end
  end
end
