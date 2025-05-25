require "test_helper"

class PromptTemplateTest < ActiveSupport::TestCase
  test "builds" do
    assignment = assignments(:english_essay)
    prompt = PromptTemplate.build("rubric_generation.txt.erb", RubricPromptInput.from(assignment: assignment))
    assert prompt.include?(assignment.title)
    assert prompt.include?(assignment.instructions)
    assert prompt.include?(assignment.grade_level)
  end
end
