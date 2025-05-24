# @example Basic usage
#   template = PromptTemplate.new
#   rubric_prompt_input = DataCollectionService.collect(assignment, "generate_rubric", user)
#   prompt = template.build("generate_rubric", rubric_prompt_input)
#   puts prompt # => Rendered prompt with interpolated variables
#
# @example Template caching
#   template = PromptTemplate.new
#   rubric_prompt_input = DataCollectionService.collect(assignment, "generate_rubric", user)
#   # First call loads template from file
#   prompt1 = template.build("generate_rubric", rubric_prompt_input)
#   # Second call uses cached template
#   prompt2 = template.build("generate_rubric", rubric_prompt_input)
#
class PromptTemplate
  class UnsupportedProcessTypeError < StandardError; end
  class InvalidDataError < StandardError; end

  SUPPORTED_PROCESS_TYPES = [
    "generate_rubric",
    "grade_student_work",
    "generate_summary_feedback"
  ].freeze

  # Maps process types to their corresponding template filenames
  TEMPLATE_MAPPING = {
    "generate_rubric" => "rubric_generation.txt.erb",
    "grade_student_work" => "student_feedback.txt.erb",
    "generate_summary_feedback" => "assignment_summary.txt.erb"
  }.freeze

  def initialize
    @template_dir = Rails.root.join("app", "views", "prompts")
  end

  # Build a prompt for the given process type with the provided data
  #
  # @param process_type [String] The type of processing ("generate_rubric", "grade_student_work", "generate_summary_feedback")
  # @param data [Object] The data collected by DataCollectionService (RubricPromptInput for rubric generation, StudentWorkPromptInput for student grading, SummaryFeedbackPromptInput for assignment summaries)
  # @return [String] The rendered prompt text ready for LLM processing
  # @raise [UnsupportedProcessTypeError] When process_type is not supported
  # @raise [InvalidDataError] When required data fields are missing
  #
  # @example Build a rubric generation prompt
  #   rubric_prompt_input = DataCollectionService.collect(assignment, "generate_rubric", user)
  #   prompt = template.build("generate_rubric", rubric_prompt_input)
  #
  def build(process_type, data)
    validate_process_type!(process_type)
    validate_data!(data, process_type)

    erb_template = load_template(process_type)
    render_template(erb_template, data)
  end

  # Check if a process type is supported
  #
  # @param process_type [String] The process type to check
  # @return [Boolean] True if the process type is supported
  #
  # @example
  #   PromptTemplate.supports?("generate_rubric") # => true
  #   PromptTemplate.supports?("unknown_type")    # => false
  #
  def self.supports?(process_type)
    SUPPORTED_PROCESS_TYPES.include?(process_type)
  end

  # Get list of supported process types
  #
  # @return [Array<String>] Array of supported process type strings
  #
  # @example
  #   PromptTemplate.supported_types
  #   # => ["generate_rubric", "grade_student_work", "generate_summary_feedback"]
  #
  def self.supported_types
    SUPPORTED_PROCESS_TYPES.dup
  end

  private

  # Validate that the process type is supported
  def validate_process_type!(process_type)
    unless SUPPORTED_PROCESS_TYPES.include?(process_type)
      raise UnsupportedProcessTypeError,
            "Unsupported process type: #{process_type.inspect}. " +
            "Supported types: #{SUPPORTED_PROCESS_TYPES.join(', ')}"
    end
  end

  # Validate that the required data fields are present
  def validate_data!(data, process_type)
    case process_type
    when "generate_rubric"
      validate_rubric_data!(data)
    when "grade_student_work"
      validate_student_work_data!(data)
    when "generate_summary_feedback"
      validate_summary_data!(data)
    end
  end

  # Validate data for rubric generation
  def validate_rubric_data!(data)
    unless data.is_a?(RubricPromptInput)
      raise InvalidDataError, "Invalid or incomplete data for rubric generation: missing rubric_prompt_input"
    end
  end

  # Validate data for student work grading
  def validate_student_work_data!(data)
    unless data.is_a?(StudentWorkPromptInput)
      raise InvalidDataError, "Invalid or incomplete data for student work grading: missing student_work_prompt_input"
    end
  end

  # Validate data for assignment summary
  def validate_summary_data!(data)
    unless data.is_a?(SummaryFeedbackPromptInput)
      raise InvalidDataError, "Invalid or incomplete data for assignment summary: missing summary_feedback_prompt_input"
    end
  end

  # Load ERB template from file system
  def load_template(process_type)
    template_filename = TEMPLATE_MAPPING[process_type]
    template_path = @template_dir.join(template_filename)

    template_content = File.read(template_path)
    ERB.new(template_content, trim_mode: "-")
  end

  # Render ERB template with provided data
  def render_template(erb_template, data)
    template_binding = binding

    # Set the appropriate variable name based on data type
    case data
    when RubricPromptInput
      template_binding.local_variable_set(:rubric_prompt_input, data)
    when StudentWorkPromptInput
      template_binding.local_variable_set(:student_work_prompt_input, data)
    when SummaryFeedbackPromptInput
      template_binding.local_variable_set(:summary_feedback_prompt_input, data)
    else
      # Fallback for legacy hash structure (shouldn't be needed anymore)
      template_binding.local_variable_set(:data, data)
    end

    erb_template.result(template_binding)
  end
end
