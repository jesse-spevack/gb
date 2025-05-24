# @example Basic usage
#   data = DataCollectionService.collect(assignment, "generate_rubric", user)
#   puts data[:assignment][:title] # => "Essay Assignment"
#
# @example For student work grading
#   data = DataCollectionService.collect(student_work, "grade_student_work", user)
#   puts data[:student_work][:id]
#   puts data[:assignment][:instructions]
#
# @example For assignment summary
#   data = DataCollectionService.collect(assignment, "generate_summary_feedback", user)
#   puts data[:student_works].length
#
class DataCollectionService
  class UnsupportedProcessableError < StandardError; end
  class UnsupportedProcessTypeError < StandardError; end

  SUPPORTED_PROCESS_TYPES = [
    "generate_rubric",
    "grade_student_work",
    "generate_summary_feedback"
  ].freeze

  SUPPORTED_PROCESSABLE_TYPES = [
    Assignment,
    StudentWork
  ].freeze

  # Collect data for LLM processing based on processable object and process type
  #
  # @param processable [Object] The main object being processed (Assignment or StudentWork)
  # @param process_type [String] The type of processing ("generate_rubric", "grade_student_work", "generate_summary_feedback")
  # @param user [User, nil] The user initiating the process (optional)
  # @return [Hash] Collected data structured for the specific process type
  # @raise [UnsupportedProcessableError] When processable type is not supported
  # @raise [UnsupportedProcessTypeError] When process type is not supported
  #
  # @example Collect data for rubric generation
  #   data = DataCollectionService.collect(assignment, "generate_rubric", user)
  #   # => { processable_type: "Assignment", assignment: {...}, user: {...}, ... }
  #
  def self.collect(processable, process_type, user = nil)
    validate_inputs!(processable, process_type)

    data = build_base_data(processable, process_type, user)

    case process_type
    when "generate_rubric"
      collect_rubric_generation_data(data, processable, user)
    when "grade_student_work"
      collect_student_work_grading_data(data, processable, user)
    when "generate_summary_feedback"
      collect_summary_feedback_data(data, processable, user)
    end
  end

  private

  # Validate that inputs are supported
  def self.validate_inputs!(processable, process_type)
    unless SUPPORTED_PROCESSABLE_TYPES.include?(processable.class)
      raise UnsupportedProcessableError,
            "Unsupported processable type: #{processable.class.name}. " +
            "Supported types: #{SUPPORTED_PROCESSABLE_TYPES.map(&:name).join(', ')}"
    end

    unless SUPPORTED_PROCESS_TYPES.include?(process_type)
      raise UnsupportedProcessTypeError,
            "Unsupported process type: #{process_type.inspect}. " +
            "Supported types: #{SUPPORTED_PROCESS_TYPES.join(', ')}"
    end
  end

  # Build the base data structure common to all process types
  def self.build_base_data(processable, process_type, user)
    {
      processable_type: processable.class.name,
      processable_id: processable.id,
      process_type: process_type,
      user_id: user&.id,
      collected_at: Time.current
    }
  end

  # Collect data specific to rubric generation (Assignment processable)
  def self.collect_rubric_generation_data(data, assignment, user)
    data[:assignment] = serialize_assignment(assignment)
    data[:user] = serialize_user(user) if user
    data[:rubric] = serialize_existing_rubric(assignment) if assignment.rubric.present?
    data
  end

  # Collect data specific to student work grading (StudentWork processable)
  def self.collect_student_work_grading_data(data, student_work, user)
    # Load associations efficiently to avoid N+1 queries
    student_work = StudentWork.includes(:assignment, :selected_document, assignment: :rubric).find(student_work.id)

    data[:student_work] = serialize_student_work(student_work)
    data[:assignment] = serialize_assignment(student_work.assignment)
    data[:selected_document] = serialize_selected_document(student_work.selected_document)
    data[:user] = serialize_user(user) if user
    data[:rubric] = serialize_existing_rubric(student_work.assignment) if student_work.assignment.rubric.present?
    data
  end

  # Collect data specific to assignment summary generation (Assignment processable)
  def self.collect_summary_feedback_data(data, assignment, user)
    # Load associations efficiently to avoid N+1 queries
    assignment = Assignment.includes(:student_works, :rubric, rubric: [ :criteria, criteria: :levels ]).find(assignment.id)

    data[:assignment] = serialize_assignment(assignment)
    data[:student_works] = assignment.student_works.map { |sw| serialize_student_work(sw) }
    data[:user] = serialize_user(user) if user
    data[:rubric] = serialize_existing_rubric(assignment) if assignment.rubric.present?
    data
  end

  # Serialize Assignment data for LLM processing
  def self.serialize_assignment(assignment)
    result = {
      id: assignment.id,
      title: assignment.title,
      subject: assignment.subject,
      grade_level: assignment.grade_level,
      instructions: assignment.instructions,
      feedback_tone: assignment.feedback_tone,
      created_at: assignment.created_at
    }

    # Include existing rubric text if present
    result[:rubric_text] = assignment.rubric_text if assignment.rubric_text.present?

    result
  end

  # Serialize StudentWork data for LLM processing
  def self.serialize_student_work(student_work)
    {
      id: student_work.id,
      assignment_id: student_work.assignment_id,
      selected_document_id: student_work.selected_document_id,
      qualitative_feedback: student_work.qualitative_feedback,
      created_at: student_work.created_at
    }
  end

  # Serialize SelectedDocument data for LLM processing
  def self.serialize_selected_document(selected_document)
    {
      id: selected_document.id,
      google_doc_id: selected_document.google_doc_id,
      title: selected_document.title,
      url: selected_document.url
    }
  end

  # Serialize User data for LLM processing
  def self.serialize_user(user)
    return nil unless user

    {
      id: user.id,
      name: user.name,
      email: user.email
    }
  end

  # Serialize existing Rubric data for LLM processing
  def self.serialize_existing_rubric(assignment)
    return nil unless assignment.rubric.present?

    rubric = assignment.rubric
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
