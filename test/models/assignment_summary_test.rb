require "test_helper"

class AssignmentSummaryTest < ActiveSupport::TestCase
  test "it should be valid with valid attributes" do
    assignment_summary = AssignmentSummary.new(
      assignment: assignments(:english_essay),
      student_work_count: 1,
      qualitative_insights: "Qualitative Insights"
    )
    assert assignment_summary.valid?
  end

  test "it should not be valid without an assignment" do
    assignment_summary = AssignmentSummary.new(
      assignment: nil,
      student_work_count: 1,
      qualitative_insights: "Qualitative Insights"
    )
    assert_not assignment_summary.valid?
  end

  test "it should not be valid without a student work count" do
    assignment_summary = AssignmentSummary.new(
      assignment: assignments(:english_essay),
      student_work_count: nil,
      qualitative_insights: "Qualitative Insights"
    )
    assert_not assignment_summary.valid?
  end

  test "it should not be valid without qualitative insights" do
    assignment_summary = AssignmentSummary.new(
      assignment: assignments(:english_essay),
      student_work_count: 1,
      qualitative_insights: nil
    )
    assert_not assignment_summary.valid?
  end

  test "it has polymorphic feedback items" do
    assignment_summary = AssignmentSummary.new(
      assignment: assignments(:english_essay),
      student_work_count: 1,
      qualitative_insights: ""
    )

    feedback_item = FeedbackItem.new(
      feedbackable: assignment_summary,
      item_type: 1,
      title: "Feedback Item",
      description: "Description",
      evidence: "Evidence"
    )

    assert feedback_item.valid?
  end
end
