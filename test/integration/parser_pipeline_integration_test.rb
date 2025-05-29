require "test_helper"

class ParserPipelineIntegrationTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:english_essay)
    @user = users(:teacher)
    @rubric = rubrics(:english_essay_rubric)
    @student_work = student_works(:student_essay_one)
  end

  test "rubric parser integrates with pipeline context" do
    # Create a context as it would be after the generator step
    context = Pipeline::Context::Rubric.new
    context.assignment = @assignment
    context.user = @user
    context.llm_response = LLMResponse.new(
      text: valid_rubric_json,
      model: "test-model",
      input_tokens: 100,
      output_tokens: 200
    )

    # Call the parser
    result = LLM::Rubric::ResponseParser.call(context: context)

    # Verify parsed response is available
    assert_not_nil result.parsed_response
    assert_equal 2, result.parsed_response.criteria.size
    assert_equal "Argument Quality", result.parsed_response.criteria[0].title
    assert_equal 4, result.parsed_response.criteria[0].levels.size

    # Verify context is preserved
    assert_same context, result
    assert_equal @assignment, result.assignment
    assert_equal @user, result.user
  end

  test "student work parser integrates with pipeline context" do
    # Create a context as it would be after the generator step
    context = Pipeline::Context::StudentWork.new
    context.student_work = @student_work
    context.rubric = @rubric
    context.user = @user
    context.assignment = @student_work.assignment
    context.llm_response = LLMResponse.new(
      text: valid_student_work_json,
      model: "test-model",
      input_tokens: 100,
      output_tokens: 200
    )

    # Call the parser
    result = LLM::StudentWork::ResponseParser.call(context: context)

    # Verify parsed response is available
    assert_not_nil result.parsed_response
    assert_equal "Good work overall", result.parsed_response.qualitative_feedback
    assert_equal 2, result.parsed_response.feedback_items.size
    assert_equal 2, result.parsed_response.criterion_levels.size
    assert_equal 2, result.parsed_response.checks.size

    # Verify context is preserved
    assert_same context, result
    assert_equal @student_work, result.student_work
    assert_equal @rubric, result.rubric
  end

  test "assignment summary parser integrates with pipeline context" do
    # Create a context as it would be after the generator step
    context = Pipeline::Context::AssignmentSummary.new
    context.assignment = @assignment
    context.user = @user
    context.student_feedbacks = []
    context.llm_response = LLMResponse.new(
      text: valid_assignment_summary_json,
      model: "test-model",
      input_tokens: 100,
      output_tokens: 200
    )

    # Call the parser
    result = LLM::AssignmentSummary::ResponseParser.call(context: context)

    # Verify parsed response is available
    assert_not_nil result.parsed_response
    assert_equal "Class performed well overall", result.parsed_response.qualitative_insights
    assert_equal 2, result.parsed_response.feedback_items.size

    # Verify context is preserved
    assert_same context, result
    assert_equal @assignment, result.assignment
    assert_equal @user, result.user
  end

  test "parser error handling works in pipeline context" do
    # Test with invalid JSON
    context = Pipeline::Context::Rubric.new
    context.assignment = @assignment
    context.user = @user
    context.llm_response = LLMResponse.new(
      text: "{ invalid json",
      model: "test-model",
      input_tokens: 100,
      output_tokens: 200
    )

    # Verify parser raises appropriate error
    assert_raises(JSON::ParserError) do
      LLM::Rubric::ResponseParser.call(context: context)
    end
  end

  test "parser validation errors work in pipeline context" do
    # Test with missing required fields
    context = Pipeline::Context::StudentWork.new
    context.student_work = @student_work
    context.llm_response = LLMResponse.new(
      text: { feedback_items: [] }.to_json,
      model: "test-model",
      input_tokens: 100,
      output_tokens: 200
    )

    # Verify parser raises validation error
    assert_raises(LLM::StudentWork::ResponseParser::ValidationError) do
      LLM::StudentWork::ResponseParser.call(context: context)
    end
  end

  test "parser preserves existing context metrics" do
    context = Pipeline::Context::AssignmentSummary.new
    context.assignment = @assignment
    context.user = @user
    context.add_metric("generator_ms", 150)
    context.add_metric("prompt_tokens", 500)

    context.llm_response = LLMResponse.new(
      text: valid_assignment_summary_json,
      model: "test-model",
      input_tokens: 100,
      output_tokens: 200
    )

    result = LLM::AssignmentSummary::ResponseParser.call(context: context)

    # Verify existing metrics are preserved
    assert_equal 150, result.metrics["generator_ms"]
    assert_equal 500, result.metrics["prompt_tokens"]

    # Verify parsed response is available
    assert_not_nil result.parsed_response
  end

  private

  def valid_rubric_json
    {
      criteria: [
        {
          title: "Argument Quality",
          description: "The strength and clarity of the main argument",
          position: 1,
          levels: [
            {
              name: "Exemplary",
              description: "Exceptional argument",
              position: 4
            },
            {
              name: "Proficient",
              description: "Strong argument",
              position: 3
            },
            {
              name: "Developing",
              description: "Basic argument",
              position: 2
            },
            {
              name: "Beginning",
              description: "Weak argument",
              position: 1
            }
          ]
        },
        {
          title: "Organization",
          description: "The structure and flow",
          position: 2,
          levels: [
            {
              name: "Exemplary",
              description: "Perfect organization",
              position: 4
            },
            {
              name: "Proficient",
              description: "Good organization",
              position: 3
            },
            {
              name: "Developing",
              description: "Basic organization",
              position: 2
            },
            {
              name: "Beginning",
              description: "Poor organization",
              position: 1
            }
          ]
        }
      ]
    }.to_json
  end

  def valid_student_work_json
    {
      qualitative_feedback: "Good work overall",
      feedback_items: [
        {
          item_type: "strength",
          title: "Clear writing",
          description: "Well organized",
          evidence: "Throughout the essay"
        },
        {
          item_type: "opportunity",
          title: "Citations",
          description: "Need improvement",
          evidence: "Missing page numbers"
        }
      ],
      criterion_levels: [
        {
          criterion_id: 1,
          level_id: 3,
          explanation: "Strong argument"
        },
        {
          criterion_id: 2,
          level_id: 2,
          explanation: "Basic organization"
        }
      ],
      checks: [
        {
          check_type: "plagiarism",
          score: 15,
          explanation: "Low plagiarism score"
        },
        {
          check_type: "llm_generated",
          score: 8,
          explanation: "Appears authentic"
        }
      ]
    }.to_json
  end

  def valid_assignment_summary_json
    {
      qualitative_insights: "Class performed well overall",
      feedback_items: [
        {
          item_type: "strength",
          title: "Understanding",
          description: "Most students grasp concepts",
          evidence: "80% scored above average"
        },
        {
          item_type: "opportunity",
          title: "Citations",
          description: "Common area for improvement",
          evidence: "60% had citation issues"
        }
      ]
    }.to_json
  end
end
