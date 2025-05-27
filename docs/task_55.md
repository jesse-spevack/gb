# Task 55: LLM Generator Classes Implementation Plan

## Overview
This implementation plan breaks down Task 55 into discrete, testable subtasks that can be executed independently by an AI coding partner. Each subtask follows TDD principles: write the test first, implement the code to make it pass, then refactor while keeping tests green.

**Goal**: Implement specialized generator classes for different processing types that integrate with the existing LLM client architecture, including retry logic via LLM::RetryHandler and automatic cost tracking via LLM::CostTracker.

---

## Task Checklist

### Core Implementation
- [ ] **Subtask 1**: Implement LLM::Rubric::Generator
- [ ] **Subtask 2**: Implement LLM::StudentWork::Generator  
- [ ] **Subtask 3**: Implement LLM::AssignmentSummary::Generator

### Integration Testing
- [ ] **Subtask 4**: Integration Testing with Pipelines

---

## Subtask 1: Implement LLM::Rubric::Generator

### Prompt for Subtask 1

Implement LLM::Rubric::Generator that integrates with the existing LLM client architecture to generate rubrics for GradeBot assignments.

**Context:**
- GradeBot uses LLM::ClientFactory.for_rubric_generation which returns GoogleClient
- The generator must integrate with LLM::RetryHandler for retry logic
- Cost tracking happens automatically via LLM::CostTracker
- The generator works within the Pipeline::Context::Rubric system
- JSON parsing errors should trigger one retry with instructions to fix JSON
- Default temperature settings should be used

**Requirements:**
- Use `context.record_timing(:llm_request)` to measure LLM call duration
- Track costs with LLM::CostTracker.record after successful generation
- Add metrics to context: tokens_used and cost_micro_usd
- Handle JSON parsing errors with one retry attempt
- Return the context unchanged for pipeline chaining

**Test First (TDD):**

Create `test/services/llm/rubric/generator_test.rb`:

```ruby
require "test_helper"

module LLM
  module Rubric
    class GeneratorTest < ActiveSupport::TestCase
      def setup
        @assignment = assignments(:physics_assignment)
        @user = users(:teacher_user)
        @context = Pipeline::Context::Rubric.new
        @context.assignment = @assignment
        @context.user = @user
        @context.prompt = "Generate a rubric for physics assignment"
      end

      test "generates rubric using Google client" do
        mock_response = OpenStruct.new(
          content: valid_rubric_json,
          model: "gemini-pro",
          total_tokens: 500,
          input_tokens: 100,
          output_tokens: 400
        )

        LLM::GoogleClient.expects(:generate).with(@context.prompt).returns(mock_response)
        LLM::CostTracker.expects(:record).with(
          llm_response: mock_response,
          trackable: @assignment,
          user: @user,
          request_type: :generate_rubric
        )

        result = Generator.call(context: @context)

        assert_equal @context, result
        assert_equal mock_response, result.llm_response
        assert_equal 500, result.metrics[:tokens_used]
        assert result.metrics[:cost_micro_usd] > 0
        assert result.metrics[:llm_request_ms] > 0
      end

      test "records timing metrics" do
        mock_response = OpenStruct.new(
          content: valid_rubric_json,
          model: "gemini-pro",
          total_tokens: 500
        )

        LLM::GoogleClient.stubs(:generate).returns(mock_response)
        LLM::CostTracker.stubs(:record)

        result = Generator.call(context: @context)

        assert result.metrics[:llm_request_ms].is_a?(Integer)
        assert result.metrics[:llm_request_ms] > 0
      end

      test "retries once on JSON parse error" do
        invalid_json_response = OpenStruct.new(
          content: "This is not valid JSON",
          model: "gemini-pro",
          total_tokens: 100
        )

        valid_json_response = OpenStruct.new(
          content: valid_rubric_json,
          model: "gemini-pro",
          total_tokens: 500
        )

        # First call returns invalid JSON, second returns valid
        LLM::GoogleClient.expects(:generate)
          .with(@context.prompt)
          .returns(invalid_json_response)

        LLM::GoogleClient.expects(:generate)
          .with(@context.prompt + "\n\nPlease ensure the response is valid JSON.")
          .returns(valid_json_response)

        LLM::CostTracker.expects(:record).once

        result = Generator.call(context: @context)

        assert_equal valid_json_response, result.llm_response
      end

      test "fails after second JSON parse error" do
        invalid_response = OpenStruct.new(
          content: "Still not valid JSON",
          model: "gemini-pro",
          total_tokens: 100
        )

        LLM::GoogleClient.stubs(:generate).returns(invalid_response)

        assert_raises(JSON::ParserError) do
          Generator.call(context: @context)
        end
      end

      test "calculates cost using CostCalculator" do
        mock_response = OpenStruct.new(
          content: valid_rubric_json,
          model: "gemini-pro",
          total_tokens: 1000
        )

        LLM::GoogleClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.expects(:get_cost).with(mock_response).returns(1500) # $0.015
        LLM::CostTracker.stubs(:record)

        result = Generator.call(context: @context)

        assert_equal 1500, result.metrics[:cost_micro_usd]
      end

      test "uses factory to get correct client" do
        LLM::ClientFactory.expects(:for_rubric_generation).returns(LLM::GoogleClient)

        mock_response = OpenStruct.new(
          content: valid_rubric_json,
          model: "gemini-pro",
          total_tokens: 500
        )

        LLM::GoogleClient.stubs(:generate).returns(mock_response)
        LLM::CostTracker.stubs(:record)

        Generator.call(context: @context)
      end

      test "handles LLM request errors" do
        LLM::GoogleClient.stubs(:generate).raises(LLM::RateLimitError, "Rate limit exceeded")

        assert_raises(LLM::RateLimitError) do
          Generator.call(context: @context)
        end
      end

      private

      def valid_rubric_json
        {
          criteria: [
            {
              title: "Understanding",
              description: "Demonstrates understanding of key concepts",
              levels: [
                { title: "Excellent", description: "Shows deep understanding" },
                { title: "Good", description: "Shows solid understanding" },
                { title: "Developing", description: "Shows basic understanding" }
              ]
            }
          ]
        }.to_json
      end
    end
  end
end
```

**Implementation:**

Update `app/services/llm/rubric/generator.rb`:

```ruby
# frozen_string_literal: true

module LLM
  module Rubric
    class Generator
      def self.call(context:)
        new(context).call
      end

      def initialize(context)
        @context = context
        @client = LLM::ClientFactory.for_rubric_generation
      end

      def call
        response = @context.record_timing(:llm_request) do
          make_llm_request(@context.prompt)
        end

        track_cost(response)
        update_context(response)

        @context
      end

      private

      def make_llm_request(prompt)
        response = @client.generate(prompt)
        validate_json_response(response)
        response
      rescue JSON::ParserError => e
        # One retry with instruction to fix JSON
        Rails.logger.warn "Invalid JSON response for rubric generation, retrying: #{e.message}"
        response = @client.generate(prompt + "\n\nPlease ensure the response is valid JSON.")
        validate_json_response(response)
        response
      end

      def validate_json_response(response)
        JSON.parse(response.content)
      end

      def track_cost(response)
        cost_micro_usd = LLM::CostCalculator.get_cost(response)
        
        LLM::CostTracker.record(
          llm_response: response,
          trackable: @context.assignment,
          user: @context.user,
          request_type: :generate_rubric
        )
        
        @context.add_metric(:cost_micro_usd, cost_micro_usd)
      end

      def update_context(response)
        @context.llm_response = response
        @context.add_metric(:tokens_used, response.total_tokens)
      end
    end
  end
end
```

**Refactor:**
After tests pass, consider:
- Adding more specific error handling for different JSON parsing issues
- Implementing circuit breaker pattern for repeated failures
- Adding request/response logging for debugging

---

## Subtask 2: Implement LLM::StudentWork::Generator

### Prompt for Subtask 2

Implement LLM::StudentWork::Generator that integrates with the existing LLM client architecture to generate feedback for student work in GradeBot.

**Context:**
- GradeBot uses LLM::ClientFactory.for_student_work_feedback which returns AnthropicClient
- The generator must integrate with LLM::RetryHandler for retry logic
- Cost tracking happens automatically via LLM::CostTracker
- The generator works within the Pipeline::Context::StudentWork system
- JSON parsing errors should trigger one retry with instructions to fix JSON
- Default temperature settings should be used

**Requirements:**
- Use `context.record_timing(:llm_request)` to measure LLM call duration
- Track costs with LLM::CostTracker.record after successful generation
- Add metrics to context: tokens_used and cost_micro_usd
- Handle JSON parsing errors with one retry attempt
- Return the context unchanged for pipeline chaining

**Test First (TDD):**

Create `test/services/llm/student_work/generator_test.rb`:

```ruby
require "test_helper"

module LLM
  module StudentWork
    class GeneratorTest < ActiveSupport::TestCase
      def setup
        @student_work = student_works(:physics_work_one)
        @rubric = rubrics(:physics_rubric)
        @user = users(:teacher_user)
        
        @context = Pipeline::Context::StudentWork.new
        @context.student_work = @student_work
        @context.rubric = @rubric
        @context.user = @user
        @context.assignment = @student_work.assignment
        @context.prompt = "Analyze this student work against the rubric"
      end

      test "generates feedback using Anthropic client" do
        mock_response = OpenStruct.new(
          content: valid_feedback_json,
          model: "claude-3-haiku-20240307",
          total_tokens: 800,
          input_tokens: 300,
          output_tokens: 500
        )

        LLM::AnthropicClient.expects(:generate).with(@context.prompt).returns(mock_response)
        LLM::CostTracker.expects(:record).with(
          llm_response: mock_response,
          trackable: @student_work,
          user: @user,
          request_type: :generate_student_work_feedback
        )

        result = Generator.call(context: @context)

        assert_equal @context, result
        assert_equal mock_response, result.llm_response
        assert_equal 800, result.metrics[:tokens_used]
        assert result.metrics[:cost_micro_usd] > 0
        assert result.metrics[:llm_request_ms] > 0
      end

      test "records timing metrics" do
        mock_response = OpenStruct.new(
          content: valid_feedback_json,
          model: "claude-3-haiku-20240307",
          total_tokens: 800
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostTracker.stubs(:record)

        result = Generator.call(context: @context)

        assert result.metrics[:llm_request_ms].is_a?(Integer)
        assert result.metrics[:llm_request_ms] > 0
      end

      test "retries once on JSON parse error" do
        invalid_json_response = OpenStruct.new(
          content: "This is not valid JSON feedback",
          model: "claude-3-haiku-20240307",
          total_tokens: 100
        )

        valid_json_response = OpenStruct.new(
          content: valid_feedback_json,
          model: "claude-3-haiku-20240307",
          total_tokens: 800
        )

        # First call returns invalid JSON, second returns valid
        LLM::AnthropicClient.expects(:generate)
          .with(@context.prompt)
          .returns(invalid_json_response)

        LLM::AnthropicClient.expects(:generate)
          .with(@context.prompt + "\n\nPlease ensure the response is valid JSON.")
          .returns(valid_json_response)

        LLM::CostTracker.expects(:record).once

        result = Generator.call(context: @context)

        assert_equal valid_json_response, result.llm_response
      end

      test "fails after second JSON parse error" do
        invalid_response = OpenStruct.new(
          content: "Still not valid JSON",
          model: "claude-3-haiku-20240307",
          total_tokens: 100
        )

        LLM::AnthropicClient.stubs(:generate).returns(invalid_response)

        assert_raises(JSON::ParserError) do
          Generator.call(context: @context)
        end
      end

      test "calculates cost using CostCalculator" do
        mock_response = OpenStruct.new(
          content: valid_feedback_json,
          model: "claude-3-haiku-20240307",
          total_tokens: 1000
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.expects(:get_cost).with(mock_response).returns(250) # $0.0025
        LLM::CostTracker.stubs(:record)

        result = Generator.call(context: @context)

        assert_equal 250, result.metrics[:cost_micro_usd]
      end

      test "uses factory to get correct client" do
        LLM::ClientFactory.expects(:for_student_work_feedback).returns(LLM::AnthropicClient)

        mock_response = OpenStruct.new(
          content: valid_feedback_json,
          model: "claude-3-haiku-20240307",
          total_tokens: 800
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostTracker.stubs(:record)

        Generator.call(context: @context)
      end

      test "handles LLM request errors" do
        LLM::AnthropicClient.stubs(:generate).raises(LLM::ServiceUnavailableError, "Service temporarily unavailable")

        assert_raises(LLM::ServiceUnavailableError) do
          Generator.call(context: @context)
        end
      end

      test "tracks correct request type for cost tracking" do
        mock_response = OpenStruct.new(
          content: valid_feedback_json,
          model: "claude-3-haiku-20240307",
          total_tokens: 800
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        
        LLM::CostTracker.expects(:record).with(
          llm_response: mock_response,
          trackable: @student_work,
          user: @user,
          request_type: :generate_student_work_feedback
        )

        Generator.call(context: @context)
      end

      private

      def valid_feedback_json
        {
          qualitative_feedback: "The student demonstrates a good understanding of the physics concepts. The explanations are clear and well-structured.",
          feedback_items: [
            {
              type: "strength",
              title: "Clear explanations",
              description: "Student explains concepts using appropriate terminology",
              evidence: "See paragraph 2 where forces are described"
            },
            {
              type: "opportunity",
              title: "Show calculations",
              description: "Include step-by-step calculations for problems",
              evidence: "Problem 3 lacks detailed work"
            }
          ],
          criterion_assessments: [
            {
              criterion_id: "physics_understanding",
              level: "good",
              explanation: "Demonstrates solid grasp of core concepts"
            }
          ]
        }.to_json
      end
    end
  end
end
```

**Implementation:**

Update `app/services/llm/student_work/generator.rb`:

```ruby
# frozen_string_literal: true

module LLM
  module StudentWork
    class Generator
      def self.call(context:)
        new(context).call
      end

      def initialize(context)
        @context = context
        @client = LLM::ClientFactory.for_student_work_feedback
      end

      def call
        response = @context.record_timing(:llm_request) do
          make_llm_request(@context.prompt)
        end

        track_cost(response)
        update_context(response)

        @context
      end

      private

      def make_llm_request(prompt)
        response = @client.generate(prompt)
        validate_json_response(response)
        response
      rescue JSON::ParserError => e
        # One retry with instruction to fix JSON
        Rails.logger.warn "Invalid JSON response for student work feedback, retrying: #{e.message}"
        response = @client.generate(prompt + "\n\nPlease ensure the response is valid JSON.")
        validate_json_response(response)
        response
      end

      def validate_json_response(response)
        JSON.parse(response.content)
      end

      def track_cost(response)
        cost_micro_usd = LLM::CostCalculator.get_cost(response)
        
        LLM::CostTracker.record(
          llm_response: response,
          trackable: @context.student_work,
          user: @context.user,
          request_type: :generate_student_work_feedback
        )
        
        @context.add_metric(:cost_micro_usd, cost_micro_usd)
      end

      def update_context(response)
        @context.llm_response = response
        @context.add_metric(:tokens_used, response.total_tokens)
      end
    end
  end
end
```

**Refactor:**
After tests pass, consider:
- Adding context-aware retry messages based on the specific JSON error
- Implementing response validation beyond JSON parsing
- Adding performance metrics for response quality

---

## Subtask 3: Implement LLM::AssignmentSummary::Generator

### Prompt for Subtask 3

Implement LLM::AssignmentSummary::Generator that integrates with the existing LLM client architecture to generate assignment-wide summaries for GradeBot.

**Context:**
- GradeBot uses LLM::ClientFactory.for_assignment_summary_feedback which returns AnthropicClient
- The generator must integrate with LLM::RetryHandler for retry logic
- Cost tracking happens automatically via LLM::CostTracker
- The generator works within the Pipeline::Context::AssignmentSummary system
- JSON parsing errors should trigger one retry with instructions to fix JSON
- Default temperature settings should be used

**Requirements:**
- Use `context.record_timing(:llm_request)` to measure LLM call duration
- Track costs with LLM::CostTracker.record after successful generation
- Add metrics to context: tokens_used and cost_micro_usd
- Handle JSON parsing errors with one retry attempt
- Return the context unchanged for pipeline chaining

**Test First (TDD):**

Create `test/services/llm/assignment_summary/generator_test.rb`:

```ruby
require "test_helper"

module LLM
  module AssignmentSummary
    class GeneratorTest < ActiveSupport::TestCase
      def setup
        @assignment = assignments(:physics_assignment)
        @user = users(:teacher_user)
        @student_feedbacks = [
          { student_work: student_works(:physics_work_one), feedback: "Good work" },
          { student_work: student_works(:physics_work_two), feedback: "Excellent analysis" }
        ]
        
        @context = Pipeline::Context::AssignmentSummary.new
        @context.assignment = @assignment
        @context.student_feedbacks = @student_feedbacks
        @context.user = @user
        @context.prompt = "Generate a summary of student performance"
      end

      test "generates summary using Anthropic client" do
        mock_response = OpenStruct.new(
          content: valid_summary_json,
          model: "claude-3-haiku-20240307",
          total_tokens: 1200,
          input_tokens: 700,
          output_tokens: 500
        )

        LLM::AnthropicClient.expects(:generate).with(@context.prompt).returns(mock_response)
        LLM::CostTracker.expects(:record).with(
          llm_response: mock_response,
          trackable: @assignment,
          user: @user,
          request_type: :generate_assignment_summary
        )

        result = Generator.call(context: @context)

        assert_equal @context, result
        assert_equal mock_response, result.llm_response
        assert_equal 1200, result.metrics[:tokens_used]
        assert result.metrics[:cost_micro_usd] > 0
        assert result.metrics[:llm_request_ms] > 0
      end

      test "records timing metrics" do
        mock_response = OpenStruct.new(
          content: valid_summary_json,
          model: "claude-3-haiku-20240307",
          total_tokens: 1200
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostTracker.stubs(:record)

        result = Generator.call(context: @context)

        assert result.metrics[:llm_request_ms].is_a?(Integer)
        assert result.metrics[:llm_request_ms] > 0
      end

      test "retries once on JSON parse error" do
        invalid_json_response = OpenStruct.new(
          content: "This is not valid JSON summary",
          model: "claude-3-haiku-20240307",
          total_tokens: 100
        )

        valid_json_response = OpenStruct.new(
          content: valid_summary_json,
          model: "claude-3-haiku-20240307",
          total_tokens: 1200
        )

        # First call returns invalid JSON, second returns valid
        LLM::AnthropicClient.expects(:generate)
          .with(@context.prompt)
          .returns(invalid_json_response)

        LLM::AnthropicClient.expects(:generate)
          .with(@context.prompt + "\n\nPlease ensure the response is valid JSON.")
          .returns(valid_json_response)

        LLM::CostTracker.expects(:record).once

        result = Generator.call(context: @context)

        assert_equal valid_json_response, result.llm_response
      end

      test "fails after second JSON parse error" do
        invalid_response = OpenStruct.new(
          content: "Still not valid JSON",
          model: "claude-3-haiku-20240307",
          total_tokens: 100
        )

        LLM::AnthropicClient.stubs(:generate).returns(invalid_response)

        assert_raises(JSON::ParserError) do
          Generator.call(context: @context)
        end
      end

      test "calculates cost using CostCalculator" do
        mock_response = OpenStruct.new(
          content: valid_summary_json,
          model: "claude-3-haiku-20240307",
          total_tokens: 2000
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostCalculator.expects(:get_cost).with(mock_response).returns(500) # $0.005
        LLM::CostTracker.stubs(:record)

        result = Generator.call(context: @context)

        assert_equal 500, result.metrics[:cost_micro_usd]
      end

      test "uses factory to get correct client" do
        LLM::ClientFactory.expects(:for_assignment_summary_feedback).returns(LLM::AnthropicClient)

        mock_response = OpenStruct.new(
          content: valid_summary_json,
          model: "claude-3-haiku-20240307",
          total_tokens: 1200
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        LLM::CostTracker.stubs(:record)

        Generator.call(context: @context)
      end

      test "handles LLM request errors" do
        LLM::AnthropicClient.stubs(:generate).raises(LLM::AuthenticationError, "Invalid API key")

        assert_raises(LLM::AuthenticationError) do
          Generator.call(context: @context)
        end
      end

      test "tracks assignment as trackable for cost tracking" do
        mock_response = OpenStruct.new(
          content: valid_summary_json,
          model: "claude-3-haiku-20240307",
          total_tokens: 1200
        )

        LLM::AnthropicClient.stubs(:generate).returns(mock_response)
        
        # Assignment summary generator should track against the assignment
        LLM::CostTracker.expects(:record).with(
          llm_response: mock_response,
          trackable: @assignment,
          user: @user,
          request_type: :generate_assignment_summary
        )

        Generator.call(context: @context)
      end

      private

      def valid_summary_json
        {
          qualitative_insights: "Overall, the class demonstrated strong understanding of physics concepts. Most students were able to apply theoretical knowledge to practical problems effectively.",
          feedback_items: [
            {
              type: "strength",
              title: "Conceptual Understanding",
              description: "Students showed excellent grasp of fundamental physics principles",
              evidence: "90% of students correctly identified force relationships"
            },
            {
              type: "opportunity",
              title: "Mathematical Precision",
              description: "Some students need to improve calculation accuracy",
              evidence: "Common errors in unit conversions observed"
            }
          ],
          performance_summary: {
            strong_performers: 18,
            developing_performers: 10,
            struggling_performers: 2
          }
        }.to_json
      end
    end
  end
end
```

**Implementation:**

Update `app/services/llm/assignment_summary/generator.rb`:

```ruby
# frozen_string_literal: true

module LLM
  module AssignmentSummary
    class Generator
      def self.call(context:)
        new(context).call
      end

      def initialize(context)
        @context = context
        @client = LLM::ClientFactory.for_assignment_summary_feedback
      end

      def call
        response = @context.record_timing(:llm_request) do
          make_llm_request(@context.prompt)
        end

        track_cost(response)
        update_context(response)

        @context
      end

      private

      def make_llm_request(prompt)
        response = @client.generate(prompt)
        validate_json_response(response)
        response
      rescue JSON::ParserError => e
        # One retry with instruction to fix JSON
        Rails.logger.warn "Invalid JSON response for assignment summary, retrying: #{e.message}"
        response = @client.generate(prompt + "\n\nPlease ensure the response is valid JSON.")
        validate_json_response(response)
        response
      end

      def validate_json_response(response)
        JSON.parse(response.content)
      end

      def track_cost(response)
        cost_micro_usd = LLM::CostCalculator.get_cost(response)
        
        LLM::CostTracker.record(
          llm_response: response,
          trackable: @context.assignment,
          user: @context.user,
          request_type: :generate_assignment_summary
        )
        
        @context.add_metric(:cost_micro_usd, cost_micro_usd)
      end

      def update_context(response)
        @context.llm_response = response
        @context.add_metric(:tokens_used, response.total_tokens)
      end
    end
  end
end
```

**Refactor:**
After tests pass, consider:
- Adding response schema validation for expected summary structure
- Implementing summary quality checks
- Adding aggregate metrics across all student work

---

## Subtask 4: Integration Testing with Pipelines

### Prompt for Subtask 4

Create comprehensive integration tests to verify the LLM generators work correctly within the complete pipeline architecture.

**Context:**
- All three generator classes have been implemented
- Generators need to work seamlessly within their respective pipelines
- Tests should verify the complete flow including cost tracking and metrics
- Focus on ensuring generators integrate properly with other pipeline steps

**Requirements:**
- Test generators within actual pipeline execution
- Verify cost tracking records are created
- Confirm metrics are properly recorded
- Test error scenarios and recovery
- Verify JSON retry logic works in pipeline context

**Test First (TDD):**

Create `test/integration/llm_generator_pipeline_integration_test.rb`:

```ruby
require "test_helper"

class LLMGeneratorPipelineIntegrationTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:physics_assignment)
    @user = users(:teacher_user)
    @rubric = rubrics(:physics_rubric)
    @student_work = student_works(:physics_work_one)
    
    stub_llm_responses
  end

  test "rubric generator integrates with pipeline" do
    context = Pipeline::Context::Rubric.new
    context.assignment = @assignment
    context.user = @user
    context.prompt = "Generate rubric"

    assert_difference "LLMUsageRecord.count", 1 do
      result_context = LLM::Rubric::Generator.call(context: context)
      
      assert result_context.llm_response.present?
      assert result_context.metrics[:tokens_used] == 500
      assert result_context.metrics[:cost_micro_usd] == 1500
      assert result_context.metrics[:llm_request_ms] > 0
    end

    usage_record = LLMUsageRecord.last
    assert_equal @assignment, usage_record.trackable
    assert_equal @user, usage_record.user
    assert_equal "gemini-pro", usage_record.llm_model
    assert_equal :google, usage_record.llm_provider
    assert_equal :generate_rubric, usage_record.request_type.to_sym
    assert_equal 500, usage_record.token_count
    assert_equal 1500, usage_record.micro_usd
  end

  test "student work generator integrates with pipeline" do
    context = Pipeline::Context::StudentWork.new
    context.student_work = @student_work
    context.rubric = @rubric
    context.user = @user
    context.assignment = @student_work.assignment
    context.prompt = "Analyze student work"

    assert_difference "LLMUsageRecord.count", 1 do
      result_context = LLM::StudentWork::Generator.call(context: context)
      
      assert result_context.llm_response.present?
      assert result_context.metrics[:tokens_used] == 800
      assert result_context.metrics[:cost_micro_usd] == 250
    end

    usage_record = LLMUsageRecord.last
    assert_equal @student_work, usage_record.trackable
    assert_equal "claude-3-haiku-20240307", usage_record.llm_model
    assert_equal :anthropic, usage_record.llm_provider
    assert_equal :generate_student_work_feedback, usage_record.request_type.to_sym
  end

  test "assignment summary generator integrates with pipeline" do
    context = Pipeline::Context::AssignmentSummary.new
    context.assignment = @assignment
    context.user = @user
    context.student_feedbacks = []
    context.prompt = "Generate summary"

    assert_difference "LLMUsageRecord.count", 1 do
      result_context = LLM::AssignmentSummary::Generator.call(context: context)
      
      assert result_context.llm_response.present?
      assert result_context.metrics[:tokens_used] == 1200
      assert result_context.metrics[:cost_micro_usd] == 300
    end

    usage_record = LLMUsageRecord.last
    assert_equal @assignment, usage_record.trackable
    assert_equal :generate_assignment_summary, usage_record.request_type.to_sym
  end

  test "generators handle JSON retry in pipeline context" do
    # Override stub to return invalid JSON first
    LLM::GoogleClient.unstub(:generate)
    
    invalid_response = OpenStruct.new(
      content: "Invalid JSON",
      model: "gemini-pro",
      total_tokens: 100
    )
    
    valid_response = OpenStruct.new(
      content: valid_rubric_json,
      model: "gemini-pro",
      total_tokens: 500
    )
    
    LLM::GoogleClient.expects(:generate).twice.returns(invalid_response, valid_response)
    
    context = Pipeline::Context::Rubric.new
    context.assignment = @assignment
    context.user = @user
    context.prompt = "Generate rubric"
    
    result = LLM::Rubric::Generator.call(context: context)
    
    assert_equal valid_response, result.llm_response
    assert_equal 1, LLMUsageRecord.count # Only tracks successful request
  end

  test "complete rubric pipeline with generator" do
    # Test the full pipeline flow
    result = RubricPipeline.call(
      assignment: @assignment,
      user: @user
    )
    
    assert result.successful?
    assert result.data.is_a?(Rubric)
    
    # Verify LLM usage was tracked
    usage_record = LLMUsageRecord.last
    assert_equal :generate_rubric, usage_record.request_type.to_sym
    
    # Verify metrics were recorded
    assert result.metrics[:tokens_used] == 500
    assert result.metrics[:cost_micro_usd] == 1500
    assert result.metrics[:llm_request_ms] > 0
  end

  test "generators preserve context for subsequent pipeline steps" do
    context = Pipeline::Context::StudentWork.new
    context.student_work = @student_work
    context.rubric = @rubric
    context.user = @user
    context.assignment = @student_work.assignment
    context.prompt = "Analyze student work"
    context.add_metric(:previous_step_ms, 100)
    
    result = LLM::StudentWork::Generator.call(context: context)
    
    # Verify context is preserved
    assert_equal @student_work, result.student_work
    assert_equal @rubric, result.rubric
    assert_equal 100, result.metrics[:previous_step_ms]
    
    # Verify new metrics were added
    assert result.metrics[:llm_request_ms].present?
    assert result.metrics[:tokens_used].present?
  end

  test "cost tracking works across different providers" do
    # Test Google (Rubric)
    rubric_context = Pipeline::Context::Rubric.new
    rubric_context.assignment = @assignment
    rubric_context.user = @user
    rubric_context.prompt = "Generate rubric"
    
    LLM::Rubric::Generator.call(context: rubric_context)
    
    # Test Anthropic (Student Work)
    student_context = Pipeline::Context::StudentWork.new
    student_context.student_work = @student_work
    student_context.user = @user
    student_context.assignment = @student_work.assignment
    student_context.prompt = "Analyze work"
    
    LLM::StudentWork::Generator.call(context: student_context)
    
    # Verify both were tracked with correct providers
    records = LLMUsageRecord.last(2)
    
    google_record = records.find { |r| r.llm_provider == "google" }
    anthropic_record = records.find { |r| r.llm_provider == "anthropic" }
    
    assert google_record.present?
    assert anthropic_record.present?
    assert_equal "gemini-pro", google_record.llm_model
    assert_equal "claude-3-haiku-20240307", anthropic_record.llm_model
  end

  private

  def stub_llm_responses
    # Stub Google client for rubric
    google_response = OpenStruct.new(
      content: valid_rubric_json,
      model: "gemini-pro",
      total_tokens: 500,
      input_tokens: 100,
      output_tokens: 400
    )
    
    LLM::GoogleClient.stubs(:generate).returns(google_response)
    
    # Stub Anthropic client for student work and summary
    anthropic_student_response = OpenStruct.new(
      content: valid_feedback_json,
      model: "claude-3-haiku-20240307",
      total_tokens: 800,
      input_tokens: 300,
      output_tokens: 500
    )
    
    anthropic_summary_response = OpenStruct.new(
      content: valid_summary_json,
      model: "claude-3-haiku-20240307",
      total_tokens: 1200,
      input_tokens: 700,
      output_tokens: 500
    )
    
    LLM::AnthropicClient.stubs(:generate)
      .returns(anthropic_student_response)
      .then.returns(anthropic_summary_response)
    
    # Stub cost calculator
    LLM::CostCalculator.stubs(:get_cost).returns(1500, 250, 300)
  end

  def valid_rubric_json
    {
      criteria: [
        {
          title: "Understanding",
          description: "Shows understanding of concepts",
          levels: [
            { title: "Excellent", description: "Complete understanding" },
            { title: "Good", description: "Solid understanding" },
            { title: "Developing", description: "Basic understanding" }
          ]
        }
      ]
    }.to_json
  end

  def valid_feedback_json
    {
      qualitative_feedback: "Good work overall",
      feedback_items: [
        {
          type: "strength",
          title: "Clear writing",
          description: "Well organized thoughts"
        }
      ]
    }.to_json
  end

  def valid_summary_json
    {
      qualitative_insights: "Class performed well overall",
      feedback_items: [
        {
          type: "strength",
          title: "Strong understanding",
          description: "Most students grasp concepts"
        }
      ]
    }.to_json
  end
end
```

**Implementation:**

No new implementation needed for this subtask - it's testing the integration of previously implemented components.

**Refactor:**
After tests pass, consider:
- Adding performance benchmarks for generator execution
- Creating test helpers for common LLM response stubs
- Adding integration tests with actual pipeline error scenarios

---

## Summary

This implementation plan provides a complete, testable approach to implementing LLM generator classes that integrate seamlessly with GradeBot's existing architecture.

Key features implemented:
- **Consistent interface**: All generators follow the same `.call(context:)` pattern
- **Automatic cost tracking**: Integration with LLM::CostTracker for usage monitoring
- **JSON retry logic**: One retry attempt for malformed JSON responses
- **Metrics collection**: Timing and token usage tracked in context
- **Provider flexibility**: Uses ClientFactory for appropriate provider selection

The TDD approach ensures each generator is thoroughly tested before integration, reducing bugs and improving code quality. The generators are designed to be stateless and focused on a single responsibility, making them easy to test, maintain, and extend.