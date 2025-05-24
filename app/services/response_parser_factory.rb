# @example Basic usage
#   parser = ResponseParserFactory.create("generate_rubric")
#   result = parser.parse("LLM response text")
#   puts result[:parser_type] # => "rubric_generation"
#
# @example With strict mode
#   parser = ResponseParserFactory.create("unknown_type", strict: true)
#   # => raises ResponseParserFactory::UnsupportedProcessTypeError
#
# @example Check supported types
#   ResponseParserFactory.supports?("generate_rubric") # => true
#   ResponseParserFactory.supported_types # => ["generate_rubric", ...]
#
class ResponseParserFactory
  class UnsupportedProcessTypeError < StandardError; end

  # Default parser for any process type
  # Returns basic structured data with minimal processing
  class DefaultResponseParser
    def self.parse(response_text)
      {
        raw_response: response_text,
        parsed_at: Time.current,
        parser_type: "default"
      }
    end
  end

  # Placeholder parser for rubric generation
  # TODO: This will be replaced by a dedicated RubricResponseParser in task 57
  class RubricResponseParser
    def self.parse(response_text)
      {
        raw_response: response_text,
        parsed_at: Time.current,
        parser_type: "rubric_generation",
        # TODO: Add actual rubric parsing logic when RubricResponseParser is implemented
        rubric_data: { placeholder: true }
      }
    end
  end

  # Placeholder parser for student work grading
  # TODO: This will be replaced by a dedicated parser in future tasks
  class StudentWorkResponseParser
    def self.parse(response_text)
      {
        raw_response: response_text,
        parsed_at: Time.current,
        parser_type: "student_work_grading",
        # TODO: Add actual grading parsing logic when parser is implemented
        grading_data: { placeholder: true }
      }
    end
  end

  # Placeholder parser for summary feedback
  # TODO: This will be replaced by a dedicated parser in future tasks
  class SummaryFeedbackResponseParser
    def self.parse(response_text)
      {
        raw_response: response_text,
        parsed_at: Time.current,
        parser_type: "summary_feedback",
        # TODO: Add actual summary parsing logic when parser is implemented
        summary_data: { placeholder: true }
      }
    end
  end

  # Maps process types to their corresponding parser classes
  PARSER_MAPPING = {
    "generate_rubric" => RubricResponseParser,
    "grade_student_work" => StudentWorkResponseParser,
    "generate_summary_feedback" => SummaryFeedbackResponseParser
  }.freeze

  # Create a response parser for the given process type
  #
  # @param process_type [String] The type of processing being performed
  # @param strict [Boolean] Whether to raise an error for unsupported types
  # @param config [Hash] Configuration options for parser initialization (reserved for future use)
  # @return [Object] A parser object that responds to #parse
  # @raise [UnsupportedProcessTypeError] When strict mode is enabled and process_type is unsupported
  #
  # @example Create a parser for rubric generation
  #   parser = ResponseParserFactory.create("generate_rubric")
  #   result = parser.parse("Generated rubric content")
  #
  # @example Handle unknown types gracefully
  #   parser = ResponseParserFactory.create("unknown_type") # Returns DefaultResponseParser
  #
  # @example Use strict mode
  #   ResponseParserFactory.create("invalid_type", strict: true)
  #   # => raises UnsupportedProcessTypeError
  #
  def self.create(process_type, strict: false, config: {})
    return PARSER_MAPPING[process_type] if PARSER_MAPPING.key?(process_type)

    if strict
      raise UnsupportedProcessTypeError, "Unsupported process type: #{process_type.inspect}"
    end

    # Return default parser for unknown or nil process types
    DefaultResponseParser
  end

  # Get list of supported process types
  #
  # @return [Array<String>] Array of supported process type strings
  #
  # @example
  #   ResponseParserFactory.supported_types
  #   # => ["generate_rubric", "grade_student_work", "generate_summary_feedback"]
  #
  def self.supported_types
    PARSER_MAPPING.keys
  end

  # Check if a process type is supported
  #
  # @param process_type [String] The process type to check
  # @return [Boolean] True if the process type is supported
  #
  # @example
  #   ResponseParserFactory.supports?("generate_rubric") # => true
  #   ResponseParserFactory.supports?("unknown_type")    # => false
  #
  def self.supports?(process_type)
    PARSER_MAPPING.key?(process_type)
  end
end
