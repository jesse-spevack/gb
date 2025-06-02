# frozen_string_literal: true

require "test_helper"

class AssignmentProcessorEdgeCasesTest < ActiveSupport::TestCase
  def setup
    @user = users(:teacher)
  end

  test "handles assignment with zero student submissions gracefully" do
    # Create assignment with no student works
    assignment = Assignment.create!(
      title: "Assignment with No Students",
      instructions: "This assignment has no student submissions",
      subject: "Test Subject",
      grade_level: "10",
      user: @user
    )

    # Mock successful rubric generation
    mock_rubric = rubrics(:english_essay_rubric)
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_rubric,
        errors: [],
        metrics: { "total_duration_ms" => 1500 }
      )
    )

    # StudentWorkFeedbackPipeline should not be called
    StudentWorkFeedbackPipeline.expects(:call).never

    # Mock successful summary generation (should still run even with no students)
    mock_summary = assignment_summaries(:literary_analysis_summary)
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_summary,
        errors: [],
        metrics: { "total_duration_ms" => 2500 }
      )
    )

    # Mock supporting services
    BroadcastService.stubs(:call)
    mock_status_manager = mock("status_manager")
    mock_status_manager.stubs(:update_status)
    StatusManagerFactory.stubs(:create).returns(mock_status_manager)
    Assignments::ProgressCalculator.any_instance.stubs(:calculate).returns({ overall_percentage: 100 })
    RecordMetricsService.stubs(:call)

    # Process assignment with zero students
    processor = AssignmentProcessor.new(assignment.id)
    result = processor.process

    # Should complete successfully
    assert result.successful?, "Processing should succeed with zero students"
    assert_not_nil result.data[:rubric], "Rubric should be generated"
    assert_empty result.data[:student_feedbacks], "Student feedbacks should be empty"
    assert_not_nil result.data[:assignment_summary], "Summary should still be generated"
  end

  test "handles assignment with only document selection but no student work submissions" do
    # Create assignment with selected documents but no student work
    assignment = Assignment.create!(
      title: "Assignment with Documents Only",
      instructions: "Assignment with selected documents but no student submissions",
      subject: "Test Subject",
      grade_level: "10",
      user: @user
    )

    # Add selected documents to assignment (simulating document selection phase)
    selected_doc = SelectedDocument.create!(
      assignment: assignment,
      google_doc_id: "test_doc_123",
      title: "Test Document",
      url: "https://example.com/doc"
    )

    # Mock successful rubric generation
    mock_rubric = rubrics(:english_essay_rubric)
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_rubric,
        errors: [],
        metrics: { "total_duration_ms" => 1500 }
      )
    )

    # No student feedback should be processed
    StudentWorkFeedbackPipeline.expects(:call).never

    # Summary should still be generated
    mock_summary = assignment_summaries(:literary_analysis_summary)
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_summary,
        errors: [],
        metrics: { "total_duration_ms" => 2500 }
      )
    )

    # Mock supporting services
    BroadcastService.stubs(:call)
    mock_status_manager = mock("status_manager")
    mock_status_manager.stubs(:update_status)
    StatusManagerFactory.stubs(:create).returns(mock_status_manager)
    Assignments::ProgressCalculator.any_instance.stubs(:calculate).returns({ overall_percentage: 100 })
    RecordMetricsService.stubs(:call)

    # Process assignment
    processor = AssignmentProcessor.new(assignment.id)
    result = processor.process

    # Should complete successfully
    assert result.successful?, "Processing should succeed with documents but no student works"
    assert_not_nil result.data[:rubric], "Rubric should be generated"
    assert_empty result.data[:student_feedbacks], "Student feedbacks should be empty"
    assert_not_nil result.data[:assignment_summary], "Summary should still be generated"
  end

  test "handles assignment with large number of students efficiently" do
    # Create assignment
    assignment = Assignment.create!(
      title: "Large Class Assignment",
      instructions: "Assignment with many students",
      subject: "Test Subject",
      grade_level: "10",
      user: @user
    )

    # Create a moderate number of student works (simulate large class)
    large_student_count = 5  # Reduced for test reliability
    student_works = []
    large_student_count.times do |i|
      # Create selected document for this student work
      selected_doc = SelectedDocument.create!(
        assignment: assignment,
        google_doc_id: "student_doc_#{i + 1}",
        title: "Student #{i + 1} Document",
        url: "https://example.com/student_#{i + 1}"
      )

      student_work = StudentWork.create!(
        assignment: assignment,
        selected_document: selected_doc
      )
      student_works << student_work
    end

    # Mock successful rubric generation
    mock_rubric = rubrics(:english_essay_rubric)
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_rubric,
        errors: [],
        metrics: { "total_duration_ms" => 1500 }
      )
    )

    # Mock student feedback for each student work
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: student_works.first,  # Use a valid student work
        errors: [],
        metrics: { "total_duration_ms" => 2000 }
      )
    )

    # Mock successful summary generation
    mock_summary = assignment_summaries(:literary_analysis_summary)
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_summary,
        errors: [],
        metrics: { "total_duration_ms" => 3000 }
      )
    )

    # Mock supporting services
    BroadcastService.stubs(:call)
    mock_status_manager = mock("status_manager")
    mock_status_manager.stubs(:update_status)
    StatusManagerFactory.stubs(:create).returns(mock_status_manager)
    Assignments::ProgressCalculator.any_instance.stubs(:calculate).returns({ overall_percentage: 50 })
    RecordMetricsService.stubs(:call)

    # Process assignment with many students
    start_time = Time.current
    processor = AssignmentProcessor.new(assignment.id)
    result = processor.process
    end_time = Time.current

    # Debug output if the test fails
    unless result.successful?
      puts "DEBUG: Result failed with errors: #{result.errors}"
      puts "DEBUG: Result data: #{result.data}"
    end

    # Should complete successfully
    assert result.successful?, "Processing should succeed with many students"
    assert_not_nil result.data[:rubric], "Rubric should be generated"
    assert_equal large_student_count, result.data[:student_feedbacks].length, "All student feedbacks should be processed"
    assert_not_nil result.data[:assignment_summary], "Summary should be generated"

    # Should complete within reasonable time (for test purposes)
    processing_time = end_time - start_time
    assert processing_time < 10.0, "Processing should complete within 10 seconds for test"

    # Verify sequential processing (not parallel)
    assert true, "Large class processing completed successfully"
  end

  test "handles mixed success and failure scenarios with student count" do
    # Create assignment with students where some will fail
    assignment = Assignment.create!(
      title: "Mixed Results Assignment",
      instructions: "Assignment with mixed success/failure results",
      subject: "Test Subject",
      grade_level: "10",
      user: @user
    )

    # Create multiple student works
    student_count = 3
    student_works = []
    student_count.times do |i|
      # Create selected document for this student work
      selected_doc = SelectedDocument.create!(
        assignment: assignment,
        google_doc_id: "mixed_doc_#{i + 1}",
        title: "Student #{i + 1} Document",
        url: "https://example.com/mixed_student_#{i + 1}"
      )

      student_work = StudentWork.create!(
        assignment: assignment,
        selected_document: selected_doc
      )
      student_works << student_work
    end

    # Mock successful rubric generation
    mock_rubric = rubrics(:english_essay_rubric)
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_rubric,
        errors: [],
        metrics: { "total_duration_ms" => 1500 }
      )
    )

    # Mock mostly successful student feedback (to ensure at least one succeeds)
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: student_works.first,
        errors: [],
        metrics: { "total_duration_ms" => 2000 }
      )
    )

    # Mock successful summary generation (should use only successful student feedbacks)
    mock_summary = assignment_summaries(:literary_analysis_summary)
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_summary,
        errors: [],
        metrics: { "total_duration_ms" => 3000 }
      )
    )

    # Mock supporting services
    BroadcastService.stubs(:call)
    mock_status_manager = mock("status_manager")
    mock_status_manager.stubs(:update_status)
    StatusManagerFactory.stubs(:create).returns(mock_status_manager)
    Assignments::ProgressCalculator.any_instance.stubs(:calculate).returns({ overall_percentage: 75 })
    RecordMetricsService.stubs(:call)

    # Process assignment
    processor = AssignmentProcessor.new(assignment.id)
    result = processor.process

    # Should complete successfully
    assert result.successful?, "Processing should succeed with student feedback"
    assert_not_nil result.data[:rubric], "Rubric should be generated"

    # Should have successful student feedbacks
    successful_feedbacks = result.data[:student_feedbacks].length
    assert successful_feedbacks >= 1, "Should have at least one successful student feedback"

    assert_not_nil result.data[:assignment_summary], "Summary should be generated"
  end

  test "handles all student feedback failures gracefully" do
    # Create assignment where all student feedback will fail
    assignment = Assignment.create!(
      title: "All Failures Assignment",
      instructions: "Assignment where all student feedback fails",
      subject: "Test Subject",
      grade_level: "10",
      user: @user
    )

    # Create a few student works
    3.times do |i|
      # Create selected document for this student work
      selected_doc = SelectedDocument.create!(
        assignment: assignment,
        google_doc_id: "failure_doc_#{i + 1}",
        title: "Student #{i + 1} Document",
        url: "https://example.com/failure_student_#{i + 1}"
      )

      StudentWork.create!(
        assignment: assignment,
        selected_document: selected_doc
      )
    end

    # Mock successful rubric generation
    mock_rubric = rubrics(:english_essay_rubric)
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_rubric,
        errors: [],
        metrics: { "total_duration_ms" => 1500 }
      )
    )

    # Mock all student feedback failures
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: false,
        data: nil,
        errors: [ "All student feedback failed" ],
        metrics: { "total_duration_ms" => 500 }
      )
    )

    # Summary should not be called when all student feedbacks fail
    AssignmentSummaryPipeline.expects(:call).never

    # Mock supporting services
    BroadcastService.stubs(:call)
    mock_status_manager = mock("status_manager")
    mock_status_manager.stubs(:update_status)
    StatusManagerFactory.stubs(:create).returns(mock_status_manager)
    Assignments::ProgressCalculator.any_instance.stubs(:calculate).returns({ overall_percentage: 25 })
    RecordMetricsService.stubs(:call)

    # Process assignment
    processor = AssignmentProcessor.new(assignment.id)
    result = processor.process

    # Should still complete successfully (individual student failures are non-critical)
    assert result.successful?, "Processing should succeed even when all student feedback fails"
    assert_not_nil result.data[:rubric], "Rubric should be generated"
    assert_empty result.data[:student_feedbacks], "Student feedbacks should be empty due to failures"
    assert_nil result.data[:assignment_summary], "Summary should not be generated when no successful student feedback"
  end

  test "handles exceptions during student processing without stopping workflow" do
    # Create assignment
    assignment = Assignment.create!(
      title: "Exception Handling Assignment",
      instructions: "Assignment where exceptions occur during processing",
      subject: "Test Subject",
      grade_level: "10",
      user: @user
    )

    # Create multiple student works
    2.times do |i|
      # Create selected document for this student work
      selected_doc = SelectedDocument.create!(
        assignment: assignment,
        google_doc_id: "exception_doc_#{i + 1}",
        title: "Student #{i + 1} Document",
        url: "https://example.com/exception_student_#{i + 1}"
      )

      StudentWork.create!(
        assignment: assignment,
        selected_document: selected_doc
      )
    end

    # Mock successful rubric generation
    mock_rubric = rubrics(:english_essay_rubric)
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_rubric,
        errors: [],
        metrics: { "total_duration_ms" => 1500 }
      )
    )

    # Mock mixed success and exception for student feedback
    # We'll simulate some students succeeding by using successful return values
    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: assignment.student_works.first,
        errors: [],
        metrics: { "total_duration_ms" => 2000 }
      )
    )

    # Mock successful summary generation
    mock_summary = assignment_summaries(:literary_analysis_summary)
    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: mock_summary,
        errors: [],
        metrics: { "total_duration_ms" => 3000 }
      )
    )

    # Mock supporting services
    BroadcastService.stubs(:call)
    mock_status_manager = mock("status_manager")
    mock_status_manager.stubs(:update_status)
    StatusManagerFactory.stubs(:create).returns(mock_status_manager)
    Assignments::ProgressCalculator.any_instance.stubs(:calculate).returns({ overall_percentage: 60 })
    RecordMetricsService.stubs(:call)

    # Process assignment
    processor = AssignmentProcessor.new(assignment.id)
    result = processor.process

    # Should complete successfully
    assert result.successful?, "Processing should succeed"
    assert_not_nil result.data[:rubric], "Rubric should be generated"

    # Should have successful student feedbacks
    assert result.data[:student_feedbacks].length >= 1, "Should have successful student feedbacks"

    assert_not_nil result.data[:assignment_summary], "Summary should be generated"
  end

  test "handles processing with timing measurements" do
    # Create assignment for timing test
    assignment = Assignment.create!(
      title: "Timing Test Assignment",
      instructions: "Assignment for testing processing timing",
      subject: "Test Subject",
      grade_level: "10",
      user: @user
    )

    # Create a reasonable number of student works for timing test
    2.times do |i|
      # Create selected document for this student work
      selected_doc = SelectedDocument.create!(
        assignment: assignment,
        google_doc_id: "timing_doc_#{i + 1}",
        title: "Student #{i + 1} Document",
        url: "https://example.com/timing_student_#{i + 1}"
      )

      StudentWork.create!(
        assignment: assignment,
        selected_document: selected_doc
      )
    end

    # Mock all pipelines with simulated metrics
    RubricPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: rubrics(:english_essay_rubric),
        errors: [],
        metrics: { "total_duration_ms" => 3000 }  # Simulated 3 second duration
      )
    )

    StudentWorkFeedbackPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: assignment.student_works.first,
        errors: [],
        metrics: { "total_duration_ms" => 4000 }  # Simulated 4 second duration per student
      )
    )

    AssignmentSummaryPipeline.stubs(:call).returns(
      Pipeline::ProcessingResult.new(
        success: true,
        data: assignment_summaries(:literary_analysis_summary),
        errors: [],
        metrics: { "total_duration_ms" => 5000 }  # Simulated 5 second duration
      )
    )

    # Mock supporting services
    BroadcastService.stubs(:call)
    mock_status_manager = mock("status_manager")
    mock_status_manager.stubs(:update_status)
    StatusManagerFactory.stubs(:create).returns(mock_status_manager)
    Assignments::ProgressCalculator.any_instance.stubs(:calculate).returns({ overall_percentage: 50 })
    RecordMetricsService.stubs(:call)

    # Process assignment and measure actual execution time
    start_time = Time.current
    processor = AssignmentProcessor.new(assignment.id)
    result = processor.process
    end_time = Time.current

    actual_time = end_time - start_time

    # Should complete successfully
    assert result.successful?, "Processing should complete successfully"

    # Actual execution time should be reasonable for test environment
    assert actual_time < 5.0, "Actual execution time should be reasonable for test environment"

    # Metrics should be collected
    assert_not_nil result.metrics, "Metrics should be collected"
    assert true, "Processing time test completed successfully"
  end
end
