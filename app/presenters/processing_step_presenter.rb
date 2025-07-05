class ProcessingStepPresenter
  STEP_DISPLAY_NAMES = {
    "assignment_saved" => "Assignment Saved",
    "creating_rubric" => "Creating Rubric",
    "generating_feedback" => "Grading Work",
    "summarizing_feedback" => "Generating Summary"
  }.freeze

  STATUS_MESSAGES = {
    "creating_rubric" => "GradeBot is generating a rubric...",
    "generating_feedback" => "GradeBot is analyzing student work...",
    "summarizing_feedback" => "GradeBot is summarizing analysis..."
  }.freeze

  def initialize(processing_steps)
    @steps = processing_steps
  end

  def current_step
    @current_step ||= @steps.find { |s| s.status == "in_progress" }
  end

  def all_completed?
    @steps.all? { |s| s.status == "completed" }
  end

  def status_message
    return "Assignment processing complete!" if all_completed?
    return STATUS_MESSAGES[current_step.step_key] if current_step && STATUS_MESSAGES[current_step.step_key]
    "Preparing to process assignment..."
  end

  def display_name_for(step_key)
    STEP_DISPLAY_NAMES[step_key] || step_key.humanize
  end

  def display_name_with_breaks(step_key)
    display_name_for(step_key).split.join("<br>").html_safe
  end

  def step_circle_classes(step)
    if step.status == "completed" || step.status == "in_progress"
      "bg-blue-600"
    else
      "bg-gray-200"
    end
  end

  def step_number_classes(step)
    step.status == "in_progress" ? "text-white" : "text-gray-900"
  end

  def step_text_classes(step)
    step.status == "completed" ? "text-gray-500" : "text-gray-900"
  end

  def line_classes(previous_step)
    previous_step.status == "completed" ? "bg-blue-600" : "bg-gray-200"
  end

  def show_spinner?
    !all_completed?
  end

  def steps_json
    @steps.to_json(only: [ :step_key, :status ])
  end
end
