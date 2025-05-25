require "test_helper"

class PromptInput::AssignmentSummaryTest < ActiveSupport::TestCase
  test "from class method creates new instance" do
    assignment = assignments(:english_essay)
    input = PromptInput::AssignmentSummary.from(assignment: assignment)

    mock_summaries = mock
    PromptInput::StudentPerformanceSummary.expects(:from)
      .with(assignment: assignment)
      .returns(mock_summaries)

    assert_instance_of PromptInput::AssignmentSummary, input
    assert_equal assignment.title, input.assignment_title
    assert_equal assignment.subject, input.assignment_subject
    assert_equal assignment.grade_level, input.assignment_grade_level
    assert_equal assignment.instructions, input.assignment_instructions
    assert_equal assignment.rubric, input.rubric
    assert_equal assignment.student_works, input.student_works
    assert_equal mock_summaries, input.rubric_performance_summary
  end
end
