require "test_helper"

class ProcessingMetricTest < ActiveSupport::TestCase
  test "invalid without processable" do
    metric = ProcessingMetric.new(
      processable: nil,
      completed_at: Time.current,
      duration_ms: 100,
      status: :completed
    )
    assert_not metric.valid?
    assert_equal [ "must exist", "can't be blank" ], metric.errors[:processable]
  end

  test "invalid without status" do
    metric = ProcessingMetric.new(
      processable: rubrics(:english_essay_rubric),
      completed_at: Time.current,
      duration_ms: 100,
      status: nil
    )
    assert_not metric.valid?
    assert_equal [ "can't be blank" ], metric.errors[:status]
  end
end
