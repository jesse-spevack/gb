require "test_helper"
require "ostruct"

class ProcessingStepPresenterTest < ActiveSupport::TestCase
  def setup
    @completed_step = OpenStruct.new(step_key: "assignment_saved", status: "completed")
    @in_progress_step = OpenStruct.new(step_key: "creating_rubric", status: "in_progress")
    @pending_step = OpenStruct.new(step_key: "generating_feedback", status: "pending")
    @unknown_step = OpenStruct.new(step_key: "unknown_step", status: "pending")
  end

  test "#initialize sets steps" do
    steps = [ @completed_step, @in_progress_step ]
    presenter = ProcessingStepPresenter.new(steps)
    assert_equal steps, presenter.instance_variable_get(:@steps)
  end

  test "#current_step returns the step with in_progress status" do
    steps = [ @completed_step, @in_progress_step, @pending_step ]
    presenter = ProcessingStepPresenter.new(steps)
    assert_equal @in_progress_step, presenter.current_step
  end

  test "#current_step returns nil when no step is in_progress" do
    steps = [ @completed_step, @pending_step ]
    presenter = ProcessingStepPresenter.new(steps)
    assert_nil presenter.current_step
  end

  test "#current_step memoizes the result" do
    steps = [ @completed_step, @in_progress_step, @pending_step ]
    presenter = ProcessingStepPresenter.new(steps)

    # First call
    first_result = presenter.current_step

    # Modify the step status
    @in_progress_step.status = "completed"

    # Second call should return the memoized result
    second_result = presenter.current_step
    assert_equal first_result, second_result
  end

  test "#all_completed? returns true when all steps are completed" do
    completed_steps = [
      OpenStruct.new(step_key: "assignment_saved", status: "completed"),
      OpenStruct.new(step_key: "creating_rubric", status: "completed")
    ]
    presenter = ProcessingStepPresenter.new(completed_steps)
    assert presenter.all_completed?
  end

  test "#all_completed? returns false when some steps are not completed" do
    mixed_steps = [ @completed_step, @in_progress_step ]
    presenter = ProcessingStepPresenter.new(mixed_steps)
    assert_not presenter.all_completed?
  end

  test "#all_completed? returns true for empty steps array" do
    presenter = ProcessingStepPresenter.new([])
    assert presenter.all_completed?
  end

  test "#status_message returns completion message when all steps are completed" do
    completed_steps = [
      OpenStruct.new(step_key: "assignment_saved", status: "completed"),
      OpenStruct.new(step_key: "creating_rubric", status: "completed")
    ]
    presenter = ProcessingStepPresenter.new(completed_steps)
    assert_equal "Assignment processing complete!", presenter.status_message
  end

  test "#status_message returns current step message when step is in progress" do
    steps = [ @completed_step, @in_progress_step ]
    presenter = ProcessingStepPresenter.new(steps)
    assert_equal "GradeBot is generating a rubric...", presenter.status_message
  end

  test "#status_message returns default message when no current step" do
    steps = [ @completed_step, @pending_step ]
    presenter = ProcessingStepPresenter.new(steps)
    assert_equal "Preparing to process assignment...", presenter.status_message
  end

  test "#status_message returns default message when current step has no status message" do
    unknown_in_progress = OpenStruct.new(step_key: "unknown_step", status: "in_progress")
    steps = [ @completed_step, unknown_in_progress ]
    presenter = ProcessingStepPresenter.new(steps)
    assert_equal "Preparing to process assignment...", presenter.status_message
  end

  test "#display_name_for returns mapped display name for known step" do
    presenter = ProcessingStepPresenter.new([])
    assert_equal "Assignment Saved", presenter.display_name_for("assignment_saved")
    assert_equal "Creating Rubric", presenter.display_name_for("creating_rubric")
    assert_equal "Grading Work", presenter.display_name_for("generating_feedback")
    assert_equal "Generating Summary", presenter.display_name_for("summarizing_feedback")
  end

  test "#display_name_for returns humanized step key for unknown step" do
    presenter = ProcessingStepPresenter.new([])
    assert_equal "Unknown step", presenter.display_name_for("unknown_step")
  end

  test "#display_name_with_breaks returns display name with HTML breaks" do
    presenter = ProcessingStepPresenter.new([])
    result = presenter.display_name_with_breaks("creating_rubric")
    assert_equal "Creating<br>Rubric", result
    assert result.html_safe?
  end

  test "#display_name_with_breaks handles single word display names" do
    presenter = ProcessingStepPresenter.new([])
    result = presenter.display_name_with_breaks("assignment_saved")
    assert_equal "Assignment<br>Saved", result
  end

  test "#step_circle_classes returns blue for completed step" do
    presenter = ProcessingStepPresenter.new([])
    assert_equal "bg-blue-600", presenter.step_circle_classes(@completed_step)
  end

  test "#step_circle_classes returns blue for in_progress step" do
    presenter = ProcessingStepPresenter.new([])
    assert_equal "bg-blue-600", presenter.step_circle_classes(@in_progress_step)
  end

  test "#step_circle_classes returns gray for pending step" do
    presenter = ProcessingStepPresenter.new([])
    assert_equal "bg-gray-200", presenter.step_circle_classes(@pending_step)
  end

  test "#step_number_classes returns white text for in_progress step" do
    presenter = ProcessingStepPresenter.new([])
    assert_equal "text-white", presenter.step_number_classes(@in_progress_step)
  end

  test "#step_number_classes returns gray text for non-in_progress step" do
    presenter = ProcessingStepPresenter.new([])
    assert_equal "text-gray-900", presenter.step_number_classes(@completed_step)
    assert_equal "text-gray-900", presenter.step_number_classes(@pending_step)
  end

  test "#step_text_classes returns gray for completed step" do
    presenter = ProcessingStepPresenter.new([])
    assert_equal "text-gray-500", presenter.step_text_classes(@completed_step)
  end

  test "#step_text_classes returns dark gray for non-completed step" do
    presenter = ProcessingStepPresenter.new([])
    assert_equal "text-gray-900", presenter.step_text_classes(@in_progress_step)
    assert_equal "text-gray-900", presenter.step_text_classes(@pending_step)
  end

  test "#line_classes returns blue for completed previous step" do
    presenter = ProcessingStepPresenter.new([])
    assert_equal "bg-blue-600", presenter.line_classes(@completed_step)
  end

  test "#line_classes returns gray for non-completed previous step" do
    presenter = ProcessingStepPresenter.new([])
    assert_equal "bg-gray-200", presenter.line_classes(@in_progress_step)
    assert_equal "bg-gray-200", presenter.line_classes(@pending_step)
  end

  test "#show_spinner? returns false when all steps are completed" do
    completed_steps = [
      OpenStruct.new(step_key: "assignment_saved", status: "completed"),
      OpenStruct.new(step_key: "creating_rubric", status: "completed")
    ]
    presenter = ProcessingStepPresenter.new(completed_steps)
    assert_not presenter.show_spinner?
  end

  test "#show_spinner? returns true when not all steps are completed" do
    mixed_steps = [ @completed_step, @in_progress_step ]
    presenter = ProcessingStepPresenter.new(mixed_steps)
    assert presenter.show_spinner?
  end

  test "#steps_json returns JSON representation of steps" do
    # Mock the to_json method for OpenStruct objects
    @completed_step.define_singleton_method(:to_json) do |options = {}|
      if options[:only]
        { step_key: step_key, status: status }.to_json
      else
        super()
      end
    end

    @in_progress_step.define_singleton_method(:to_json) do |options = {}|
      if options[:only]
        { step_key: step_key, status: status }.to_json
      else
        super()
      end
    end

    steps = [ @completed_step, @in_progress_step ]

    # Mock the to_json method for the array
    steps.define_singleton_method(:to_json) do |options = {}|
      if options[:only]
        map { |step| { step_key: step.step_key, status: step.status } }.to_json
      else
        super()
      end
    end

    presenter = ProcessingStepPresenter.new(steps)

    expected_json = [
      { step_key: "assignment_saved", status: "completed" },
      { step_key: "creating_rubric", status: "in_progress" }
    ].to_json

    assert_equal expected_json, presenter.steps_json
  end

  test "#steps_json returns empty array JSON for empty steps" do
    presenter = ProcessingStepPresenter.new([])
    assert_equal "[]", presenter.steps_json
  end
end
