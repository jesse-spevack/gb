class ProcessingTask
  attr_reader :processable, :process_type, :user, :configuration
  attr_accessor :started_at, :completed_at, :error_message, :metrics

  VALID_PROCESS_TYPES = [
    "generate_rubric",
    "grade_student_work",
    "generate_summary_feedback"
  ].freeze

  def initialize(processable:, process_type:, user: nil, configuration:)
    @processable = processable
    @process_type = process_type
    @user = user
    @configuration = configuration
    @metrics = {}.with_indifferent_access
    validate!
  end

  # Configuration accessors - delegate to configuration object
  def prompt_template
    configuration.prompt_template
  end

  def response_parser
    configuration.response_parser
  end

  def storage_service
    configuration.storage_service
  end

  def broadcaster
    configuration.broadcaster
  end

  def status_manager
    configuration.status_manager
  end

  # Timing methods
  def mark_started
    @started_at = Time.current
  end

  def mark_completed
    @completed_at = Time.current
  end

  def processing_time_ms
    return 0 unless started_at && completed_at
    ((completed_at - started_at) * 1000).to_i
  end

  def record_metric(key, value)
    @metrics[key] = value
  end

  private

  def validate!
    raise ArgumentError, "Processable is required" unless processable
    raise ArgumentError, "Process type is required" unless process_type
    raise ArgumentError, "Configuration is required" unless configuration
    raise ArgumentError, "Invalid process type: #{process_type}" unless VALID_PROCESS_TYPES.include?(process_type)
  end
end
