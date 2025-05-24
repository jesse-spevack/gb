require "test_helper"

class ProcessingTaskTest < ActiveSupport::TestCase
  def setup
    @valid_configuration = ProcessingTaskConfiguration.new(
      prompt_template: "MockPromptTemplate",
      response_parser: "MockResponseParser",
      storage_service: "MockStorageService",
      broadcaster: "MockBroadcaster",
      status_manager: "MockStatusManager"
    )

    @assignment = assignments(:english_essay)
    @user = users(:teacher)
  end

  test "initializes with valid parameters" do
    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      user: @user,
      configuration: @valid_configuration,
    )

    assert_equal @assignment, task.processable
    assert_equal "generate_rubric", task.process_type
    assert_equal @user, task.user
    assert_equal @valid_configuration, task.configuration
    assert_equal({}, task.metrics)
  end

  test "initializes without optional parameters" do
    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      configuration: @valid_configuration
    )

    assert_equal @assignment, task.processable
    assert_equal "generate_rubric", task.process_type
    assert_nil task.user
    assert_equal({}, task.metrics)
  end

  test "raises error when processable is missing" do
    assert_raises(ArgumentError, "Processable is required") do
      ProcessingTask.new(
        process_type: "generate_rubric",
        configuration: @valid_configuration
      )
    end
  end

  test "raises error when process_type is missing" do
    assert_raises(ArgumentError, "Process type is required") do
      ProcessingTask.new(
        processable: @assignment,
        configuration: @valid_configuration
      )
    end
  end

  test "raises error when configuration is missing" do
    assert_raises(ArgumentError, "Configuration is required") do
      ProcessingTask.new(
        processable: @assignment,
        process_type: "generate_rubric"
      )
    end
  end

  test "validates process_type is in VALID_PROCESS_TYPES" do
    assert_raises(ArgumentError, "Invalid process type: invalid_type") do
      ProcessingTask.new(
        processable: @assignment,
        process_type: "invalid_type",
        configuration: @valid_configuration
      )
    end
  end

  test "accepts all valid process types" do
    ProcessingTask::VALID_PROCESS_TYPES.each do |process_type|
      task = ProcessingTask.new(
        processable: @assignment,
        process_type: process_type,
        configuration: @valid_configuration
      )
      assert_equal process_type, task.process_type
    end
  end

  test "configuration accessors delegate to configuration object" do
    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      configuration: @valid_configuration
    )

    assert_equal "MockPromptTemplate", task.prompt_template
    assert_equal "MockResponseParser", task.response_parser
    assert_equal "MockStorageService", task.storage_service
    assert_equal "MockBroadcaster", task.broadcaster
    assert_equal "MockStatusManager", task.status_manager
  end

  test "mark_started sets started_at timestamp" do
    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      configuration: @valid_configuration
    )

    assert_nil task.started_at

    task.mark_started

    assert_not_nil task.started_at
    assert_kind_of Time, task.started_at
  end

  test "mark_completed sets completed_at timestamp" do
    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      configuration: @valid_configuration
    )

    assert_nil task.completed_at

    task.mark_completed

    assert_not_nil task.completed_at
    assert_kind_of Time, task.completed_at
  end

  test "processing_time_ms returns 0 when not started" do
    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      configuration: @valid_configuration
    )

    assert_equal 0, task.processing_time_ms
  end

  test "processing_time_ms returns 0 when started but not completed" do
    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      configuration: @valid_configuration
    )

    task.mark_started

    assert_equal 0, task.processing_time_ms
  end

  test "processing_time_ms calculates duration in milliseconds" do
    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      configuration: @valid_configuration
    )

    # Set specific times for predictable calculation
    start_time = Time.current
    end_time = start_time + 2.5.seconds

    task.started_at = start_time
    task.completed_at = end_time

    assert_equal 2500, task.processing_time_ms
  end

  test "record_metric stores metric values" do
    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      configuration: @valid_configuration
    )

    task.record_metric(:token_count, 1500)
    task.record_metric("response_time", 2.5)

    assert_equal 1500, task.metrics[:token_count]
    assert_equal 1500, task.metrics["token_count"]
    assert_equal 2.5, task.metrics[:response_time]
    assert_equal 2.5, task.metrics["response_time"]
  end

  test "metrics are accessible with indifferent access" do
    task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      configuration: @valid_configuration
    )

    task.record_metric(:status, "completed")

    assert_equal "completed", task.metrics[:status]
    assert_equal "completed", task.metrics["status"]
  end
end
