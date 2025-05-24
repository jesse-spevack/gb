# @example Basic usage
#   builder = PromptBuilder.new
#   data = DataCollectionService.collect(assignment, "generate_rubric", user)
#   prompt = builder.build("generate_rubric", data)
#   puts prompt # => Rendered prompt text
#
# @example Convenience method for assignments
#   builder = PromptBuilder.new
#   prompt = builder.build_for_assignment(assignment, "generate_rubric", user)
#
# @example Building with metadata
#   builder = PromptBuilder.new
#   result = builder.build_with_metadata("generate_rubric", data)
#   puts result[:prompt]
#   puts result[:metadata][:prompt_length]
#
class PromptBuilder
  class PromptGenerationError < StandardError; end
  class InvalidContextError < StandardError; end

  def initialize
    @template = PromptTemplate.new
    @logger = Rails.logger
  end

  # Build a prompt for the given process type with the provided data
  #
  # @param process_type [String] The type of processing ("generate_rubric", "grade_student_work", "generate_summary_feedback")
  # @param data [Hash] The data collected by DataCollectionService for template interpolation
  # @return [String] The rendered prompt text ready for LLM processing
  # @raise [PromptGenerationError] When prompt generation fails
  # @raise [InvalidContextError] When data context doesn't match process type
  #
  # @example Build a rubric generation prompt
  #   data = DataCollectionService.collect(assignment, "generate_rubric", user)
  #   prompt = builder.build("generate_rubric", data)
  #
  def build(process_type, data)
    @logger.info("Building prompt for #{process_type}")

    validate_data_context!(process_type, data)

    begin
      prompt = @template.build(process_type, data)
      validate_prompt_quality!(prompt)

      @logger.info("Successfully built prompt for #{process_type} (#{prompt.length} characters)")
      prompt
    rescue => e
      @logger.error("Failed to generate prompt for #{process_type}: #{e.message}")
      raise PromptGenerationError, "Failed to generate prompt for #{process_type}: #{e.message}"
    end
  end

  # Build a prompt with additional metadata
  #
  # @param process_type [String] The type of processing
  # @param data [Hash] The data for template interpolation
  # @return [Hash] Hash containing :prompt and :metadata keys
  #
  # @example Build with metadata
  #   result = builder.build_with_metadata("generate_rubric", data)
  #   # => { prompt: "...", metadata: { process_type: "generate_rubric", ... } }
  #
  def build_with_metadata(process_type, data)
    generated_at = Time.current
    prompt = build(process_type, data)

    {
      prompt: prompt,
      metadata: {
        process_type: process_type,
        generated_at: generated_at,
        prompt_length: prompt.length,
        data_size: data.to_s.length,
        template_used: @template.class::TEMPLATE_MAPPING[process_type]
      }
    }
  end

  # Convenience method for building assignment-level prompts
  #
  # @param assignment [Assignment] The assignment object
  # @param process_type [String] The type of processing ("generate_rubric" or "generate_summary_feedback")
  # @param user [User] The user initiating the process
  # @return [String] The rendered prompt text
  #
  # @example Build rubric generation prompt
  #   prompt = builder.build_for_assignment(assignment, "generate_rubric", user)
  #
  def build_for_assignment(assignment, process_type, user = nil)
    unless %w[generate_rubric generate_summary_feedback].include?(process_type)
      raise InvalidContextError, "Invalid process type '#{process_type}' for assignment context. Use 'generate_rubric' or 'generate_summary_feedback'."
    end

    data = DataCollectionService.collect(assignment, process_type, user)
    build(process_type, data)
  end

  # Convenience method for building student work feedback prompts
  #
  # @param student_work [StudentWork] The student work object
  # @param user [User] The user initiating the process
  # @return [String] The rendered prompt text
  #
  # @example Build student work feedback prompt
  #   prompt = builder.build_for_student_work(student_work, user)
  #
  def build_for_student_work(student_work, user = nil)
    data = DataCollectionService.collect(student_work, "grade_student_work", user)
    build("grade_student_work", data)
  end

  # Clear the underlying template cache
  #
  # @example Clear cache to reload templates in development
  #   builder.clear_cache!
  #
  def clear_cache!
    @template.clear_cache!
    @logger.info("Cleared prompt template cache")
  end

  private

  # Validate that the data context matches the expected process type
  def validate_data_context!(process_type, data)
    return unless data.is_a?(Hash)

    case process_type
    when "generate_rubric", "generate_summary_feedback"
      validate_assignment_context!(data, process_type)
    when "grade_student_work"
      validate_student_work_context!(data)
    end
  end

  # Validate data for assignment-level processes
  def validate_assignment_context!(data, process_type)
    unless data[:processable_type] == "Assignment"
      raise InvalidContextError,
            "Invalid data context for #{process_type}: expected Assignment processable, got #{data[:processable_type]}"
    end
  end

  # Validate data for student work grading
  def validate_student_work_context!(data)
    unless data[:processable_type] == "StudentWork"
      raise InvalidContextError,
            "Invalid data context for grade_student_work: expected StudentWork processable, got #{data[:processable_type]}"
    end
  end

  # Validate that the generated prompt meets quality standards
  def validate_prompt_quality!(prompt)
    if prompt.blank?
      raise PromptGenerationError, "Generated prompt is empty"
    end

    if prompt.length < 50
      @logger.warn("Generated prompt is suspiciously short (#{prompt.length} characters)")
    end

    if prompt.length > 20000
      @logger.warn("Generated prompt is very long (#{prompt.length} characters)")
    end
  end
end
