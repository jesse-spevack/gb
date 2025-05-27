# frozen_string_literal: true

require "test_helper"

class TimeEstimatorIntegrationTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @assignment = assignments(:english_essay)
  end

  test "TimeEstimator provides reasonable defaults for all operations" do
    estimator = TimeEstimator.new

    # Test rubric generation
    rubric_estimate = estimator.estimate(:rubric_generation, { criteria_count: 4 })
    assert_equal 28, rubric_estimate[:seconds]
    assert_equal "28 seconds", rubric_estimate[:display]

    # Test student work with context
    student_estimate = estimator.estimate(:student_work_feedback, {
      page_count: 2,
      criteria_count: 4
    })
    assert_equal 47, student_estimate[:seconds]
    assert_equal "47 seconds", student_estimate[:display]

    # Test assignment summary
    summary_estimate = estimator.estimate(:assignment_summary, { student_count: 30 })
    assert_equal 60, summary_estimate[:seconds]
    assert_equal "1 minute", summary_estimate[:display]
  end

  test "StatusManagerFactory uses TimeEstimator for completion estimates" do
    manager = StatusManagerFactory.create("generate_rubric")
    result = manager.update_status(@assignment, :queued)

    # Verify the estimate is reasonable (around 28 seconds for 4 criteria)
    completion_time = result[:metadata][:estimated_completion]
    time_diff = (completion_time - Time.current).to_i

    assert_in_delta 28, time_diff, 5, "Expected completion time around 28 seconds"
  end

  test "progress calculator integration with TimeEstimator" do
    # Test remaining time calculation without modifying fixtures
    estimator = TimeEstimator.new
    context = {
      total_operations: 7, # 1 rubric + 5 students + 1 summary
      completed_operations: 0,
      current_phase: :rubric_generation,
      criteria_count: 4,
      average_page_count: 2,
      student_count: 5
    }

    result = estimator.estimate_remaining_time(context)
    assert_equal 7, result[:remaining_operations]
    # 28 (rubric) + 5*47 (students) + 35 (summary) = 298
    assert_equal 298, result[:estimated_seconds]
    assert_equal "5.0 minutes", result[:display]

    # Test with partial progress
    context[:completed_operations] = 3
    context[:current_phase] = :student_work_feedback

    result = estimator.estimate_remaining_time(context)
    assert_equal 4, result[:remaining_operations]
    # 4 remaining operations in student phase = 4 * 47 = 188
    assert_equal 188, result[:estimated_seconds]
    assert_equal "3.1 minutes", result[:display]
  end

  test "TimeEstimator handles edge cases gracefully" do
    estimator = TimeEstimator.new

    # Nil operation
    assert_nil estimator.estimate(nil)

    # Unknown operation
    assert_nil estimator.estimate(:unknown_operation)

    # Empty context for remaining time
    assert_nil estimator.estimate_remaining_time({})

    # Zero remaining operations
    context = {
      total_operations: 10,
      completed_operations: 10,
      current_phase: :completed
    }
    result = estimator.estimate_remaining_time(context)
    assert_equal 0, result[:remaining_operations]
    assert_equal "0 seconds", result[:display]
  end
end
