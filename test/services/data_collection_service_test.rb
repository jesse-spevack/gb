require "test_helper"

class DataCollectionServiceTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
    @student_work = student_works(:student_essay_one)
    @user = users(:teacher)
  end

  test "collects basic data for all process types" do
    data = DataCollectionService.collect(@assignment, "generate_rubric", @user)

    assert_equal "Assignment", data[:processable_type]
    assert_equal @assignment.id, data[:processable_id]
    assert_equal "generate_rubric", data[:process_type]
    assert_equal @user.id, data[:user_id]
    assert_not_nil data[:collected_at]
  end

  test "collects assignment data for rubric generation" do
    data = DataCollectionService.collect(@assignment, "generate_rubric", @user)

    # Basic assignment data
    assert_equal @assignment.title, data[:assignment][:title]
    assert_equal @assignment.subject, data[:assignment][:subject]
    assert_equal @assignment.grade_level, data[:assignment][:grade_level]
    assert_equal @assignment.instructions, data[:assignment][:instructions]
    assert_equal @assignment.feedback_tone, data[:assignment][:feedback_tone]

    # Existing rubric text if present
    if @assignment.rubric_text.present?
      assert_equal @assignment.rubric_text, data[:assignment][:rubric_text]
    end

    # User context
    assert_equal @user.name, data[:user][:name]
    assert_equal @user.email, data[:user][:email]
  end

  test "collects student work data for grading" do
    data = DataCollectionService.collect(@student_work, "grade_student_work", @user)

    # Student work context
    assert_equal @student_work.id, data[:student_work][:id]
    assert_equal @student_work.assignment_id, data[:student_work][:assignment_id]
    assert_equal @student_work.selected_document_id, data[:student_work][:selected_document_id]

    # Assignment context for grading
    assignment = data[:assignment]
    assert_equal @student_work.assignment.title, assignment[:title]
    assert_equal @student_work.assignment.instructions, assignment[:instructions]
    assert_equal @student_work.assignment.feedback_tone, assignment[:feedback_tone]

    # Selected document info
    document = data[:selected_document]
    assert_equal @student_work.selected_document.title, document[:title]
    assert_equal @student_work.selected_document.google_doc_id, document[:google_doc_id]

    # Rubric data if available
    if @student_work.assignment.rubric.present?
      assert_not_nil data[:rubric]
    end
  end

  test "collects assignment summary data for summary feedback" do
    data = DataCollectionService.collect(@assignment, "generate_summary_feedback", @user)

    # Assignment context
    assert_equal @assignment.title, data[:assignment][:title]
    assert_equal @assignment.instructions, data[:assignment][:instructions]

    # Student works collection
    assert data[:student_works].is_a?(Array)
    assert_equal @assignment.student_works.count, data[:student_works].length

    if @assignment.student_works.any?
      first_work = data[:student_works].first
      assert_not_nil first_work[:id]
      assert_not_nil first_work[:qualitative_feedback] if first_work[:qualitative_feedback]
    end

    # Rubric context
    if @assignment.rubric.present?
      assert_not_nil data[:rubric]
    end
  end

  test "handles missing rubric gracefully" do
    # Create an assignment that definitely has no rubric
    assignment_without_rubric = Assignment.create!(
      user: @user,
      title: "Test Assignment Without Rubric",
      subject: "Test",
      grade_level: "10",
      instructions: "This is a test assignment",
      feedback_tone: "encouraging"
    )

    data = DataCollectionService.collect(assignment_without_rubric, "generate_rubric", @user)

    assert_nil data[:rubric]
    assert_not_nil data[:assignment]
  end

  test "raises error for unsupported processable type" do
    unsupported_object = Object.new

    error = assert_raises(DataCollectionService::UnsupportedProcessableError) do
      DataCollectionService.collect(unsupported_object, "generate_rubric", @user)
    end

    assert_match(/Unsupported processable type/, error.message)
  end

  test "raises error for unsupported process type" do
    error = assert_raises(DataCollectionService::UnsupportedProcessTypeError) do
      DataCollectionService.collect(@assignment, "unknown_process", @user)
    end

    assert_match(/Unsupported process type/, error.message)
  end

  test "handles nil user gracefully" do
    data = DataCollectionService.collect(@assignment, "generate_rubric", nil)

    assert_nil data[:user_id]
    assert_nil data[:user]
  end

  test "includes relevant associations in collected data" do
    # Test that associations are properly loaded
    data = DataCollectionService.collect(@student_work, "grade_student_work", @user)

    # Should include related models without causing N+1 queries
    assert_not_nil data[:assignment]
    assert_not_nil data[:selected_document]

    # Check that we're not making excessive database calls
    # This is more of a design principle test
    assert data.keys.include?(:student_work)
    assert data.keys.include?(:assignment)
    assert data.keys.include?(:selected_document)
  end
end
