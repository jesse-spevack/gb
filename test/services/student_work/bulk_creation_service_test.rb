require "test_helper"

class StudentWork::BulkCreationServiceTest < ActiveSupport::TestCase
  test "creates student works" do
    assignment = assignments(:english_essay_with_rubric_text)
    selected_documents = [ selected_documents(:one), selected_documents(:two) ]

    original_count = StudentWork.count

    StudentWork::BulkCreationService.create(assignment: assignment, selected_documents: selected_documents)

    assert_equal original_count + 2, StudentWork.count
  end
end
