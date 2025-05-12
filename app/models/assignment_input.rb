class AssignmentInput
  attr_reader :user

  def initialize(assignment_params:, user:)
    @assignment_params = assignment_params
    @user = user
  end

  def title
    @assignment_params[:title]
  end

  def subject
    @assignment_params[:subject]
  end

  def grade_level
    @assignment_params[:grade_level]
  end

  def instructions
    @assignment_params[:instructions]
  end

  def raw_rubric_text
    @assignment_params[:raw_rubric_text]
  end

  def feedback_tone
    @assignment_params[:feedback_tone]
  end

  def document_data
    DocumentData.from_json(@assignment_params[:document_data])
  end

  def params
    {
      user: user,
      title: title,
      subject: subject,
      grade_level: grade_level,
      instructions: instructions,
      feedback_tone: feedback_tone
    }
  end
end
