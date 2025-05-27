require "test_helper"

class ProcessingMetricTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
    @user = users(:teacher)
    @metric = ProcessingMetric.new(
      processable: @assignment,
      status: :completed,
      total_duration_ms: 5000,
      llm_duration_ms: 3000
    )
  end

  test "should be valid with required attributes" do
    assert @metric.valid?
  end

  test "invalid without processable" do
    metric = ProcessingMetric.new(
      processable: nil,
      status: :completed,
      total_duration_ms: 100
    )
    assert_not metric.valid?
    assert_equal [ "must exist", "can't be blank" ], metric.errors[:processable]
  end

  test "invalid without status" do
    metric = ProcessingMetric.new(
      processable: rubrics(:english_essay_rubric),
      total_duration_ms: 100,
      status: nil
    )
    assert_not metric.valid?
    assert_equal [ "can't be blank" ], metric.errors[:status]
  end

  test "should require total_duration_ms for completed status" do
    @metric.total_duration_ms = nil
    assert_not @metric.valid?
    assert_includes @metric.errors[:total_duration_ms], "can't be blank"
  end

  test "should not require duration fields for pending status" do
    @metric.status = :pending
    @metric.total_duration_ms = nil
    @metric.llm_duration_ms = nil
    assert @metric.valid?
  end

  test "should have scope for assignment metrics" do
    @metric.save!
    rubric = rubrics(:english_essay_rubric)
    ProcessingMetric.create!(
      processable: rubric,
      status: :completed,
      total_duration_ms: 1000,
      llm_duration_ms: 800
    )

    assignment_metrics = ProcessingMetric.for_assignment(@assignment)
    assert_equal 2, assignment_metrics.count # Assignment metric + rubric metric
  end

  test "should have scope for user metrics" do
    @metric.save!
    another_user = users(:admin)
    another_assignment = assignments(:history_essay)
    # Create metric for another assignment (not associated with another_user yet)
    ProcessingMetric.create!(
      processable: another_assignment,
      status: :completed,
      total_duration_ms: 2000,
      llm_duration_ms: 1500
    )

    # Reload associations to ensure the before_save hook effects are visible
    @metric.reload

    user_metrics = ProcessingMetric.for_user(@user)
    another_user_metrics = ProcessingMetric.for_user(another_user)

    # The history_essay's metric was automatically associated with its owner (@user)
    # due to the set_associations callback, so we expect 2 metrics for @user
    assert_equal 2, user_metrics.count
    assert_includes user_metrics, @metric
    assert_equal 0, another_user_metrics.count # No metrics associated with another_user yet
  end

  test "should calculate average durations" do
    3.times do |i|
      ProcessingMetric.create!(
        processable: @assignment,
        status: :completed,
        total_duration_ms: 1000 * (i + 1),
        llm_duration_ms: 500 * (i + 1)
      )
    end

    assert_equal 2000, ProcessingMetric.average_total_duration
    assert_equal 1000, ProcessingMetric.average_llm_duration
  end
end
