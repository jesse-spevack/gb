class RubricPromptInput
  attr_reader :assignment_title, :subject, :grade_level, :instructions,
              :rubric_text, :feedback_tone

  def initialize(assignment_title:, subject:, grade_level:, instructions:,
                 rubric_text: nil, feedback_tone:)
    @assignment_title = assignment_title
    @subject = subject
    @grade_level = grade_level
    @instructions = instructions
    @rubric_text = rubric_text
    @feedback_tone = feedback_tone
  end

  def self.from(assignment:)
    new(
      assignment_title: assignment.title,
      subject: assignment.subject,
      grade_level: assignment.grade_level,
      instructions: assignment.instructions,
      rubric_text: assignment.rubric_text,
      feedback_tone: assignment.feedback_tone
    )
  end

  def rubric_text_present?
    rubric_text.present?
  end
end
