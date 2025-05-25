require "test_helper"

class StudentWorkDataForAssignmentSummaryTest < ActiveSupport::TestCase
  def setup
    @student_work = student_works(:student_essay_one)
  end

  test "wraps student work with clean interface" do
    data = StudentWorkDataForAssignmentSummary.new(@student_work)

    assert_respond_to data, :qualitative_feedback
    assert_respond_to data, :criterion_levels
    assert_respond_to data, :has_feedback?
    assert_respond_to data, :has_criterion_levels?
  end

  test "provides qualitative feedback" do
    data = StudentWorkDataForAssignmentSummary.new(@student_work)

    assert_equal @student_work.qualitative_feedback, data.qualitative_feedback
  end

  test "detects presence of feedback" do
    # Test with student work that has feedback
    data_with_feedback = StudentWorkDataForAssignmentSummary.new(@student_work)
    assert data_with_feedback.has_feedback? if @student_work.qualitative_feedback.present?

    # Test with student work without feedback
    student_work_without_feedback = StudentWork.new(qualitative_feedback: nil)
    data_without_feedback = StudentWorkDataForAssignmentSummary.new(student_work_without_feedback)
    assert_not data_without_feedback.has_feedback?

    # Test with empty feedback
    student_work_empty_feedback = StudentWork.new(qualitative_feedback: "")
    data_empty_feedback = StudentWorkDataForAssignmentSummary.new(student_work_empty_feedback)
    assert_not data_empty_feedback.has_feedback?
  end

  test "provides criterion levels data" do
    data = StudentWorkDataForAssignmentSummary.new(@student_work)
    criterion_levels = data.criterion_levels

    assert criterion_levels.is_a?(Array)

    # If student work has criterion levels, verify structure
    if @student_work.student_criterion_levels.any?
      # Choose any level for testing structure and data mapping
      sample_level = criterion_levels.first

      assert_respond_to sample_level, :criterion_title
      assert_respond_to sample_level, :level_title
      assert_respond_to sample_level, :explanation

      # Verify each criterion level has a matching source
      criterion_levels.each do |cl|
        # Find matching source level by criterion title
        source_level = @student_work.student_criterion_levels.find { |scl| scl.criterion.title == cl.criterion_title }
        assert_not_nil source_level, "Could not find source for criterion: #{cl.criterion_title}"

        # Verify data matches
        assert_equal source_level.criterion.title, cl.criterion_title
        assert_equal source_level.level.title, cl.level_title
        assert_equal source_level.explanation, cl.explanation
      end
    end
  end

  test "detects presence of criterion levels" do
    data = StudentWorkDataForAssignmentSummary.new(@student_work)

    if @student_work.student_criterion_levels.any?
      assert data.has_criterion_levels?
    else
      assert_not data.has_criterion_levels?
    end
  end

  test "handles student work without criterion levels" do
    student_work_without_levels = StudentWork.new
    student_work_without_levels.stubs(:student_criterion_levels).returns([])

    data = StudentWorkDataForAssignmentSummary.new(student_work_without_levels)

    assert_not data.has_criterion_levels?
    assert_equal [], data.criterion_levels
  end

  test "criterion levels are ordered consistently" do
    data = StudentWorkDataForAssignmentSummary.new(@student_work)
    criterion_levels = data.criterion_levels

    # Should be ordered by criterion for consistent display
    if criterion_levels.length > 1
      titles = criterion_levels.map(&:criterion_title)
      assert_equal titles.sort, titles, "Criterion levels should be ordered consistently"
    end
  end
end
