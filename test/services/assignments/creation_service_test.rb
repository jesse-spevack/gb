require "test_helper"
require "ostruct"

class Assignments::CreationServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:teacher)
    @assignment_input = mock("AssignmentInput")
    @assignment_params = {
      user_id: @user.id,
      title: "Test Assignment",
      instructions: "Test instructions",
      grade_level: Assignment::GRADE_LEVELS.first,
      feedback_tone: Assignment::FEEDBACK_TONES.first
    }
    @document_data = [
      OpenStruct.new(
        google_doc_id: "doc123",
        title: "Document 1",
        url: "https://docs.google.com/doc123"
      )
    ]

    @assignment_input.stubs(:params).returns(@assignment_params)
    @assignment_input.stubs(:document_data).returns(@document_data)
  end

  test "creates assignment, processing_steps, selected documents, student works, and rubric" do
    assert_difference [ "Assignment.count", "SelectedDocument.count", "StudentWork.count", "Rubric.count" ], 1 do
      result = Assignments::CreationService.create(@assignment_input)

      assert result.success?
      assert_not_nil result.assignment
      assert_equal "Test Assignment", result.assignment.title
      assert_equal 1, Rubric.where(assignment_id: result.assignment.id).count
      assert_equal 4, ProcessingStep.where(assignment_id: result.assignment.id).count
    end
  end

  test "returns failure when assignment cannot be created" do
    Assignment.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(Assignment.new))

    result = Assignments::CreationService.create(@assignment_input)

    assert_not result.success?
    assert_nil result.assignment
    assert_not_nil result.error_message
  end

  test "returns failure when an error is raised during transaction" do
    SelectedDocument::BulkCreationService.stubs(:create).raises(StandardError.new("Test error"))

    result = Assignments::CreationService.create(@assignment_input)

    assert_not result.success?
    assert_nil result.assignment
    assert_equal "Test error", result.error_message
  end
end
