require "test_helper"

class StudentWorkCheckTest < ActiveSupport::TestCase
  test "not valid without student work" do
    student_work_check = StudentWorkCheck.new(
      check_type: :plagiarism,
      score: 100,
      explanation: "No plagiarism detected"
    )
    assert_not student_work_check.valid?
  end

  test "not valid without check type" do
    student_work_check = StudentWorkCheck.new(
      student_work: student_works(:student_essay_one),
      score: 100,
      explanation: "No plagiarism detected"
    )
    assert_not student_work_check.valid?
  end

  test "not valid without score" do
    student_work_check = StudentWorkCheck.new(
      student_work: student_works(:student_essay_one),
      check_type: :plagiarism,
      explanation: "No plagiarism detected"
    )
    assert_not student_work_check.valid?
  end

  test "not valid without explanation" do
    student_work_check = StudentWorkCheck.new(
      student_work: student_works(:student_essay_one),
      check_type: :plagiarism,
      score: 100
    )
    assert_not student_work_check.valid?
  end

  test "valid with all required attributes" do
    student_work_check = StudentWorkCheck.new(
      student_work: student_works(:student_essay_one),
      check_type: :plagiarism,
      score: 100,
      explanation: "No plagiarism detected"
    )
    assert student_work_check.valid?
  end
end
