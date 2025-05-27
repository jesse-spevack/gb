# frozen_string_literal: true

require "test_helper"

class TimeEstimatorTest < ActiveSupport::TestCase
  def setup
    @estimator = TimeEstimator.new
  end

  test "estimates rubric generation time with defaults" do
    estimate = @estimator.estimate(:rubric_generation)

    assert_equal 20, estimate[:seconds]
    assert_equal "20 seconds", estimate[:display]
    assert_equal :rubric_generation, estimate[:operation]
  end

  test "estimates student work feedback time with defaults" do
    estimate = @estimator.estimate(:student_work_feedback)

    assert_equal 25, estimate[:seconds]
    assert_equal "25 seconds", estimate[:display]
    assert_equal :student_work_feedback, estimate[:operation]
  end

  test "estimates assignment summary time with defaults" do
    estimate = @estimator.estimate(:assignment_summary)

    assert_equal 30, estimate[:seconds]
    assert_equal "30 seconds", estimate[:display]
    assert_equal :assignment_summary, estimate[:operation]
  end

  test "returns nil for unknown operation" do
    estimate = @estimator.estimate(:unknown_operation)

    assert_nil estimate
  end

  test "formats time display for longer durations" do
    estimator = TimeEstimator.new

    # Test various duration formats
    assert_equal "45 seconds", estimator.format_duration(45)
    assert_equal "1 minute", estimator.format_duration(60)
    assert_equal "1.5 minutes", estimator.format_duration(90)
    assert_equal "2 minutes", estimator.format_duration(120)
    assert_equal "5 minutes", estimator.format_duration(300)
  end

  # Context-aware estimates tests
  test "estimates rubric generation with criteria count" do
    context = { criteria_count: 5 }
    estimate = @estimator.estimate(:rubric_generation, context)

    # Base 20s + 2s per criterion = 30s
    assert_equal 30, estimate[:seconds]
    assert_equal "30 seconds", estimate[:display]
  end

  test "estimates student work feedback with document pages and criteria" do
    context = { page_count: 3, criteria_count: 4 }
    estimate = @estimator.estimate(:student_work_feedback, context)

    # Base 25s + (3 pages * 5s) + (4 criteria * 3s) = 52s
    assert_equal 52, estimate[:seconds]
    assert_equal "52 seconds", estimate[:display]
  end

  test "estimates assignment summary with student count" do
    context = { student_count: 30 }
    estimate = @estimator.estimate(:assignment_summary, context)

    # Base 30s + (30 students * 1s) = 60s
    assert_equal 60, estimate[:seconds]
    assert_equal "1 minute", estimate[:display]
  end

  test "applies maximum limits to estimates" do
    # Test rubric with many criteria hits max
    context = { criteria_count: 50 }
    estimate = @estimator.estimate(:rubric_generation, context)
    assert_equal 60, estimate[:seconds] # Should cap at 60s max

    # Test student work with long document hits max
    context = { page_count: 20, criteria_count: 10 }
    estimate = @estimator.estimate(:student_work_feedback, context)
    assert_equal 90, estimate[:seconds] # Should cap at 90s max

    # Test summary with large class hits max
    context = { student_count: 100 }
    estimate = @estimator.estimate(:assignment_summary, context)
    assert_equal 120, estimate[:seconds] # Should cap at 120s max
  end

  test "handles missing context gracefully" do
    # Should use defaults when context is empty
    estimate = @estimator.estimate(:rubric_generation, {})
    assert_equal 20, estimate[:seconds]

    # Should use defaults when context is nil
    estimate = @estimator.estimate(:student_work_feedback, nil)
    assert_equal 25, estimate[:seconds]
  end

  # Remaining time calculations
  test "calculates remaining time for assignment processing" do
    assignment_context = {
      total_operations: 37, # 1 rubric + 35 students + 1 summary
      completed_operations: 10,
      current_phase: :student_work_feedback,
      criteria_count: 4,
      average_page_count: 2
    }

    result = @estimator.estimate_remaining_time(assignment_context)

    assert_equal 27, result[:remaining_operations]
    assert_equal 1269, result[:estimated_seconds] # 27 * 47s (25 base + 2*5 + 4*3)
    assert_equal "21.2 minutes", result[:display]
    assert_equal :student_work_feedback, result[:current_phase]
  end

  test "calculates remaining time when starting assignment" do
    assignment_context = {
      total_operations: 37,
      completed_operations: 0,
      current_phase: :rubric_generation,
      criteria_count: 4
    }

    result = @estimator.estimate_remaining_time(assignment_context)

    assert_equal 37, result[:remaining_operations]
    # 1 rubric (20+8) + 35 students (25+10+12 each) + 1 summary (30+35)
    # = 28 + 35*47 + 65 = 1738
    assert_equal 1738, result[:estimated_seconds]
    assert_equal "29.0 minutes", result[:display]
  end

  test "calculates remaining time with mixed phases" do
    assignment_context = {
      total_operations: 10, # 1 rubric + 8 students + 1 summary
      completed_operations: 4, # rubric + 3 students done
      current_phase: :student_work_feedback,
      phases_remaining: [ :student_work_feedback, :assignment_summary ],
      criteria_count: 3,
      average_page_count: 2,
      student_count: 8
    }

    result = @estimator.estimate_remaining_time(assignment_context)

    assert_equal 6, result[:remaining_operations]
    # 5 students * 44s (25+10+9) + 1 summary * 38s
    assert_equal 258, result[:estimated_seconds]
    assert_equal "4.3 minutes", result[:display]
  end

  test "returns zero when all operations complete" do
    assignment_context = {
      total_operations: 10,
      completed_operations: 10,
      current_phase: :completed
    }

    result = @estimator.estimate_remaining_time(assignment_context)

    assert_equal 0, result[:remaining_operations]
    assert_equal 0, result[:estimated_seconds]
    assert_equal "0 seconds", result[:display]
  end

  test "handles edge cases in remaining time calculation" do
    # Nil context
    result = @estimator.estimate_remaining_time(nil)
    assert_nil result

    # Missing required fields
    result = @estimator.estimate_remaining_time({})
    assert_nil result

    # Invalid numbers
    context = { total_operations: 0, completed_operations: 5 }
    result = @estimator.estimate_remaining_time(context)
    assert_nil result
  end
end
