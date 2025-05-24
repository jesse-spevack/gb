require "test_helper"

class ProcessingPipelineTest < ActiveSupport::TestCase
  # Mock classes for testing
  class MockPromptTemplate
    def self.build(template_type, variables)
      case variables
      when RubricPromptInput
        "Mock prompt for #{template_type} with RubricPromptInput"
      when StudentWorkPromptInput
        "Mock prompt for #{template_type} with StudentWorkPromptInput"
      when SummaryFeedbackPromptInput
        "Mock prompt for #{template_type} with SummaryFeedbackPromptInput"
      when Hash
        "Mock prompt for #{template_type} with #{variables.keys.join(', ')}"
      else
        "Mock prompt for #{template_type} with #{variables.class.name}"
      end
    end
  end

  class MockResponseParser
    def self.parse(response)
      { parsed_data: "Mock parsed result from #{response}" }
    end
  end

  class MockStorageService
    def self.store(processable, parsed_result)
      { stored: true, result: parsed_result }
    end
  end

  class MockBroadcaster
    def self.broadcast(processable, status, data = nil)
      { broadcast: status, data: data }
    end
  end

  class MockStatusManager
    def self.update_status(processable, status)
      { status_updated: status }
    end
  end

  def setup
    @assignment = assignments(:english_essay)
    @user = users(:teacher)

    @configuration = ProcessingTaskConfiguration.new(
      prompt_template: MockPromptTemplate,
      response_parser: MockResponseParser,
      storage_service: MockStorageService,
      broadcaster: MockBroadcaster,
      status_manager: MockStatusManager
    )

    @task = ProcessingTask.new(
      processable: @assignment,
      process_type: "generate_rubric",
      user: @user,
      configuration: @configuration
    )
  end

  test "initializes with a processing task" do
    pipeline = ProcessingPipeline.new(@task)

    assert_equal @task, pipeline.task
  end

  test "execute returns successful result when all steps complete" do
    pipeline = ProcessingPipeline.new(@task)

    result = pipeline.execute

    assert result.success?
    assert_not_nil result.data
    assert_nil result.error_message
  end

  test "execute marks task as started and completed" do
    pipeline = ProcessingPipeline.new(@task)

    assert_nil @task.started_at
    assert_nil @task.completed_at

    pipeline.execute

    assert_not_nil @task.started_at
    assert_not_nil @task.completed_at
  end

  test "execute records processing time metric" do
    pipeline = ProcessingPipeline.new(@task)

    pipeline.execute

    assert @task.metrics.key?(:processing_time_ms)
    assert @task.metrics[:processing_time_ms] >= 0
  end

  test "execute handles errors and returns failure result" do
    # Mock an error in the storage service
    MockStorageService.stubs(:store).raises(StandardError.new("Storage failed"))

    pipeline = ProcessingPipeline.new(@task)

    result = pipeline.execute

    assert result.failure?
    assert_equal "Storage failed", result.error_message
    assert_nil result.data
  end

  test "execute records error in task metrics on failure" do
    MockStorageService.stubs(:store).raises(StandardError.new("Storage failed"))

    pipeline = ProcessingPipeline.new(@task)

    pipeline.execute

    assert_equal "failed", @task.metrics[:status]
    assert_equal "Storage failed", @task.error_message
  end

  test "execute broadcasts status updates" do
    MockBroadcaster.expects(:broadcast).with(@assignment, :processing, nil).once
    MockBroadcaster.expects(:broadcast).with(@assignment, :completed, anything).once

    pipeline = ProcessingPipeline.new(@task)
    pipeline.execute
  end

  test "execute updates status through status manager" do
    MockStatusManager.expects(:update_status).with(@assignment, :processing).once
    MockStatusManager.expects(:update_status).with(@assignment, :completed).once

    pipeline = ProcessingPipeline.new(@task)
    pipeline.execute
  end

  test "execute follows the 5-step process" do
    pipeline = ProcessingPipeline.new(@task)

    # We'll verify this by checking the sequence of calls
    MockPromptTemplate.expects(:build).returns("test prompt").once
    MockResponseParser.expects(:parse).returns({ test: "data" }).once
    MockStorageService.expects(:store).returns({ stored: true }).once

    result = pipeline.execute

    assert result.success?
  end
end
