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
end
