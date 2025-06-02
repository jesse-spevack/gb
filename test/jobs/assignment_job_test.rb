require "test_helper"

class AssignmentJobTest < ActiveJob::TestCase
  def setup
    @assignment = assignments(:english_essay)
  end

  test "creates AssignmentProcessor with correct assignment ID" do
    processor_mock = mock("assignment_processor")

    # Expect AssignmentProcessor to be instantiated with the assignment ID
    AssignmentProcessor.expects(:new).with(@assignment.id).returns(processor_mock)

    # Mock the process method to return a success result
    processor_mock.expects(:process).returns(
      Pipeline::ProcessingResult.new(success: true, data: {}, errors: [], metrics: {})
    )

    AssignmentJob.perform_now(@assignment.id)
  end

  test "calls process method on AssignmentProcessor" do
    processor_mock = mock("assignment_processor")
    mock_result = Pipeline::ProcessingResult.new(
      success: true,
      data: { rubric: "generated", student_feedbacks: [], assignment_summary: "complete" },
      errors: [],
      metrics: { "total_duration_ms" => 5000 }
    )

    AssignmentProcessor.stubs(:new).returns(processor_mock)

    # Expect process to be called and return a result
    processor_mock.expects(:process).returns(mock_result).once

    AssignmentJob.perform_now(@assignment.id)
  end

  test "handles successful processing" do
    processor_mock = mock("assignment_processor")
    success_result = Pipeline::ProcessingResult.new(
      success: true,
      data: {
        rubric: rubrics(:english_essay_rubric),
        student_feedbacks: [ student_works(:student_essay_one) ],
        assignment_summary: assignment_summaries(:literary_analysis_summary)
      },
      errors: [],
      metrics: { "total_duration_ms" => 8500, "total_tokens_used" => 2500 }
    )

    AssignmentProcessor.stubs(:new).returns(processor_mock)
    processor_mock.stubs(:process).returns(success_result)

    # Should complete without raising any errors
    assert_nothing_raised do
      AssignmentJob.perform_now(@assignment.id)
    end
  end

  test "handles processing failures gracefully" do
    processor_mock = mock("assignment_processor")
    failure_result = Pipeline::ProcessingResult.new(
      success: false,
      data: nil,
      errors: [ "RubricPipeline failed: LLM rate limit exceeded" ],
      metrics: { "total_duration_ms" => 1200 }
    )

    AssignmentProcessor.stubs(:new).returns(processor_mock)
    processor_mock.stubs(:process).returns(failure_result)

    # Should complete without raising an exception
    assert_nothing_raised do
      AssignmentJob.perform_now(@assignment.id)
    end
  end

  test "handles exceptions from AssignmentProcessor gracefully" do
    processor_mock = mock("assignment_processor")

    AssignmentProcessor.stubs(:new).returns(processor_mock)
    processor_mock.stubs(:process).raises(StandardError.new("Database connection lost"))

    exception = assert_raises(StandardError) do
      AssignmentJob.perform_now(@assignment.id)
    end

    assert_equal "Database connection lost", exception.message
    assert_instance_of StandardError, exception
  end

  test "processes successfully with valid result" do
    processor_mock = mock("assignment_processor")
    result = Pipeline::ProcessingResult.new(
      success: true,
      data: {},
      errors: [],
      metrics: { "total_duration_ms" => 3000 }
    )

    AssignmentProcessor.stubs(:new).returns(processor_mock)
    processor_mock.stubs(:process).returns(result)

    assert_nothing_raised do
      AssignmentJob.perform_now(@assignment.id)
    end
  end

  test "handles invalid assignment ID with proper error" do
    invalid_id = "invalid-assignment-id"

    exception = assert_raises(Hashids::InputError) do
      AssignmentJob.perform_now(invalid_id)
    end

    assert_not_nil exception
    assert_instance_of Hashids::InputError, exception
  end

  test "handles non-existent assignment ID" do
    nonexistent_id = "asgn_999999"

    exception = assert_raises(ActiveRecord::RecordNotFound) do
      AssignmentJob.perform_now(nonexistent_id)
    end

    assert_not_nil exception
    assert_instance_of ActiveRecord::RecordNotFound, exception
  end

  test "passes assignment ID as string to AssignmentProcessor" do
    string_id = @assignment.id.to_s

    # Expect AssignmentProcessor to be called with the string ID
    AssignmentProcessor.expects(:new).with(string_id).returns(
      mock("processor", process: Pipeline::ProcessingResult.new(success: true))
    )

    AssignmentJob.perform_now(string_id)
  end

  test "measures job execution time" do
    processor_mock = mock("assignment_processor")

    # Simulate a longer processing time
    processor_mock.stubs(:process).returns(
      Pipeline::ProcessingResult.new(success: true, metrics: { "total_duration_ms" => 4500 })
    )

    AssignmentProcessor.stubs(:new).returns(processor_mock)

    start_time = Time.current
    AssignmentJob.perform_now(@assignment.id)
    end_time = Time.current

    # Job should complete reasonably quickly (within test timeout)
    assert (end_time - start_time) < 1.0, "Job took too long to execute"
  end

  test "integrates with existing job queue infrastructure" do
    # Test that the job can be enqueued and performed
    assert_enqueued_jobs 1 do
      AssignmentJob.perform_later(@assignment.id)
    end

    # Mock the processor for the actual execution
    processor_mock = mock("assignment_processor")
    processor_mock.stubs(:process).returns(
      Pipeline::ProcessingResult.new(success: true)
    )
    AssignmentProcessor.stubs(:new).returns(processor_mock)

    # Perform the enqueued job
    assert_nothing_raised do
      perform_enqueued_jobs
    end
  end
end
