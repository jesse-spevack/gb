class PromptBuilder
  def self.build_for(task)
    new(task).build
  end


  def initialize(task)
    @task = task
    @template = template
  end

  def build
    PromptTemplate.build(
      template: @template,
      input: input
    )
  end

  private

  def template
    case @task.process_type
    when :generate_rubric
      "rubric_generation.txt.erb"
    when :generate_student_work_feedback
      "student_feedback.txt.erb"
    when :generate_assignment_summary_feedback
      "assignment_summary.txt.erb"
    end
  end

  def input
    case @task.process_type
    when :generate_rubric
      PromptInput::Rubric.from(assignment: @task.processable)
    when :generate_student_work_feedback
      PromptInput::StudentWorkFeedback.from(student_work: @task.processable)
    when :generate_assignment_summary_feedback
      PromptInput::AssignmentSummary.from(assignment: @task.processable)
    end
  end
end
