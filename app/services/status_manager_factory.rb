# @example Basic usage
#   manager = StatusManagerFactory.create("generate_rubric")
#   result = manager.update_status(assignment, :processing)
#   puts result[:status_type] # => "assignment_status"
#
# @example With strict mode
#   manager = StatusManagerFactory.create("unknown_type", strict: true)
#   # => raises StatusManagerFactory::UnsupportedProcessTypeError
#
# @example Check supported types
#   StatusManagerFactory.supports?("generate_rubric") # => true
#   StatusManagerFactory.supported_types # => ["generate_rubric", ...]
#
class StatusManagerFactory
  class UnsupportedProcessTypeError < StandardError; end

  # Shared behavior for all status manager classes
  module StatusUpdateBehavior
    def status_update_base(processable, status, status_type)
      {
        status_updated: true,
        status_type: status_type,
        updated_at: Time.current,
        processable_id: processable.id,
        processable_type: processable.class.name,
        status: status,
        previous_status: get_previous_status(processable),
        metadata: get_status_metadata(processable, status)
      }
    end

    private

    def get_previous_status(processable)
      # TODO: Implement actual status tracking when status persistence is added
      :unknown
    end

    def get_status_metadata(processable, status)
      # Override in subclasses for different metadata collection
      {
        status_changed_at: Time.current,
        processable_type: processable.class.name,
        processable_id: processable.id
      }
    end
  end

  # Default status manager for any process type
  # Returns basic structured data with minimal processing
  class DefaultStatusManager
    def self.update_status(processable, status)
      {
        status_updated: true,
        status_type: "default",
        updated_at: Time.current,
        processable_id: processable.id,
        processable_type: processable.class.name,
        status: status
      }
    end
  end

  # Status manager for assignment-level processing (rubric generation, summary feedback)
  # TODO: This will be enhanced when Assignment status tracking is implemented
  class AssignmentStatusManager
    extend StatusUpdateBehavior

    def self.update_status(processable, status)
      result = status_update_base(processable, status, "assignment_status")
      # TODO: Add actual assignment status persistence when Assignment status fields are added
      result[:assignment_updated] = true
      result[:placeholder] = true
      result
    end

    private

    def self.get_status_metadata(processable, status)
      super.merge(
        assignment_id: processable.id,
        process_context: "assignment_level",
        estimated_completion: estimate_completion_time(status)
      )
    end

    def self.estimate_completion_time(status)
      # TODO: Replace with actual time estimation when ProcessingTimeEstimator is implemented
      case status
      when :queued then 5.minutes.from_now
      when :processing then 3.minutes.from_now
      when :completed, :failed then Time.current
      else 2.minutes.from_now
      end
    end
  end

  # Status manager for student work processing
  # TODO: This will be enhanced when StudentWork status tracking is implemented
  class StudentWorkStatusManager
    extend StatusUpdateBehavior

    def self.update_status(processable, status)
      result = status_update_base(processable, status, "student_work_status")
      # TODO: Add actual student work status persistence when StudentWork status fields are added
      result[:student_work_updated] = true
      result[:placeholder] = true
      result
    end

    private

    def self.get_status_metadata(processable, status)
      super.merge(
        student_work_id: processable.id,
        process_context: "student_work_level",
        assignment_id: processable.assignment_id,
        document_id: processable.selected_document_id
      )
    end
  end

  # Maps process types to their corresponding status manager classes
  MANAGER_MAPPING = {
    "generate_rubric" => AssignmentStatusManager,
    "grade_student_work" => StudentWorkStatusManager,
    "generate_summary_feedback" => AssignmentStatusManager
  }.freeze

  # Create a status manager for the given process type
  #
  # @param process_type [String] The type of processing being performed
  # @param strict [Boolean] Whether to raise an error for unsupported types
  # @param config [Hash] Configuration options for manager initialization (reserved for future use)
  # @return [Object] A status manager object that responds to #update_status
  # @raise [UnsupportedProcessTypeError] When strict mode is enabled and process_type is unsupported
  #
  # @example Create a status manager for rubric generation
  #   manager = StatusManagerFactory.create("generate_rubric")
  #   result = manager.update_status(assignment, :processing)
  #
  # @example Handle unknown types gracefully
  #   manager = StatusManagerFactory.create("unknown_type") # Returns DefaultStatusManager
  #
  # @example Use strict mode
  #   StatusManagerFactory.create("invalid_type", strict: true)
  #   # => raises UnsupportedProcessTypeError
  #
  def self.create(process_type, strict: false, config: {})
    return MANAGER_MAPPING[process_type] if MANAGER_MAPPING.key?(process_type)

    if strict
      raise UnsupportedProcessTypeError, "Unsupported process type: #{process_type.inspect}"
    end

    # Return default status manager for unknown or nil process types
    DefaultStatusManager
  end

  # Get list of supported process types
  #
  # @return [Array<String>] Array of supported process type strings
  #
  # @example
  #   StatusManagerFactory.supported_types
  #   # => ["generate_rubric", "grade_student_work", "generate_summary_feedback"]
  #
  def self.supported_types
    MANAGER_MAPPING.keys
  end

  # Check if a process type is supported
  #
  # @param process_type [String] The process type to check
  # @return [Boolean] True if the process type is supported
  #
  # @example
  #   StatusManagerFactory.supports?("generate_rubric") # => true
  #   StatusManagerFactory.supports?("unknown_type")    # => false
  #
  def self.supports?(process_type)
    MANAGER_MAPPING.key?(process_type)
  end
end
