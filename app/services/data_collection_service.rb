# @example Basic usage
#   rubric_prompt_input = DataCollectionService.collect(assignment, "generate_rubric", user)
#   puts rubric_prompt_input.assignment_title # => "Essay Assignment"
#
# @example For student work grading
#   student_work_prompt_input = DataCollectionService.collect(student_work, "grade_student_work", user)
#   puts student_work_prompt_input.student_work_id
#   puts student_work_prompt_input.assignment_instructions
#
# @example For assignment summary
#   summary_feedback_prompt_input = DataCollectionService.collect(assignment, "generate_summary_feedback", user)
#   puts summary_feedback_prompt_input.student_works_count
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
  # @return [Object] Template-specific data (RubricPromptInput for rubric generation, StudentWorkPromptInput for student grading, SummaryFeedbackPromptInput for assignment summaries)
  # @raise [UnsupportedProcessableError] When processable type is not supported
  # @raise [UnsupportedProcessTypeError] When process type is not supported
  #
  # @example Collect data for rubric generation
  #   rubric_prompt_input = DataCollectionService.collect(assignment, "generate_rubric", user)
  #   # => RubricPromptInput instance
  #
  def self.collect(processable, process_type, user = nil)
    validate_inputs!(processable, process_type)

    case process_type
    when "generate_rubric"
      collect_rubric_generation_data(processable, user)
    when "grade_student_work"
      collect_student_work_grading_data(processable, user)
    when "generate_summary_feedback"
      collect_summary_feedback_data(processable, user)
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

  # Collect data specific to rubric generation (Assignment processable)
  def self.collect_rubric_generation_data(assignment, user)
    RubricPromptInput.from(assignment: assignment)
  end

  # Collect data specific to student work grading (StudentWork processable)
  def self.collect_student_work_grading_data(student_work, user)
    StudentWorkPromptInput.from(student_work: student_work, user: user)
  end

  # Collect data specific to assignment summary generation (Assignment processable)
  def self.collect_summary_feedback_data(assignment, user)
    SummaryFeedbackPromptInput.from(assignment: assignment, user: user)
  end
end
