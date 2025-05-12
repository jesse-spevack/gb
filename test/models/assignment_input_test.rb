require "test_helper"

class AssignmentInputTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @assignment_params = {
      title: "Test Assignment",
      subject: "Math",
      grade_level: "6th",
      instructions: "Test instructions",
      raw_rubric_text: "Test rubric text",
      feedback_tone: "positive",
      document_data: JSON.generate([ { googleDocId: "1", title: "Document 1", url: "https://example.com/1" } ])
    }
  end

  test "returns correct properties" do
    assignment_input = AssignmentInput.new(assignment_params: @assignment_params, user: @user)

    assert_equal @user, assignment_input.user
    assert_equal "Test Assignment", assignment_input.title
    assert_equal "Math", assignment_input.subject
    assert_equal "6th", assignment_input.grade_level
    assert_equal "Test instructions", assignment_input.instructions
    assert_equal "Test rubric text", assignment_input.raw_rubric_text
    assert_equal "positive", assignment_input.feedback_tone

    document_data = assignment_input.document_data
    assert_equal "1", document_data.first.google_doc_id
    assert_equal "Document 1", document_data.first.title
    assert_equal "https://example.com/1", document_data.first.url
  end

  test "#params returns correct params" do
    assignment_input = AssignmentInput.new(assignment_params: @assignment_params, user: @user)
    expected_params = {
      user: @user,
      title: "Test Assignment",
      subject: "Math",
      grade_level: "6th",
      instructions: "Test instructions",
      feedback_tone: "positive"
    }

    assert_equal expected_params, assignment_input.params
  end
end
