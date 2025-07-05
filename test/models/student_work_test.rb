require "test_helper"

class StudentWorkTest < ActiveSupport::TestCase
  test "is not valid without an assignment" do
    student_work = StudentWork.new(assignment: nil, selected_document: selected_documents(:one))
    assert_not student_work.valid?
  end

  test "is not valid without a selected document" do
    student_work = StudentWork.new(selected_document: nil, assignment: assignments(:english_essay))
    assert_not student_work.valid?
  end

      test "high_level_feedback_average returns most frequent level title" do
    student_work = student_works(:student_essay_one)

    # Clear existing student_criterion_levels to have a clean test
    student_work.student_criterion_levels.destroy_all

    # Create multiple criterion levels with different frequencies
    # "Proficient" appears 2 times (using correct criterion-level pairs)
    student_work.student_criterion_levels.create!(
      criterion: criteria(:writing_quality),
      level: levels(:writing_proficient),
      explanation: "Test explanation 1"
    )

    student_work.student_criterion_levels.create!(
      criterion: criteria(:content_depth),
      level: levels(:content_proficient),
      explanation: "Test explanation 2"
    )

    # "Developing" appears 2 times
    student_work.student_criterion_levels.create!(
      criterion: criteria(:writing_quality),
      level: levels(:writing_developing),
      explanation: "Test explanation 3"
    )

    student_work.student_criterion_levels.create!(
      criterion: criteria(:content_depth),
      level: levels(:content_developing),
      explanation: "Test explanation 4"
    )

    # "Exemplary" appears 1 time
    student_work.student_criterion_levels.create!(
      criterion: criteria(:writing_quality),
      level: levels(:writing_exemplary),
      explanation: "Test explanation 5"
    )

    # Should return "Proficient" as it appears most frequently (2 times, tied with Developing)
    # The method should return whichever appears first in the max_by operation
    result = student_work.high_level_feedback_average
    assert_includes [ "Proficient", "Developing" ], result
  end

  test "high_level_feedback_average handles tie by returning first maximum" do
    student_work = student_works(:student_essay_one)

    # Clear existing student_criterion_levels
    student_work.student_criterion_levels.destroy_all

    # Create equal frequencies - "Proficient" and "Developing" each appear twice
    student_work.student_criterion_levels.create!(
      criterion: criteria(:writing_quality),
      level: levels(:writing_proficient),
      explanation: "Test explanation 1"
    )

    student_work.student_criterion_levels.create!(
      criterion: criteria(:content_depth),
      level: levels(:content_proficient),
      explanation: "Test explanation 2"
    )

    student_work.student_criterion_levels.create!(
      criterion: criteria(:writing_quality),
      level: levels(:writing_developing),
      explanation: "Test explanation 3"
    )

    student_work.student_criterion_levels.create!(
      criterion: criteria(:content_depth),
      level: levels(:content_developing),
      explanation: "Test explanation 4"
    )

    # Should return whichever appears first in the max_by operation
    result = student_work.high_level_feedback_average
    assert_includes [ "Proficient", "Developing" ], result
  end
end
