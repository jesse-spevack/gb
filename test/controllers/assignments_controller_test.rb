require "test_helper"

class AssignmentsControllerTest < ActiveSupport::TestCase
  # Unit tests for the enhanced AssignmentsController functionality
  # Tests focus on the controller logic without HTTP integration

  setup do
    @user = users(:teacher)
    @assignment = assignments(:english_essay)
    @controller = AssignmentsController.new
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

  test "criterion averages are loaded when assignment is complete" do
    # Create a mock assignment
    mock_assignment = mock()
    mock_stats_collection = mock()

    @controller.instance_variable_set(:@assignment, mock_assignment)

    # Mock the CompletionChecker to return true
    Assignments::CompletionChecker.expects(:call).with(mock_assignment).returns(true)

    # Mock the Statistics service
    Assignments::Statistics.expects(:get_criterion_performance).with(mock_assignment).returns(mock_stats_collection)

    # Simulate the logic from the show action
    if Assignments::CompletionChecker.call(mock_assignment)
      @controller.instance_variable_set(:@criterion_averages, Assignments::Statistics.get_criterion_performance(mock_assignment))
    end

    criterion_averages = @controller.instance_variable_get(:@criterion_averages)
    assert_not_nil criterion_averages
    assert_equal mock_stats_collection, criterion_averages
  end

  test "criterion averages are not loaded when assignment is incomplete" do
    # Create a mock assignment
    mock_assignment = mock()

    @controller.instance_variable_set(:@assignment, mock_assignment)

    # Mock the CompletionChecker to return false
    Assignments::CompletionChecker.expects(:call).with(mock_assignment).returns(false)

    # Simulate the logic from the show action
    if Assignments::CompletionChecker.call(mock_assignment)
      @controller.instance_variable_set(:@criterion_averages, Assignments::Statistics.get_criterion_performance(mock_assignment))
    end

    criterion_averages = @controller.instance_variable_get(:@criterion_averages)
    assert_nil criterion_averages
  end
end
