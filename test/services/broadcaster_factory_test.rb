require "test_helper"

class BroadcasterFactoryTest < ActiveSupport::TestCase
  test "creates broadcaster for generate_rubric process type" do
    broadcaster = BroadcasterFactory.create("generate_rubric")

    assert_not_nil broadcaster
    assert_respond_to broadcaster, :broadcast
  end

  test "creates broadcaster for grade_student_work process type" do
    broadcaster = BroadcasterFactory.create("grade_student_work")

    assert_not_nil broadcaster
    assert_respond_to broadcaster, :broadcast
  end

  test "creates broadcaster for generate_summary_feedback process type" do
    broadcaster = BroadcasterFactory.create("generate_summary_feedback")

    assert_not_nil broadcaster
    assert_respond_to broadcaster, :broadcast
  end

  test "creates default broadcaster for unknown process type" do
    broadcaster = BroadcasterFactory.create("unknown_type")

    assert_not_nil broadcaster
    assert_respond_to broadcaster, :broadcast
  end

  test "handles nil process type gracefully" do
    broadcaster = BroadcasterFactory.create(nil)

    assert_not_nil broadcaster
    assert_respond_to broadcaster, :broadcast
  end

  test "raises error for unsupported types when strict mode enabled" do
    assert_raises(BroadcasterFactory::UnsupportedProcessTypeError) do
      BroadcasterFactory.create("unsupported_type", strict: true)
    end
  end

  test "created broadcaster can broadcast updates" do
    broadcaster = BroadcasterFactory.create("generate_rubric")
    assignment = assignments(:english_essay)

    result = broadcaster.broadcast(assignment, :processing, { progress: 50 })

    # Should return some kind of result
    assert_not_nil result
  end

  test "supports configuration options" do
    config = { channel: "custom_channel", format: "json" }
    broadcaster = BroadcasterFactory.create("generate_rubric", config: config)

    assert_not_nil broadcaster
    assert_respond_to broadcaster, :broadcast
  end

  test "supported_types returns all known process types" do
    supported = BroadcasterFactory.supported_types

    assert_includes supported, "generate_rubric"
    assert_includes supported, "grade_student_work"
    assert_includes supported, "generate_summary_feedback"
    assert_equal 3, supported.size
  end

  test "supports? returns true for known process types" do
    assert BroadcasterFactory.supports?("generate_rubric")
    assert BroadcasterFactory.supports?("grade_student_work")
    assert BroadcasterFactory.supports?("generate_summary_feedback")
  end

  test "supports? returns false for unknown process types" do
    refute BroadcasterFactory.supports?("unknown_type")
    refute BroadcasterFactory.supports?(nil)
    refute BroadcasterFactory.supports?("")
  end

  test "created broadcasters return structured result with expected fields" do
    broadcaster = BroadcasterFactory.create("generate_rubric")
    assignment = assignments(:english_essay)

    result = broadcaster.broadcast(assignment, :completed, { data: "test result" })

    assert result.key?(:broadcast)
    assert result.key?(:broadcaster_type)
    assert result.key?(:broadcasted_at)
    assert_equal "rubric_broadcast", result[:broadcaster_type]
  end

  test "default broadcaster returns basic result data" do
    broadcaster = BroadcasterFactory.create("unknown_type")
    assignment = assignments(:english_essay)

    result = broadcaster.broadcast(assignment, :processing, { some: "data" })

    assert result.key?(:broadcast)
    assert result.key?(:broadcaster_type)
    assert result.key?(:broadcasted_at)
    assert_equal "default", result[:broadcaster_type]
  end

  test "factory maintains consistency across multiple calls" do
    broadcaster1 = BroadcasterFactory.create("generate_rubric")
    broadcaster2 = BroadcasterFactory.create("generate_rubric")

    assert_equal broadcaster1, broadcaster2
  end

  test "broadcaster handles different status types" do
    broadcaster = BroadcasterFactory.create("generate_rubric")
    assignment = assignments(:english_essay)

    [ :processing, :completed, :failed, :queued ].each do |status|
      result = broadcaster.broadcast(assignment, status, { progress: 75 })

      assert_not_nil result
      assert_equal status, result[:broadcast]
    end
  end

  test "broadcaster handles nil data parameter" do
    broadcaster = BroadcasterFactory.create("generate_rubric")
    assignment = assignments(:english_essay)

    result = broadcaster.broadcast(assignment, :processing, nil)

    assert_not_nil result
    assert_equal :processing, result[:broadcast]
  end
end
