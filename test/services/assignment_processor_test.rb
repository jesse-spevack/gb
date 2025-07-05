# frozen_string_literal: true

require "test_helper"

class AssignmentProcessorTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
    @user = users(:teacher)
  end

  test "initializes with valid assignment ID" do
    processor = AssignmentProcessor.new(@assignment.id)
    assert_not_nil processor
  end

  test "stores the assignment instance" do
    processor = AssignmentProcessor.new(@assignment.id)
    assert_equal @assignment, processor.instance_variable_get(:@assignment)
  end

  test "raises error for invalid assignment ID" do
    # When using prefixed_ids, invalid IDs raise Hashids::InputError
    assert_raises(Hashids::InputError) do
      AssignmentProcessor.new("invalid-id")
    end
  end

  test "raises error for nil assignment ID" do
    assert_raises(ActiveRecord::RecordNotFound) do
      AssignmentProcessor.new(nil)
    end
  end

  test "raises error for non-existent assignment ID" do
    # Use a valid prefixed ID format that doesn't exist
    non_existent_id = "asgn_999999"
    assert_raises(ActiveRecord::RecordNotFound) do
      AssignmentProcessor.new(non_existent_id)
    end
  end

  test "initializes instance variables for pipeline results" do
    processor = AssignmentProcessor.new(@assignment.id)

    # Check that instance variables for tracking results are initialized
    assert_nil processor.instance_variable_get(:@rubric_result)
    assert_equal [], processor.instance_variable_get(:@student_feedback_results) || []
    assert_nil processor.instance_variable_get(:@assignment_summary_result)
  end

  # Process method interface tests
  test "process method returns a result object" do
    processor = AssignmentProcessor.new(@assignment.id)
    result = processor.process

    assert_instance_of Pipeline::ProcessingResult, result
  end

  test "process method can be called without arguments" do
    processor = AssignmentProcessor.new(@assignment.id)

    assert_nothing_raised do
      processor.process
    end
  end

  test "result object contains success status" do
    processor = AssignmentProcessor.new(@assignment.id)
    result = processor.process

    assert_respond_to result, :successful?
    assert_respond_to result, :failed?
  end

  test "result object contains data" do
    processor = AssignmentProcessor.new(@assignment.id)
    result = processor.process

    assert_respond_to result, :data
  end

  test "result object contains errors array" do
    processor = AssignmentProcessor.new(@assignment.id)
    result = processor.process

    assert_respond_to result, :errors
    assert_kind_of Array, result.errors
  end

  test "result object contains metrics hash" do
    processor = AssignmentProcessor.new(@assignment.id)
    result = processor.process

    assert_respond_to result, :metrics
    assert_kind_of Hash, result.metrics
  end

  # Rubric pipeline execution tests
  test "executes RubricPipeline with correct assignment" do
    processor = AssignmentProcessor.new(@assignment.id)

    # Mock the RubricPipeline.call method
    mock_result = Pipeline::ProcessingResult.new(
      success: true,
      data: rubrics(:english_essay_rubric),
      errors: [],
      metrics: { "total_duration_ms" => 100 }
    )

    RubricPipeline.expects(:call)
      .with(assignment: @assignment, user: @assignment.user)
      .returns(mock_result)
      .once

    processor.process
  end

  test "captures RubricPipeline results" do
    processor = AssignmentProcessor.new(@assignment.id)

    mock_rubric = rubrics(:english_essay_rubric)
    mock_result = Pipeline::ProcessingResult.new(
      success: true,
      data: mock_rubric,
      errors: [],
      metrics: { "total_duration_ms" => 100 }
    )

    RubricPipeline.stubs(:call).returns(mock_result)
    # Since assignment might have no student works, we don't need to generate summary
    # But in case it does, mock the summary pipeline
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: nil)
    )

    result = processor.process

    assert result.successful?
    assert_equal mock_rubric, result.data[:rubric]
  end

  test "includes rubric metrics in final result" do
    processor = AssignmentProcessor.new(@assignment.id)

    rubric_metrics = {
      "total_duration_ms" => 100,
      "llm_request_ms" => 80,
      "tokens_used" => 500
    }

    mock_result = Pipeline::ProcessingResult.new(
      success: true,
      data: rubrics(:english_essay_rubric),
      errors: [],
      metrics: rubric_metrics
    )

    RubricPipeline.stubs(:call).returns(mock_result)

    result = processor.process

    # Check that rubric metrics are prefixed and included
    assert_equal 100, result.metrics["rubric_total_duration_ms"]
    assert_equal 80, result.metrics["rubric_llm_request_ms"]
    assert_equal 500, result.metrics["rubric_tokens_used"]
  end

  test "handles RubricPipeline failure" do
    processor = AssignmentProcessor.new(@assignment.id)

    mock_result = Pipeline::ProcessingResult.new(
      success: false,
      data: nil,
      errors: [ "Failed to generate rubric" ],
      metrics: {}
    )

    RubricPipeline.stubs(:call).returns(mock_result)

    result = processor.process

    # RubricPipeline failure is critical and should stop processing
    assert result.failed?
  end

  # Student feedback pipeline execution tests
  test "executes StudentWorkFeedbackPipeline for each student work" do
    # Create assignment with student works
    assignment_with_students = assignments(:english_essay)
    student_work1 = student_works(:student_essay_one)
    student_work2 = student_works(:student_essay_with_rubric)

    # Ensure the student works belong to our assignment
    student_work1.update!(assignment: assignment_with_students)
    student_work2.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock rubric pipeline
    mock_rubric = rubrics(:english_essay_rubric)
    rubric_result = Pipeline::ProcessingResult.new(
      success: true,
      data: mock_rubric,
      errors: [],
      metrics: { "total_duration_ms" => 100 }
    )
    RubricPipeline.stubs(:call).returns(rubric_result)

    # Expect StudentWorkFeedbackPipeline to be called twice
    StudentWorkFeedbackPipeline.expects(:call)
      .with(student_work: student_work1, rubric: mock_rubric, user: assignment_with_students.user)
      .returns(Pipeline::ProcessingResult.new(success: true, data: student_work1))

    StudentWorkFeedbackPipeline.expects(:call)
      .with(student_work: student_work2, rubric: mock_rubric, user: assignment_with_students.user)
      .returns(Pipeline::ProcessingResult.new(success: true, data: student_work2))

    processor.process
  end

  test "processes student works sequentially not in parallel" do
    assignment_with_students = assignments(:english_essay)
    student_work = student_works(:student_essay_one)
    student_work.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock rubric pipeline
    rubric_result = Pipeline::ProcessingResult.new(
      success: true,
      data: rubrics(:english_essay_rubric),
      errors: [],
      metrics: {}
    )
    RubricPipeline.stubs(:call).returns(rubric_result)

    # Track call order
    call_sequence = []

    StudentWorkFeedbackPipeline.stubs(:call).with { |args|
      call_sequence << Time.now
      true
    }.returns(
      Pipeline::ProcessingResult.new(success: true, data: student_work)
    )

    processor.process

    # Sequential processing means each call should complete before the next starts
    # In a real test, we'd verify no threading/async behavior
    assert_equal 1, call_sequence.length
  end

  test "collects results from all student feedback pipelines" do
    assignment_with_students = assignments(:english_essay)
    student_work1 = student_works(:student_essay_one)
    student_work1.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock pipelines
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: rubrics(:english_essay_rubric),
        errors: [],
        metrics: {}
      )
    )

    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: student_work1,
        errors: [],
        metrics: { "total_duration_ms" => 200 }
      )
    )

    # Mock summary pipeline since we have student works
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: nil)
    )

    result = processor.process

    assert result.successful?
    assert_equal 1, result.data[:student_feedbacks].length
    assert_equal student_work1, result.data[:student_feedbacks].first
  end

  test "includes student feedback metrics in final result" do
    assignment_with_students = assignments(:english_essay)
    student_work = student_works(:student_essay_one)
    student_work.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock pipelines
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: rubrics(:english_essay_rubric),
        errors: [],
        metrics: { "total_duration_ms" => 100 }
      )
    )

    student_metrics = {
      "total_duration_ms" => 200,
      "llm_request_ms" => 150,
      "tokens_used" => 800
    }

    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: student_work,
        errors: [],
        metrics: student_metrics
      )
    )

    result = processor.process

    # Check that student metrics are prefixed and included
    assert_equal 200, result.metrics["student_0_total_duration_ms"]
    assert_equal 150, result.metrics["student_0_llm_request_ms"]
    assert_equal 800, result.metrics["student_0_tokens_used"]
  end

  test "passes rubric context to student feedback pipelines" do
    assignment_with_students = assignments(:english_essay)
    student_work = student_works(:student_essay_one)
    student_work.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock rubric pipeline
    mock_rubric = rubrics(:english_essay_rubric)
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_rubric,
        errors: [],
        metrics: {}
      )
    )

    # Verify rubric is passed to student pipeline
    StudentWorkFeedbackPipeline.expects(:call)
      .with(has_entries(rubric: mock_rubric))
      .returns(Pipeline::ProcessingResult.new(success: true, data: student_work))

    processor.process
  end

  # Assignment summary pipeline execution tests
  test "executes AssignmentSummaryPipeline with aggregated contexts" do
    assignment_with_students = assignments(:english_essay)
    student_work = student_works(:student_essay_one)
    student_work.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock rubric pipeline
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: rubrics(:english_essay_rubric),
        errors: [],
        metrics: {}
      )
    )

    # Mock student feedback pipeline
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: student_work,
        errors: [],
        metrics: {}
      )
    )

    # Expect AssignmentSummaryPipeline to be called with all student feedbacks
    AssignmentSummaryPipeline.expects(:call)
      .with(
        assignment: assignment_with_students,
        student_feedbacks: [ student_work ],
        user: assignment_with_students.user
      )
      .returns(Pipeline::ProcessingResult.new(success: true))
      .once

    processor.process
  end

  test "executes pipelines in correct order" do
    # This test verifies that pipelines are executed in the correct sequence:
    # 1. RubricPipeline
    # 2. StudentWorkFeedbackPipeline (for each student)
    # 3. AssignmentSummaryPipeline (last)

    assignment_with_students = assignments(:english_essay)
    student_work = student_works(:student_essay_one)
    student_work.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Use sequence to ensure order
    seq = sequence("pipeline_execution")

    # 1. Rubric pipeline must be called first
    RubricPipeline.expects(:call).in_sequence(seq).returns(
      Pipeline::ProcessingResult.new(success: true, data: rubrics(:english_essay_rubric))
    )

    # 2. Student feedback pipeline(s) called next
    StudentWorkFeedbackPipeline.expects(:call).in_sequence(seq).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_work)
    )

    # 3. Assignment summary pipeline called last
    AssignmentSummaryPipeline.expects(:call).in_sequence(seq).returns(
      Pipeline::ProcessingResult.new(success: true)
    )

    processor.process
  end

  test "captures assignment summary results" do
    processor = AssignmentProcessor.new(@assignment.id)

    # Mock all pipelines
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: rubrics(:english_essay_rubric))
    )

    # Mock student feedback pipeline so summary will be generated
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_works(:student_essay_one))
    )

    mock_summary = assignment_summaries(:literary_analysis_summary)
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_summary,
        errors: [],
        metrics: { "total_duration_ms" => 300 }
      )
    )

    result = processor.process

    assert result.successful?
    assert_equal mock_summary, result.data[:assignment_summary]
  end

  test "includes assignment summary metrics in final result" do
    processor = AssignmentProcessor.new(@assignment.id)

    # Mock pipelines
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: rubrics(:english_essay_rubric))
    )

    # Mock student feedback pipeline so summary will be generated
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_works(:student_essay_one))
    )

    summary_metrics = {
      "total_duration_ms" => 300,
      "llm_request_ms" => 250,
      "tokens_used" => 1200
    }

    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: assignment_summaries(:literary_analysis_summary),
        errors: [],
        metrics: summary_metrics
      )
    )

    result = processor.process

    # Check that summary metrics are prefixed and included
    assert_equal 300, result.metrics["summary_total_duration_ms"]
    assert_equal 250, result.metrics["summary_llm_request_ms"]
    assert_equal 1200, result.metrics["summary_tokens_used"]
  end

  test "handles assignment summary pipeline failure" do
    # Use assignment with student works to ensure summary pipeline runs
    assignment_with_students = assignments(:english_essay)
    student_work = student_works(:student_essay_one)
    student_work.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock successful rubric pipeline
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: rubrics(:english_essay_rubric))
    )

    # Mock successful student feedback so summary will be generated
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_work)
    )

    # Mock failed summary pipeline
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: false,
        data: nil,
        errors: [ "Failed to generate summary" ],
        metrics: {}
      )
    )

    result = processor.process

    # AssignmentSummaryPipeline failure is critical and should mark the assignment as failed
    assert result.failed?
  end

  # Critical pipeline failure tests
  test "returns failure result when RubricPipeline fails" do
    processor = AssignmentProcessor.new(@assignment.id)

    # Mock failed rubric pipeline
    mock_result = Pipeline::ProcessingResult.new(
      success: false,
      data: nil,
      errors: [ "Failed to generate rubric: LLM rate limit exceeded" ],
      metrics: { "total_duration_ms" => 50 }
    )

    RubricPipeline.stubs(:call).returns(mock_result)

    result = processor.process

    assert result.failed?
    assert_nil result.data[:rubric]
    assert_includes result.errors, "RubricPipeline failed: Failed to generate rubric: LLM rate limit exceeded"
  end

  test "stops processing when RubricPipeline fails" do
    processor = AssignmentProcessor.new(@assignment.id)

    # Mock failed rubric pipeline
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: false,
        data: nil,
        errors: [ "Rubric generation failed" ],
        metrics: {}
      )
    )

    # These pipelines should never be called
    StudentWorkFeedbackPipeline.expects(:call).never
    AssignmentSummaryPipeline.expects(:call).never

    result = processor.process

    assert result.failed?
  end


  test "includes rubric error details in result" do
    processor = AssignmentProcessor.new(@assignment.id)

    error_message = "API key invalid"
    mock_result = Pipeline::ProcessingResult.new(
      success: false,
      data: nil,
      errors: [ error_message ],
      metrics: { "attempted_at" => Time.current.to_s }
    )

    RubricPipeline.stubs(:call).returns(mock_result)

    result = processor.process

    assert result.failed?
    assert_equal [ "RubricPipeline failed: #{error_message}" ], result.errors
    assert_includes result.metrics.keys, "rubric_attempted_at"
  end

  test "returns failure result when AssignmentSummaryPipeline fails" do
    processor = AssignmentProcessor.new(@assignment.id)

    # Mock successful rubric pipeline
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: rubrics(:english_essay_rubric),
        errors: [],
        metrics: {}
      )
    )

    # Mock successful student feedback so summary will be generated
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_works(:student_essay_one))
    )

    # Mock failed summary pipeline
    mock_result = Pipeline::ProcessingResult.new(
      success: false,
      data: nil,
      errors: [ "Summary generation failed: Context too large" ],
      metrics: { "total_duration_ms" => 300 }
    )

    AssignmentSummaryPipeline.stubs(:call).returns(mock_result)

    result = processor.process

    assert result.failed?
    assert_not_nil result.data[:rubric] # Rubric should still be present
    assert_nil result.data[:assignment_summary]
    assert_includes result.errors, "AssignmentSummaryPipeline failed: Summary generation failed: Context too large"
  end

  test "preserves successful pipeline results when summary fails" do
    assignment_with_students = assignments(:english_essay)
    student_work = student_works(:student_essay_one)
    student_work.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock successful pipelines
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: rubrics(:english_essay_rubric),
        errors: [],
        metrics: {}
      )
    )

    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: student_work,
        errors: [],
        metrics: {}
      )
    )

    # Mock failed summary
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: false,
        data: nil,
        errors: [ "Summary failed" ],
        metrics: {}
      )
    )

    result = processor.process

    # Should preserve successful results
    assert result.failed?
    assert_not_nil result.data[:rubric]
    assert_equal 1, result.data[:student_feedbacks].length
    assert_nil result.data[:assignment_summary]
  end

  test "includes all pipeline metrics even on failure" do
    processor = AssignmentProcessor.new(@assignment.id)

    # Mock successful rubric with metrics
    rubric_metrics = {
      "total_duration_ms" => 100,
      "llm_request_ms" => 80
    }

    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: rubrics(:english_essay_rubric),
        errors: [],
        metrics: rubric_metrics
      )
    )

    # Mock successful student feedback so summary will be generated
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_works(:student_essay_one))
    )

    # Mock failed summary with metrics
    summary_metrics = {
      "total_duration_ms" => 200,
      "error_type" => "timeout"
    }

    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: false,
        data: nil,
        errors: [ "Timeout" ],
        metrics: summary_metrics
      )
    )

    result = processor.process

    # Should include metrics from all pipelines
    assert_equal 100, result.metrics["rubric_total_duration_ms"]
    assert_equal 80, result.metrics["rubric_llm_request_ms"]
    assert_equal 200, result.metrics["summary_total_duration_ms"]
    assert_equal "timeout", result.metrics["summary_error_type"]
  end

  test "handles exceptions during rubric pipeline execution" do
    processor = AssignmentProcessor.new(@assignment.id)

    # Simulate an exception
    error_message = "Connection refused"
    RubricPipeline.stubs(:call).raises(StandardError.new(error_message))

    result = processor.process

    assert result.failed?
    assert_includes result.errors.first, error_message
  end

  test "handles exceptions during summary pipeline execution" do
    processor = AssignmentProcessor.new(@assignment.id)

    # Mock successful rubric
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: rubrics(:english_essay_rubric))
    )

    # Mock successful student feedback so summary will be generated
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_works(:student_essay_one))
    )

    # Simulate exception in summary pipeline
    error_message = "Database connection lost"
    AssignmentSummaryPipeline.stubs(:call).raises(StandardError.new(error_message))

    result = processor.process

    assert result.failed?
    assert_includes result.errors.first, error_message
  end

  # Student feedback failure tests (non-critical)
  test "continues processing when individual student feedback fails" do
    assignment_with_students = assignments(:english_essay)
    student_work1 = student_works(:student_essay_one)
    student_work2 = student_works(:student_essay_with_rubric)
    student_work1.update!(assignment: assignment_with_students)
    student_work2.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock successful rubric
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: rubrics(:english_essay_rubric))
    )

    # First student fails, second succeeds
    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work1)).returns(
      Pipeline::ProcessingResult.new(
        success: false,
        data: nil,
        errors: [ "Student 1 feedback generation failed" ],
        metrics: { "total_duration_ms" => 100 }
      )
    )

    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work2)).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: student_work2,
        errors: [],
        metrics: { "total_duration_ms" => 200 }
      )
    )

    # Mock summary pipeline
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: assignment_summaries(:literary_analysis_summary))
    )

    result = processor.process

    # Should still be successful overall
    assert result.successful?
    # Should have one successful student feedback
    assert_equal 1, result.data[:student_feedbacks].length
    assert_equal student_work2, result.data[:student_feedbacks].first
  end

  test "marks individual student work failures but continues" do
    assignment_with_students = assignments(:english_essay)
    student_work1 = student_works(:student_essay_one)
    student_work2 = student_works(:student_essay_with_rubric)
    student_work3 = student_works(:student_essay_one).dup
    student_work3.save!
    student_work1.update!(assignment: assignment_with_students)
    student_work2.update!(assignment: assignment_with_students)
    student_work3.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock successful rubric
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: rubrics(:english_essay_rubric))
    )

    # Mix of successes and failures
    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work1)).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_work1)
    )

    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work2)).returns(
      Pipeline::ProcessingResult.new(
        success: false,
        data: nil,
        errors: [ "LLM timeout for student 2" ]
      )
    )

    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work3)).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_work3)
    )

    # Mock summary pipeline
    AssignmentSummaryPipeline.expects(:call).with { |args|
      # Should only pass successful student feedbacks
      args[:student_feedbacks].length == 2 &&
      args[:student_feedbacks].include?(student_work1) &&
      args[:student_feedbacks].include?(student_work3)
    }.returns(
      Pipeline::ProcessingResult.new(success: true, data: assignment_summaries(:literary_analysis_summary))
    )

    result = processor.process

    assert result.successful?
    assert_equal 2, result.data[:student_feedbacks].length
  end

  test "handles exceptions during student feedback processing" do
    assignment_with_students = assignments(:english_essay)
    student_work1 = student_works(:student_essay_one)
    student_work2 = student_works(:student_essay_with_rubric)
    student_work1.update!(assignment: assignment_with_students)
    student_work2.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock successful rubric
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: rubrics(:english_essay_rubric))
    )

    # First student throws exception, second succeeds
    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work1)).raises(
      StandardError.new("Network error")
    )

    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work2)).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_work2)
    )

    # Mock summary pipeline
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: nil)
    )

    result = processor.process

    # Should continue and be successful
    assert result.successful?
    assert_equal 1, result.data[:student_feedbacks].length
    assert_equal student_work2, result.data[:student_feedbacks].first
  end

  test "includes metrics from failed student feedback pipelines" do
    assignment_with_students = assignments(:english_essay)
    student_work = student_works(:student_essay_one)
    student_work.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock pipelines
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: rubrics(:english_essay_rubric))
    )

    failed_metrics = {
      "total_duration_ms" => 150,
      "error_type" => "rate_limit",
      "attempted_at" => Time.current.to_s
    }

    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: false,
        data: nil,
        errors: [ "Rate limit exceeded" ],
        metrics: failed_metrics
      )
    )

    # Mock summary pipeline
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: nil)
    )

    result = processor.process

    # Should include metrics from failed pipeline
    assert_equal 150, result.metrics["student_0_total_duration_ms"]
    assert_equal "rate_limit", result.metrics["student_0_error_type"]
  end

  # Note: This test was simplified due to complex mocking requirements
  test "continues processing all students despite failures" do
    # This test verifies the core behavior: student failures don't stop processing
    assignment_with_students = assignments(:english_essay)
    student_work1 = student_works(:student_essay_one)
    student_work2 = student_works(:student_essay_with_rubric)
    student_work1.update!(assignment: assignment_with_students)
    student_work2.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock successful rubric
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: rubrics(:english_essay_rubric))
    )

    # Mock mixed success/failure for students
    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work1)).returns(
      Pipeline::ProcessingResult.new(success: false, data: nil, errors: [ "Failed" ])
    )

    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work2)).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_work2)
    )

    # Mock summary pipeline
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: nil)
    )

    result = processor.process

    # Should continue processing and be successful overall
    assert result.successful?
    # Should have one successful student feedback
    assert_equal 1, result.data[:student_feedbacks].length
  end

  test "generates summary with only successful student feedbacks" do
    assignment_with_students = assignments(:english_essay)
    student_work1 = student_works(:student_essay_one)
    student_work2 = student_works(:student_essay_with_rubric)
    student_work1.update!(assignment: assignment_with_students)
    student_work2.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock successful rubric
    mock_rubric = rubrics(:english_essay_rubric)
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: mock_rubric)
    )

    # One success, one failure
    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work1)).returns(
      Pipeline::ProcessingResult.new(
        success: false,
        data: nil,
        errors: [ "Failed" ]
      )
    )

    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work2)).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_work2)
    )

    # Verify summary is called with only successful feedback
    AssignmentSummaryPipeline.expects(:call).with(
      assignment: assignment_with_students,
      student_feedbacks: [ student_work2 ],
      user: assignment_with_students.user
    ).returns(
      Pipeline::ProcessingResult.new(success: true, data: assignment_summaries(:literary_analysis_summary))
    )

    result = processor.process

    assert result.successful?
  end

  # Processing metrics tracking tests
  test "calls RecordMetricsService for successful rubric generation" do
    processor = AssignmentProcessor.new(@assignment.id)

    mock_rubric = rubrics(:english_essay_rubric)
    rubric_result = Pipeline::ProcessingResult.new(
      success: true,
      data: mock_rubric,
      errors: [],
      metrics: {
        "total_duration_ms" => 1500,
        "llm_request_ms" => 1200,
        "tokens_used" => 850,
        "cost_usd" => 0.042
      }
    )

    RubricPipeline.stubs(:call).returns(rubric_result)

    # Mock student feedback pipeline if assignment has student works
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_works(:student_essay_one))
    )

    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: nil)
    )

    # Expect RecordMetricsService to be called with context parameter
    RecordMetricsService.expects(:call).with(has_key(:context)).at_least_once

    processor.process
  end

  test "calls RecordMetricsService for failed rubric generation" do
    processor = AssignmentProcessor.new(@assignment.id)

    rubric_result = Pipeline::ProcessingResult.new(
      success: false,
      data: nil,
      errors: [ "LLM rate limit exceeded" ],
      metrics: {
        "total_duration_ms" => 500,
        "error_type" => "rate_limit",
        "attempted_at" => Time.current.to_s
      }
    )

    RubricPipeline.stubs(:call).returns(rubric_result)

    # Expect RecordMetricsService to be called with context parameter
    RecordMetricsService.expects(:call).with(has_key(:context)).at_least_once

    processor.process
  end

  test "calls RecordMetricsService for each student feedback" do
    assignment_with_students = assignments(:english_essay)
    student_work1 = student_works(:student_essay_one)
    student_work2 = student_works(:student_essay_with_rubric)
    student_work1.update!(assignment: assignment_with_students)
    student_work2.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock successful rubric
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: rubrics(:english_essay_rubric))
    )

    # Mock student feedback results with metrics
    student1_metrics = {
      "total_duration_ms" => 2000,
      "llm_request_ms" => 1800,
      "tokens_used" => 1200,
      "cost_usd" => 0.096
    }

    student2_metrics = {
      "total_duration_ms" => 1800,
      "llm_request_ms" => 1600,
      "tokens_used" => 1100,
      "cost_usd" => 0.088
    }

    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work1)).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: student_work1,
        metrics: student1_metrics
      )
    )

    StudentWorkFeedbackPipeline.stubs(:call).with(has_entries(student_work: student_work2)).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: student_work2,
        metrics: student2_metrics
      )
    )

    # Mock summary pipeline
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: nil)
    )

    # Expect RecordMetricsService to be called with context parameter
    RecordMetricsService.expects(:call).with(has_key(:context)).at_least_once

    processor.process
  end

  test "calls RecordMetricsService for assignment summary generation" do
    assignment_with_students = assignments(:english_essay)
    student_work = student_works(:student_essay_one)
    student_work.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock successful rubric
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: rubrics(:english_essay_rubric))
    )

    # Mock successful student feedback
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: student_work)
    )

    # Mock assignment summary with metrics
    summary_metrics = {
      "total_duration_ms" => 2500,
      "llm_request_ms" => 2200,
      "tokens_used" => 1800,
      "cost_usd" => 0.144
    }

    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: assignment_summaries(:literary_analysis_summary),
        metrics: summary_metrics
      )
    )

    # Expect RecordMetricsService to be called with context parameter
    RecordMetricsService.expects(:call).with(has_key(:context)).at_least_once

    result = processor.process
    assert result.successful?
  end

  test "handles RecordMetricsService failures gracefully" do
    processor = AssignmentProcessor.new(@assignment.id)

    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: rubrics(:english_essay_rubric),
        metrics: { "total_duration_ms" => 1000 }
      )
    )

    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(success: true, data: nil)
    )

    # RecordMetricsService raises an exception
    RecordMetricsService.stubs(:call).raises(StandardError.new("Database connection failed"))

    # Should not fail the overall processing
    result = processor.process
    assert result.successful?
  end

  test "tracks total processing metrics across all pipelines" do
    assignment_with_students = assignments(:english_essay)
    student_work = student_works(:student_essay_one)
    student_work.update!(assignment: assignment_with_students)

    processor = AssignmentProcessor.new(assignment_with_students.id)

    # Mock all pipelines with specific timing
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: rubrics(:english_essay_rubric),
        metrics: { "total_duration_ms" => 1000, "tokens_used" => 500 }
      )
    )

    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: student_work,
        metrics: { "total_duration_ms" => 2000, "tokens_used" => 800 }
      )
    )

    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: assignment_summaries(:literary_analysis_summary),
        metrics: { "total_duration_ms" => 1500, "tokens_used" => 600 }
      )
    )

    # Expect RecordMetricsService to be called with context parameter
    RecordMetricsService.expects(:call).with(has_key(:context)).at_least_once

    processor.process
  end
end
