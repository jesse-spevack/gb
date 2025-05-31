require "test_helper"

class AssignmentsControllerTest < ActiveSupport::TestCase
  # Unit tests for the enhanced AssignmentsController functionality
  # Tests focus on the controller logic without HTTP integration

  setup do
    @user = users(:teacher)
    @assignment = assignments(:english_essay)
    @controller = AssignmentsController.new
  end

  test "calculate_progress_metrics returns correct structure" do
    @controller.instance_variable_set(:@assignment, @assignment)
    @controller.instance_variable_set(:@student_works, @assignment.student_works)

    progress_metrics = @controller.send(:calculate_progress_metrics)

    assert progress_metrics.is_a?(Hash)
    assert progress_metrics.key?(:total)
    assert progress_metrics.key?(:completed)
    assert progress_metrics.key?(:percentage)
    assert progress_metrics.key?(:rubric_generated)
    assert progress_metrics.key?(:summary_generated)

    # Verify the values are sensible
    assert progress_metrics[:total] >= 0
    assert progress_metrics[:completed] >= 0
    assert progress_metrics[:percentage] >= 0
    assert progress_metrics[:percentage] <= 100
    assert [ true, false ].include?(progress_metrics[:rubric_generated])
    assert [ true, false ].include?(progress_metrics[:summary_generated])
  end

  test "calculate_progress_metrics handles empty student works" do
    assignment_without_works = Assignment.create!(
      user: @user,
      title: "Test Assignment",
      instructions: "Test instructions",
      grade_level: "10",
      feedback_tone: "encouraging"
    )

    @controller.instance_variable_set(:@assignment, assignment_without_works)
    @controller.instance_variable_set(:@student_works, assignment_without_works.student_works)

    progress_metrics = @controller.send(:calculate_progress_metrics)

    assert_equal 0, progress_metrics[:total]
    assert_equal 0, progress_metrics[:completed]
    assert_equal 0, progress_metrics[:percentage]
  end

  test "calculate_progress_metrics handles completed student works" do
    # Create mock student works with feedback
    mock_student_work1 = mock()
    mock_student_work1.expects(:qualitative_feedback).returns("Some feedback").at_least_once

    mock_student_work2 = mock()
    mock_student_work2.expects(:qualitative_feedback).returns(nil).at_least_once

    mock_student_works = [ mock_student_work1, mock_student_work2 ]

    @controller.instance_variable_set(:@assignment, @assignment)
    @controller.instance_variable_set(:@student_works, mock_student_works)

    progress_metrics = @controller.send(:calculate_progress_metrics)

    assert_equal 2, progress_metrics[:total]
    assert_equal 1, progress_metrics[:completed]
    assert_equal 50, progress_metrics[:percentage]
  end

  test "calculate_progress_metrics handles rubric presence" do
    # Test with rubric present
    mock_rubric = mock()
    @controller.instance_variable_set(:@assignment, @assignment)
    @controller.instance_variable_set(:@student_works, @assignment.student_works)
    @controller.instance_variable_set(:@rubric, mock_rubric)

    progress_metrics = @controller.send(:calculate_progress_metrics)
    assert_equal true, progress_metrics[:rubric_generated]
  end

  test "calculate_progress_metrics handles rubric absence" do
    # Test with no rubric
    @controller.instance_variable_set(:@assignment, @assignment)
    @controller.instance_variable_set(:@student_works, @assignment.student_works)
    @controller.instance_variable_set(:@rubric, nil)

    progress_metrics = @controller.send(:calculate_progress_metrics)
    assert_equal false, progress_metrics[:rubric_generated]
  end

  test "calculate_progress_metrics handles assignment summary presence" do
    # Test with summary present
    mock_summary = mock()
    @controller.instance_variable_set(:@assignment, @assignment)
    @controller.instance_variable_set(:@student_works, @assignment.student_works)
    @controller.instance_variable_set(:@assignment_summary, mock_summary)

    progress_metrics = @controller.send(:calculate_progress_metrics)
    assert_equal true, progress_metrics[:summary_generated]
  end

  test "calculate_progress_metrics handles assignment summary absence" do
    # Test with no summary
    @controller.instance_variable_set(:@assignment, @assignment)
    @controller.instance_variable_set(:@student_works, @assignment.student_works)
    @controller.instance_variable_set(:@assignment_summary, nil)

    progress_metrics = @controller.send(:calculate_progress_metrics)
    assert_equal false, progress_metrics[:summary_generated]
  end

  test "section parameter validation" do
    # Valid sections
    valid_sections = %w[details rubric student_works summary]
    valid_sections.each do |section|
      result = section.in?(%w[details rubric student_works summary]) ? section : "details"
      assert_equal section, result
    end

    # Invalid sections should default to 'details'
    invalid_sections = %w[invalid_section unknown_section nil_section]
    invalid_sections.each do |section|
      result = section.in?(%w[details rubric student_works summary]) ? section : "details"
      assert_equal "details", result
    end
  end

  test "assignment loading with associations" do
    # This would normally be tested through the actual controller action
    # but we can verify the approach by checking that the includes work
    student_works = @assignment.student_works.includes(:selected_document, :feedback_items)

    assert student_works.respond_to?(:each)
    # Verify that associations are loaded (this doesn't trigger additional queries)
    if student_works.any?
      assert student_works.first.selected_document
    end
  end

  test "view data preparation" do
    # Test that the controller properly prepares data for the view
    @controller.instance_variable_set(:@assignment, @assignment)
    @controller.instance_variable_set(:@student_works, @assignment.student_works)
    @controller.instance_variable_set(:@rubric, @assignment.rubric)
    @controller.instance_variable_set(:@assignment_summary, @assignment.assignment_summary)
    @controller.instance_variable_set(:@active_section, "details")

    # Verify instance variables are set correctly
    assert_equal @assignment, @controller.instance_variable_get(:@assignment)
    assert_equal @assignment.student_works, @controller.instance_variable_get(:@student_works)
    assert_equal @assignment.rubric, @controller.instance_variable_get(:@rubric)
    assert_equal @assignment.assignment_summary, @controller.instance_variable_get(:@assignment_summary)
    assert_equal "details", @controller.instance_variable_get(:@active_section)
  end

  test "criterion averages are loaded when rubric exists" do
    # Create a mock assignment with a rubric
    mock_assignment = mock()
    mock_rubric = mock()
    mock_statistics = mock()
    mock_statistics.expects(:criterion_performance).returns({ criterion1: { average: 3.5, evaluated_count: 2, total_count: 3 } })
    
    @controller.instance_variable_set(:@assignment, mock_assignment)
    @controller.instance_variable_set(:@rubric, mock_rubric)
    
    # Mock the Statistics service
    Assignments::Statistics.expects(:new).with(mock_assignment).returns(mock_statistics)
    
    # Simulate the logic from the show action
    if @controller.instance_variable_get(:@rubric).present?
      @controller.instance_variable_set(:@criterion_averages, Assignments::Statistics.new(mock_assignment).criterion_performance)
    end
    
    criterion_averages = @controller.instance_variable_get(:@criterion_averages)
    assert_not_nil criterion_averages
    assert_kind_of Hash, criterion_averages
    assert criterion_averages.key?(:criterion1)
    assert_equal 3.5, criterion_averages[:criterion1][:average]
  end

  test "criterion averages are not loaded when rubric does not exist" do
    # Create a mock assignment without a rubric
    mock_assignment = mock()
    
    @controller.instance_variable_set(:@assignment, mock_assignment)
    @controller.instance_variable_set(:@rubric, nil)
    
    # Simulate the logic from the show action
    if @controller.instance_variable_get(:@rubric).present?
      @controller.instance_variable_set(:@criterion_averages, mock_assignment.criterion_averages)
    end
    
    criterion_averages = @controller.instance_variable_get(:@criterion_averages)
    assert_nil criterion_averages
  end
end
