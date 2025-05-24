class SummaryFeedbackPromptInput
  attr_reader :assignment_id, :assignment_title, :assignment_subject, :assignment_grade_level,
              :assignment_instructions, :assignment_feedback_tone,
              :student_works, :user_id, :user_name, :user_email, :rubric

  def initialize(assignment_id:, assignment_title:, assignment_subject:, assignment_grade_level:,
                 assignment_instructions:, assignment_feedback_tone:,
                 student_works:, user_id: nil, user_name: nil, user_email: nil, rubric: nil)
    @assignment_id = assignment_id
    @assignment_title = assignment_title
    @assignment_subject = assignment_subject
    @assignment_grade_level = assignment_grade_level
    @assignment_instructions = assignment_instructions
    @assignment_feedback_tone = assignment_feedback_tone
    @student_works = student_works
    @user_id = user_id
    @user_name = user_name
    @user_email = user_email
    @rubric = rubric
  end

  def self.from(assignment:, user: nil)
    # Load associations if not already loaded
    assignment = Assignment.includes(:student_works, :rubric, rubric: [ :criteria, criteria: :levels ]).find(assignment.id)

    # Build student works data
    student_works_data = assignment.student_works.map do |student_work|
      {
        id: student_work.id,
        assignment_id: student_work.assignment_id,
        selected_document_id: student_work.selected_document_id,
        qualitative_feedback: student_work.qualitative_feedback,
        created_at: student_work.created_at
      }
    end

    # Build rubric data if present
    rubric_data = if assignment.rubric.present?
      build_rubric_data(assignment.rubric)
    else
      nil
    end

    new(
      assignment_id: assignment.id,
      assignment_title: assignment.title,
      assignment_subject: assignment.subject,
      assignment_grade_level: assignment.grade_level,
      assignment_instructions: assignment.instructions,
      assignment_feedback_tone: assignment.feedback_tone,
      student_works: student_works_data,
      user_id: user&.id,
      user_name: user&.name,
      user_email: user&.email,
      rubric: rubric_data
    )
  end

  def student_works_count
    student_works.length
  end

  def rubric_present?
    rubric.present?
  end

  private

  def self.build_rubric_data(rubric)
    criteria_data = rubric.criteria.includes(:levels).map do |criterion|
      {
        id: criterion.id,
        title: criterion.title,
        description: criterion.description,
        position: criterion.position,
        levels: criterion.levels.order(:position).map do |level|
          {
            id: level.id,
            title: level.title,
            description: level.description,
            position: level.position
          }
        end
      }
    end

    {
      id: rubric.id,
      assignment_id: rubric.assignment_id,
      criteria: criteria_data,
      created_at: rubric.created_at
    }
  end
end
