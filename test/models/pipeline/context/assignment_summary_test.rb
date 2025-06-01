require "test_helper"

class Pipeline::Context::AssignmentSummaryTest < ActiveSupport::TestCase
  setup do
    @assignment = assignments(:history_essay)
    @context = Pipeline::Context::AssignmentSummary.new
    @context.assignment = @assignment
  end

  test "it has the expected attributes" do
    assignment_summary = Pipeline::Context::AssignmentSummary.new
    assert_equal({}, assignment_summary.metrics)
    assert_nil assignment_summary.assignment
  end

  test "it can add metrics" do
    assignment_summary = Pipeline::Context::AssignmentSummary.new
    assignment_summary.add_metric("test", 1)
    assert_equal({ "test" => 1 }, assignment_summary.metrics)
  end

  test "it can set values" do
    assignment_summary = Pipeline::Context::AssignmentSummary.new
    assignment_summary.assignment = "test"
    assert_equal("test", assignment_summary.assignment)
  end

  test "student_work_count returns student_feedbacks size when present" do
    # Create mock student feedbacks
    @context.student_feedbacks = [
      OpenStruct.new(id: 1),
      OpenStruct.new(id: 2),
      OpenStruct.new(id: 3)
    ]

    assert_equal 3, @context.student_work_count
  end

  test "student_work_count returns assignment student_works count when student_feedbacks is nil" do
    @context.student_feedbacks = nil

    assert_equal @assignment.student_works.count, @context.student_work_count
  end

  test "student_work_count returns assignment student_works count when student_feedbacks is empty" do
    @context.student_feedbacks = []

    assert_equal @assignment.student_works.count, @context.student_work_count
  end
end
