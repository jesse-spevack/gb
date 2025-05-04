require "test_helper"

class FeedbackItemTest < ActiveSupport::TestCase
  # Validation Tests
  test "is not valid without title" do
    feedback_item = FeedbackItem.new(
      title: "",
      description: "Description",
      evidence: "Evidence",
      item_type: FeedbackItem.item_types[:strength],
      feedbackable: student_works(:student_essay_one)
    )

    assert_not feedback_item.valid?, feedback_item.errors.full_messages
  end

  test "is not valid without description" do
    feedback_item = FeedbackItem.new(
      title: "Title",
      description: "",
      evidence: "Evidence",
      item_type: FeedbackItem.item_types[:strength],
      feedbackable: student_works(:student_essay_one)
    )

    assert_not feedback_item.valid?, feedback_item.errors.full_messages
  end

  test "is not valid without evidence" do
    feedback_item = FeedbackItem.new(
      title: "Title",
      description: "Description",
      evidence: "",
      item_type: FeedbackItem.item_types[:strength],
      feedbackable: student_works(:student_essay_one)
    )

    assert_not feedback_item.valid?, feedback_item.errors.full_messages
  end

  test "is not valid without item_type" do
    feedback_item = FeedbackItem.new(
      title: "Title",
      description: "Description",
      evidence: "Evidence",
      item_type: nil,
      feedbackable: student_works(:student_essay_one)
    )

    assert_not feedback_item.valid?, feedback_item.errors.full_messages
  end

  test "is not valid without feedbackable" do
    feedback_item = FeedbackItem.new(
      title: "Title",
      description: "Description",
      evidence: "Evidence",
      item_type: :strength
    )

    assert_not feedback_item.valid?, feedback_item.errors.full_messages
    assert_includes feedback_item.errors[:feedbackable], "must exist"
  end

  test "is valid with all attributes" do
    feedback_item = FeedbackItem.new(
      title: "Title",
      description: "Description",
      evidence: "Evidence",
      item_type: :strength,
      feedbackable: student_works(:student_essay_one)
    )

    assert feedback_item.valid?, feedback_item.errors.full_messages
  end

  test "should use enum for item_type" do
    assert_equal 0, FeedbackItem.item_types[:strength]
    assert_equal 1, FeedbackItem.item_types[:opportunity]

    feedback_item = feedback_items(:strong_thesis_feedback)
    assert feedback_item.strength?
    assert_not feedback_item.opportunity?

    feedback_item.opportunity!
    assert_not feedback_item.strength?
    assert feedback_item.opportunity?
  end

  # Scope Tests
  test "scopes should filter by item_type" do
    assert_includes FeedbackItem.strengths, feedback_items(:strong_thesis_feedback)
    assert_not_includes FeedbackItem.strengths, feedback_items(:clarity_improvement_feedback)

    assert_includes FeedbackItem.opportunities, feedback_items(:clarity_improvement_feedback)
    assert_not_includes FeedbackItem.opportunities, feedback_items(:strong_thesis_feedback)
  end

  # Default Scope Test
  test "default scope should order by created_at desc" do
    # Create feedback items with different timestamps
    older = FeedbackItem.create!(
      title: "Older item",
      description: "Description",
      evidence: "Evidence",
      item_type: :strength,
      feedbackable: student_works(:student_essay_one),
      created_at: 2.days.ago
    )

    newer = FeedbackItem.create!(
      title: "Newer item",
      description: "Description",
      evidence: "Evidence",
      item_type: :strength,
      feedbackable: student_works(:student_essay_one),
      created_at: 1.day.ago
    )

    # Verify ordering
    items = FeedbackItem.where(id: [ older.id, newer.id ]).to_a
    assert_equal newer, items.first
    assert_equal older, items.last

    # Clean up
    older.destroy
    newer.destroy
  end
end
