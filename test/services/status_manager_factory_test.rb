require "test_helper"

class StatusManagerFactoryTest < ActiveSupport::TestCase
  test "creates assignment status manager for generate_rubric process type" do
    manager = StatusManagerFactory.create("generate_rubric")

    assert_not_nil manager
    assert_respond_to manager, :update_status
  end

  test "creates student work status manager for grade_student_work process type" do
    manager = StatusManagerFactory.create("grade_student_work")

    assert_not_nil manager
    assert_respond_to manager, :update_status
  end

  test "creates assignment summary status manager for generate_summary_feedback process type" do
    manager = StatusManagerFactory.create("generate_summary_feedback")

    assert_not_nil manager
    assert_respond_to manager, :update_status
  end

  test "returns default status manager for unknown process type" do
    manager = StatusManagerFactory.create("unknown_type")

    assert_equal StatusManagerFactory::DefaultStatusManager, manager
    assert_respond_to manager, :update_status
  end

  test "raises error for unknown process type when strict mode enabled" do
    error = assert_raises(StatusManagerFactory::UnsupportedProcessTypeError) do
      StatusManagerFactory.create("unknown_type", strict: true)
    end

    assert_match(/Unsupported process type/, error.message)
  end

  test "returns supported types" do
    supported = StatusManagerFactory.supported_types

    assert_includes supported, "generate_rubric"
    assert_includes supported, "grade_student_work"
    assert_includes supported, "generate_summary_feedback"
  end

  test "checks if process type is supported" do
    assert StatusManagerFactory.supports?("generate_rubric")
    assert_not StatusManagerFactory.supports?("unknown_type")
  end

  test "update_status method works with assignment for rubric generation" do
    assignment = assignments(:english_essay)
    manager = StatusManagerFactory.create("generate_rubric")

    result = manager.update_status(assignment, :processing)

    assert result[:status_updated]
    assert_equal "assignment_status", result[:status_type]
    assert_equal assignment.id, result[:processable_id]
    assert_equal "Assignment", result[:processable_type]
    assert_equal :processing, result[:status]
  end

  test "update_status method works with student work for grading" do
    student_work = student_works(:student_essay_one)
    manager = StatusManagerFactory.create("grade_student_work")

    result = manager.update_status(student_work, :completed)

    assert result[:status_updated]
    assert_equal "student_work_status", result[:status_type]
    assert_equal student_work.id, result[:processable_id]
    assert_equal "StudentWork", result[:processable_type]
    assert_equal :completed, result[:status]
  end
end
