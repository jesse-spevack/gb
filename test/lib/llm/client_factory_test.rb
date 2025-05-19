require "test_helper"

class LLM::ClientFactoryTest < ActiveSupport::TestCase
  test "for_rubric_generation returns GoogleClient" do
    assert_equal LLM::GoogleClient, LLM::ClientFactory.for_rubric_generation
  end

  test "for_student_work_feedback returns AnthropicClient" do
    assert_equal LLM::AnthropicClient, LLM::ClientFactory.for_student_work_feedback
  end

  test "for_assignment_summary_feedback returns AnthropicClient" do
    assert_equal LLM::AnthropicClient, LLM::ClientFactory.for_assignment_summary_feedback
  end
end
