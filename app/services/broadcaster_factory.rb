# @example Basic usage
#   broadcaster = BroadcasterFactory.create("generate_rubric")
#   result = broadcaster.broadcast(assignment, :processing, { progress: 50 })
#   puts result[:broadcaster_type] # => "rubric_broadcast"
#
# @example With strict mode
#   broadcaster = BroadcasterFactory.create("unknown_type", strict: true)
#   # => raises BroadcasterFactory::UnsupportedProcessTypeError
#
# @example Check supported types
#   BroadcasterFactory.supports?("generate_rubric") # => true
#   BroadcasterFactory.supported_types # => ["generate_rubric", ...]
#
class BroadcasterFactory
  class UnsupportedProcessTypeError < StandardError; end

  # Shared behavior for all broadcaster classes
  module BroadcastBehavior
    def broadcast_base(processable, status, broadcaster_type, data = nil)
      {
        broadcast: status,
        broadcaster_type: broadcaster_type,
        broadcasted_at: Time.current,
        processable_id: processable.id,
        processable_type: processable.class.name,
        progress_percentage: calculate_progress(status),
        data: data
      }
    end

    private

    def calculate_progress(status)
      case status
      when :queued then 0
      when :processing then processing_progress
      when :completed then 100
      when :failed then 0
      else default_progress
      end
    end

    # Override in subclasses for different processing progress values
    def processing_progress
      50
    end

    # Override in subclasses for different default progress values
    def default_progress
      25
    end
  end

  # Default broadcaster for any process type
  # Returns basic structured data with minimal processing
  class DefaultBroadcaster
    def self.broadcast(processable, status, data = nil)
      {
        broadcast: status,
        broadcaster_type: "default",
        broadcasted_at: Time.current,
        processable_id: processable.id,
        processable_type: processable.class.name,
        data: data
      }
    end
  end

  # Placeholder broadcaster for rubric generation
  # TODO: This will be replaced by a dedicated RubricBroadcaster in future tasks
  class RubricBroadcaster
    extend BroadcastBehavior

    def self.broadcast(processable, status, data = nil)
      result = broadcast_base(processable, status, "rubric_broadcast", data)
      # TODO: Add actual rubric broadcasting logic when RubricBroadcaster is implemented
      result[:placeholder] = true
      result
    end

    private

    def self.processing_progress
      50
    end

    def self.default_progress
      25
    end
  end

  # Placeholder broadcaster for student work grading
  # TODO: This will be replaced by a dedicated broadcaster in future tasks
  class StudentWorkBroadcaster
    extend BroadcastBehavior

    def self.broadcast(processable, status, data = nil)
      result = broadcast_base(processable, status, "student_work_broadcast", data)
      # TODO: Add actual student work broadcasting logic when broadcaster is implemented
      result[:placeholder] = true
      result
    end

    private

    def self.processing_progress
      60
    end

    def self.default_progress
      30
    end
  end

  # Placeholder broadcaster for summary feedback
  # TODO: This will be replaced by a dedicated broadcaster in future tasks
  class SummaryFeedbackBroadcaster
    extend BroadcastBehavior

    def self.broadcast(processable, status, data = nil)
      result = broadcast_base(processable, status, "summary_feedback_broadcast", data)
      # TODO: Add actual summary broadcasting logic when broadcaster is implemented
      result[:placeholder] = true
      result
    end

    private

    def self.processing_progress
      45
    end

    def self.default_progress
      20
    end
  end

  # Maps process types to their corresponding broadcaster classes
  BROADCASTER_MAPPING = {
    "generate_rubric" => RubricBroadcaster,
    "grade_student_work" => StudentWorkBroadcaster,
    "generate_summary_feedback" => SummaryFeedbackBroadcaster
  }.freeze

  # Create a broadcaster for the given process type
  #
  # @param process_type [String] The type of processing being performed
  # @param strict [Boolean] Whether to raise an error for unsupported types
  # @param config [Hash] Configuration options for broadcaster initialization (reserved for future use)
  # @return [Object] A broadcaster object that responds to #broadcast
  # @raise [UnsupportedProcessTypeError] When strict mode is enabled and process_type is unsupported
  #
  # @example Create a broadcaster for rubric generation
  #   broadcaster = BroadcasterFactory.create("generate_rubric")
  #   result = broadcaster.broadcast(assignment, :processing, { progress: 50 })
  #
  # @example Handle unknown types gracefully
  #   broadcaster = BroadcasterFactory.create("unknown_type") # Returns DefaultBroadcaster
  #
  # @example Use strict mode
  #   BroadcasterFactory.create("invalid_type", strict: true)
  #   # => raises UnsupportedProcessTypeError
  #
  def self.create(process_type, strict: false, config: {})
    return BROADCASTER_MAPPING[process_type] if BROADCASTER_MAPPING.key?(process_type)

    if strict
      raise UnsupportedProcessTypeError, "Unsupported process type: #{process_type.inspect}"
    end

    # Return default broadcaster for unknown or nil process types
    DefaultBroadcaster
  end

  # Get list of supported process types
  #
  # @return [Array<String>] Array of supported process type strings
  #
  # @example
  #   BroadcasterFactory.supported_types
  #   # => ["generate_rubric", "grade_student_work", "generate_summary_feedback"]
  #
  def self.supported_types
    BROADCASTER_MAPPING.keys
  end

  # Check if a process type is supported
  #
  # @param process_type [String] The process type to check
  # @return [Boolean] True if the process type is supported
  #
  # @example
  #   BroadcasterFactory.supports?("generate_rubric") # => true
  #   BroadcasterFactory.supports?("unknown_type")    # => false
  #
  def self.supports?(process_type)
    BROADCASTER_MAPPING.key?(process_type)
  end
end
