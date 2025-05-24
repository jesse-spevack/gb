# @example Basic usage
#   service = StorageServiceFactory.create("generate_rubric")
#   result = service.store(assignment, parsed_result)
#   puts result[:storage_type] # => "rubric_storage"
#
# @example With strict mode
#   service = StorageServiceFactory.create("unknown_type", strict: true)
#   # => raises StorageServiceFactory::UnsupportedProcessTypeError
#
# @example Check supported types
#   StorageServiceFactory.supports?("generate_rubric") # => true
#   StorageServiceFactory.supported_types # => ["generate_rubric", ...]
#
class StorageServiceFactory
  class UnsupportedProcessTypeError < StandardError; end

  # Default storage service for any process type
  # Returns basic structured data with minimal processing
  class DefaultStorageService
    def self.store(processable, parsed_result)
      {
        stored: true,
        storage_type: "default",
        stored_at: Time.current,
        processable_id: processable.id,
        processable_type: processable.class.name,
        data_size: parsed_result.to_s.length
      }
    end
  end

  # Placeholder storage service for rubric generation
  # TODO: This will be replaced by a dedicated RubricStorageService in future tasks
  class RubricStorageService
    def self.store(processable, parsed_result)
      {
        stored: true,
        storage_type: "rubric_storage",
        stored_at: Time.current,
        processable_id: processable.id,
        processable_type: processable.class.name,
        # TODO: Add actual rubric storage logic when RubricStorageService is implemented
        rubric_stored: true,
        placeholder: true
      }
    end
  end

  # Placeholder storage service for student work grading
  # TODO: This will be replaced by a dedicated storage service in future tasks
  class StudentWorkStorageService
    def self.store(processable, parsed_result)
      {
        stored: true,
        storage_type: "student_work_storage",
        stored_at: Time.current,
        processable_id: processable.id,
        processable_type: processable.class.name,
        # TODO: Add actual student work storage logic when service is implemented
        feedback_stored: true,
        placeholder: true
      }
    end
  end

  # Placeholder storage service for summary feedback
  # TODO: This will be replaced by a dedicated storage service in future tasks
  class SummaryFeedbackStorageService
    def self.store(processable, parsed_result)
      {
        stored: true,
        storage_type: "summary_feedback_storage",
        stored_at: Time.current,
        processable_id: processable.id,
        processable_type: processable.class.name,
        # TODO: Add actual summary storage logic when service is implemented
        summary_stored: true,
        placeholder: true
      }
    end
  end

  # Maps process types to their corresponding storage service classes
  SERVICE_MAPPING = {
    "generate_rubric" => RubricStorageService,
    "grade_student_work" => StudentWorkStorageService,
    "generate_summary_feedback" => SummaryFeedbackStorageService
  }.freeze

  # Create a storage service for the given process type
  #
  # @param process_type [String] The type of processing being performed
  # @param strict [Boolean] Whether to raise an error for unsupported types
  # @param config [Hash] Configuration options for service initialization (reserved for future use)
  # @return [Object] A storage service object that responds to #store
  # @raise [UnsupportedProcessTypeError] When strict mode is enabled and process_type is unsupported
  #
  # @example Create a storage service for rubric generation
  #   service = StorageServiceFactory.create("generate_rubric")
  #   result = service.store(assignment, parsed_result)
  #
  # @example Handle unknown types gracefully
  #   service = StorageServiceFactory.create("unknown_type") # Returns DefaultStorageService
  #
  # @example Use strict mode
  #   StorageServiceFactory.create("invalid_type", strict: true)
  #   # => raises UnsupportedProcessTypeError
  #
  def self.create(process_type, strict: false, config: {})
    return SERVICE_MAPPING[process_type] if SERVICE_MAPPING.key?(process_type)

    if strict
      raise UnsupportedProcessTypeError, "Unsupported process type: #{process_type.inspect}"
    end

    # Return default storage service for unknown or nil process types
    DefaultStorageService
  end

  # Get list of supported process types
  #
  # @return [Array<String>] Array of supported process type strings
  #
  # @example
  #   StorageServiceFactory.supported_types
  #   # => ["generate_rubric", "grade_student_work", "generate_summary_feedback"]
  #
  def self.supported_types
    SERVICE_MAPPING.keys
  end

  # Check if a process type is supported
  #
  # @param process_type [String] The process type to check
  # @return [Boolean] True if the process type is supported
  #
  # @example
  #   StorageServiceFactory.supports?("generate_rubric") # => true
  #   StorageServiceFactory.supports?("unknown_type")    # => false
  #
  def self.supports?(process_type)
    SERVICE_MAPPING.key?(process_type)
  end
end
