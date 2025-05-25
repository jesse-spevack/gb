require "test_helper"

class PromptInput::RubricTest < ActiveSupport::TestCase
  test "criteria" do
    assignment = assignments(:english_essay)

    rubric_input = PromptInput::Rubric.new(assignment: assignment)

    assert_equal assignment.rubric.criteria, rubric_input.criteria
  end
end
