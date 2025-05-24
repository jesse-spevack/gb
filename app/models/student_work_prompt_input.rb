class StudentWorkPromptInput
  attr_reader :student_work_id, :assignment_id, :selected_document_id, :qualitative_feedback,
              :assignment_title, :assignment_subject, :assignment_grade_level,
              :assignment_instructions, :assignment_feedback_tone,
              :selected_document_title, :selected_document_google_doc_id, :selected_document_url,
              :document_content,
              :user_id, :user_name, :user_email,
              :rubric

  def initialize(student_work_id:, assignment_id:, selected_document_id:, qualitative_feedback:,
                 assignment_title:, assignment_subject:, assignment_grade_level:,
                 assignment_instructions:, assignment_feedback_tone:,
                 selected_document_title:, selected_document_google_doc_id:, selected_document_url:,
                 document_content:,
                 user_id: nil, user_name: nil, user_email: nil,
                 rubric: nil)
    @student_work_id = student_work_id
    @assignment_id = assignment_id
    @selected_document_id = selected_document_id
    @qualitative_feedback = qualitative_feedback
    @assignment_title = assignment_title
    @assignment_subject = assignment_subject
    @assignment_grade_level = assignment_grade_level
    @assignment_instructions = assignment_instructions
    @assignment_feedback_tone = assignment_feedback_tone
    @selected_document_title = selected_document_title
    @selected_document_google_doc_id = selected_document_google_doc_id
    @selected_document_url = selected_document_url
    @document_content = document_content
    @user_id = user_id
    @user_name = user_name
    @user_email = user_email
    @rubric = rubric
  end

  def self.from(student_work:, user: nil)
    # Load associations if not already loaded
    student_work = StudentWork.includes(:assignment, :selected_document, assignment: :rubric).find(student_work.id)
    assignment = student_work.assignment
    selected_document = student_work.selected_document

    # Build rubric data if present
    rubric_data = if assignment.rubric.present?
      build_rubric_data(assignment.rubric)
    else
      nil
    end

    new(
      student_work_id: student_work.id,
      assignment_id: student_work.assignment_id,
      selected_document_id: student_work.selected_document_id,
      qualitative_feedback: student_work.qualitative_feedback,
      assignment_title: assignment.title,
      assignment_subject: assignment.subject,
      assignment_grade_level: assignment.grade_level,
      assignment_instructions: assignment.instructions,
      assignment_feedback_tone: assignment.feedback_tone,
      selected_document_title: selected_document.title,
      selected_document_google_doc_id: selected_document.google_doc_id,
      selected_document_url: selected_document.url,
      document_content: fetch_document_content(selected_document),
      user_id: user&.id,
      user_name: user&.name,
      user_email: user&.email,
      rubric: rubric_data
    )
  end

  def rubric_present?
    rubric.present?
  end

  private

  def self.fetch_document_content(selected_document)
    # TODO: Implement Google Docs API call to retrieve document content
    # This would use the selected_document.google_doc_id to fetch content from Google Docs API
    # For now, return a placeholder
    "[Document content would be retrieved from Google Docs API using ID: #{selected_document.google_doc_id}]"
  end

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
