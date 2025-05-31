require "test_helper"

class PromptInput::StudentPerformanceSummaryTest < ActiveSupport::TestCase
  def setup
    # Create a test assignment
    @assignment = Assignment.create!(
      title: "Test Assignment",
      user: users(:teacher),
      subject: "English",
      grade_level: "9",
      instructions: "Write an essay",
      feedback_tone: "encouraging"
    )

    # Create a rubric for the assignment
    @rubric = Rubric.create!(assignment: @assignment)

    # Create two criteria for the rubric
    @criterion1 = Criterion.create!(
      rubric: @rubric,
      title: "Writing Quality",
      description: "Evaluates writing quality",
      position: 1
    )

    @criterion2 = Criterion.create!(
      rubric: @rubric,
      title: "Grammar",
      description: "Evaluates grammar",
      position: 2
    )

    # Create levels for each criterion
    @level1_1 = Level.create!(
      criterion: @criterion1,
      title: "Excellent",
      description: "Excellent writing",
      position: 1,
      points: 4
    )

    @level1_2 = Level.create!(
      criterion: @criterion1,
      title: "Good",
      description: "Good writing",
      position: 2,
      points: 3
    )

    @level2_1 = Level.create!(
      criterion: @criterion2,
      title: "Excellent",
      description: "Excellent grammar",
      position: 1,
      points: 4
    )

    @level2_2 = Level.create!(
      criterion: @criterion2,
      title: "Good",
      description: "Good grammar",
      position: 2,
      points: 3
    )

    # Create a document to use for student works
    @document = SelectedDocument.create!(
      assignment: @assignment,
      google_doc_id: "doc123",
      title: "Test Document",
      url: "https://example.com/doc123"
    )

    # Create three student works
    @student_work1 = StudentWork.create!(
      assignment: @assignment,
      selected_document: @document,
      qualitative_feedback: "Good work overall."
    )

    @student_work2 = StudentWork.create!(
      assignment: @assignment,
      selected_document: @document,
      qualitative_feedback: "Excellent work."
    )

    @student_work3 = StudentWork.create!(
      assignment: @assignment,
      selected_document: @document,
      qualitative_feedback: "Needs improvement."
    )

    # Create student criterion levels with known values
    # For criterion1: 3 levels, positions 1, 1, 2 (avg = 1.33, min = 1, max = 2, count = 3)
    StudentCriterionLevel.create!(
      student_work: @student_work1,
      criterion: @criterion1,
      level: @level1_1,
      explanation: "Great writing quality"
    )

    StudentCriterionLevel.create!(
      student_work: @student_work2,
      criterion: @criterion1,
      level: @level1_1,
      explanation: "Excellent writing quality"
    )

    StudentCriterionLevel.create!(
      student_work: @student_work3,
      criterion: @criterion1,
      level: @level1_2,
      explanation: "Good writing quality"
    )

    # For criterion2: 3 levels, all position 2 (avg = 2, min = 2, max = 2, count = 3)
    StudentCriterionLevel.create!(
      student_work: @student_work1,
      criterion: @criterion2,
      level: @level2_2,
      explanation: "Good grammar"
    )

    StudentCriterionLevel.create!(
      student_work: @student_work2,
      criterion: @criterion2,
      level: @level2_2,
      explanation: "Good grammar usage"
    )

    StudentCriterionLevel.create!(
      student_work: @student_work3,
      criterion: @criterion2,
      level: @level2_2,
      explanation: "Grammar is good"
    )
  end

  test "from returns a collection of criterion performance summaries with exact expected values" do
    # Call the method with our test assignment
    result = PromptInput::StudentPerformanceSummary.from(assignment: @assignment)

    # Verify result is a collection with exactly 2 items (one for each criterion)
    assert_kind_of Array, result
    assert_equal 2, result.length

    # Find our two criteria in the results
    writing_quality = result.find { |summary| summary.criterion_title == "Writing Quality" }
    grammar = result.find { |summary| summary.criterion_title == "Grammar" }

    # Verify both criteria were found
    assert_not_nil writing_quality
    assert_not_nil grammar

    # Verify exact values for Writing Quality criterion
    assert_equal "Writing Quality", writing_quality.criterion_title
    assert_equal 1.33, writing_quality.average_level.round(2) # (1+1+2)/3 = 1.33
    assert_equal 1, writing_quality.min_level
    assert_equal 2, writing_quality.max_level
    assert_equal 3, writing_quality.count

    # Verify exact values for Grammar criterion
    assert_equal "Grammar", grammar.criterion_title
    assert_equal 2.0, grammar.average_level
    assert_equal 2, grammar.min_level
    assert_equal 2, grammar.max_level
    assert_equal 3, grammar.count
  end
end
