require "test_helper"

class ProcessingStepTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
  end

  # Association tests
  test "belongs to assignment" do
    processing_step = ProcessingStep.new(assignment: @assignment, step_key: "assignment_saved")
    assert_equal @assignment, processing_step.assignment
  end

  test "requires assignment" do
    processing_step = ProcessingStep.new(step_key: "assignment_saved")
    assert_not processing_step.valid?
    assert_includes processing_step.errors[:assignment], "must exist"
  end

  # Constant tests
  test "STEP_KEYS contains expected values" do
    expected_keys = [
      "assignment_saved",
      "creating_rubric",
      "generating_feedback",
      "summarizing_feedback"
    ]
    assert_equal expected_keys, ProcessingStep::STEP_KEYS
  end

  test "STEP_KEYS is frozen" do
    assert ProcessingStep::STEP_KEYS.frozen?
  end

  # Enum tests
  test "has pending status by default" do
    processing_step = ProcessingStep.new(assignment: @assignment, step_key: "assignment_saved")
    assert processing_step.pending?
  end

    test "can set status to in_progress" do
    processing_step = ProcessingStep.create!(assignment: @assignment, step_key: "creating_rubric")
    processing_step.in_progress!
    assert processing_step.in_progress?
  end

  test "can set status to completed" do
    processing_step = ProcessingStep.create!(assignment: @assignment, step_key: "generating_feedback")
    processing_step.completed!
    assert processing_step.completed?
  end

  test "enum provides query methods" do
    processing_step = ProcessingStep.create!(assignment: @assignment, step_key: "summarizing_feedback")

    assert_respond_to processing_step, :pending?
    assert_respond_to processing_step, :in_progress?
    assert_respond_to processing_step, :completed?
  end

  test "enum provides bang methods" do
    # Create a separate assignment to avoid conflicts
    test_assignment = Assignment.create!(
      user: users(:teacher),
      title: "Test Assignment for Bang Methods",
      instructions: "Test instructions",
      subject: "Test",
      grade_level: "10"
    )
    processing_step = ProcessingStep.create!(assignment: test_assignment, step_key: "assignment_saved")

    assert_respond_to processing_step, :pending!
    assert_respond_to processing_step, :in_progress!
    assert_respond_to processing_step, :completed!
  end

  # Validation tests
  test "requires step_key" do
    processing_step = ProcessingStep.new(assignment: @assignment)
    assert_not processing_step.valid?
    assert_includes processing_step.errors[:step_key], "can't be blank"
  end

  test "step_key must be in STEP_KEYS" do
    processing_step = ProcessingStep.new(assignment: @assignment, step_key: "invalid_key")
    assert_not processing_step.valid?
    assert_includes processing_step.errors[:step_key], "is not included in the list"
  end

  test "accepts valid step_keys" do
    ProcessingStep::STEP_KEYS.each_with_index do |step_key, index|
      # Use different assignments to avoid uniqueness constraint violations
      assignment = Assignment.create!(
        user: users(:teacher),
        title: "Test Assignment #{index}",
        instructions: "Test instructions",
        subject: "Test",
        grade_level: "10"
      )
      processing_step = ProcessingStep.new(assignment: assignment, step_key: step_key)
      assert processing_step.valid?, "#{step_key} should be valid"
    end
  end

  test "step_key must be unique per assignment" do
    # Create a separate assignment to avoid conflicts
    test_assignment = Assignment.create!(
      user: users(:teacher),
      title: "Test Assignment for Uniqueness",
      instructions: "Test instructions",
      subject: "Test",
      grade_level: "10"
    )

    ProcessingStep.create!(assignment: test_assignment, step_key: "assignment_saved")

    duplicate_step = ProcessingStep.new(assignment: test_assignment, step_key: "assignment_saved")
    assert_not duplicate_step.valid?
    assert_includes duplicate_step.errors[:step_key], "has already been taken"
  end

  test "step_key can be duplicated across different assignments" do
    other_assignment = assignments(:history_essay)

    ProcessingStep.create!(assignment: @assignment, step_key: "creating_rubric")
    other_step = ProcessingStep.new(assignment: other_assignment, step_key: "creating_rubric")

    assert other_step.valid?
  end

  # Scope tests
  test "ordered scope orders by id" do
    # Create a separate assignment to avoid conflicts
    test_assignment = Assignment.create!(
      user: users(:teacher),
      title: "Test Assignment for Ordering",
      instructions: "Test instructions",
      subject: "Test",
      grade_level: "10"
    )

    step1 = ProcessingStep.create!(assignment: test_assignment, step_key: "assignment_saved")
    step2 = ProcessingStep.create!(assignment: test_assignment, step_key: "creating_rubric")
    step3 = ProcessingStep.create!(assignment: test_assignment, step_key: "generating_feedback")

    ordered_steps = ProcessingStep.where(assignment: test_assignment).ordered
    assert_equal [ step1, step2, step3 ], ordered_steps.to_a
  end

  # Integration tests
  test "can create processing step with all valid attributes" do
    processing_step = ProcessingStep.create!(
      assignment: @assignment,
      step_key: "summarizing_feedback",
      status: :in_progress
    )

    assert processing_step.persisted?
    assert_equal @assignment, processing_step.assignment
    assert_equal "summarizing_feedback", processing_step.step_key
    assert processing_step.in_progress?
  end
end
