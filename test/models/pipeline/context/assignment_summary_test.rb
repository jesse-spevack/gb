require "test_helper"

class Pipeline::Context::AssignmentSummaryTest < ActiveSupport::TestCase
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
end
