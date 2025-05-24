# LLM Module

This module provides utilities for working with Large Language Models (LLMs) in the application.

## Classes

### LLM::CostCalculator

Calculates the cost of LLM API calls based on model usage and token consumption.

### LLM::CostTracker

Records LLM usage and cost data by taking an `LLMResponse` and saving an `LLMUsageRecord` record for tracking and business intelligence.

#### Usage

```ruby
# After making an LLM API call and getting a response
response = llm_client.send_request(prompt)

# Track the cost and usage
LLM::CostTracker.record(
  llm_response: response,
  trackable: assignment,          # The business object this request relates to
  user: current_user,            # Who made the request
  request_type: :generate_rubric, # What type of operation this was
  prompt: original_prompt        # The prompt that was sent
)
```

#### Parameters

- `llm_response`: An `LLMResponse` object containing the API response and token usage
- `trackable`: Any ActiveRecord object this request relates to (Assignment, Rubric, etc.)
- `user`: The User who initiated the request
- `request_type`: Symbol indicating the type of operation (`:generate_rubric`, `:grade_student_work`)
- `prompt`: The original prompt text sent to the LLM

#### What it does

1. Calculates the total cost using `LLM::CostCalculator`
2. Extracts token usage from the response
3. Maps the model name to the appropriate enum value
4. Creates and saves an `LLMUsageRecord` record for tracking

#### Error Handling

- Raises `ArgumentError` for missing required parameters
- Raises `LLM::CostTracker::UnknownModelError` for unrecognized models
- Re-raises validation errors from the `LLMUsageRecord` model

## Models

### LLMUsageRecord

Records individual LLM API calls with cost and usage information for business analytics.

#### Fields

- `trackable`: Polymorphic association to the business object
- `user`: The user who made the request
- `llm`: Enum for the LLM provider/model (maps to simplified categories)
- `request_type`: Enum for the type of operation
- `token_count`: Total tokens used (input + output)
- `micro_usd`: Cost in micro-dollars (1,000,000 = $1.00)
- `prompt`: The original prompt text

#### Methods

- `dollars`: Returns cost converted to dollars (divides micro_usd by 1,000,000)

## Integration Points

### Processing Pipeline

The CostTracker should be called explicitly from processing pipelines after LLM API calls:

```ruby
# In a service class
def generate_rubric_for_assignment(assignment, user)
  prompt = build_rubric_prompt(assignment)
  response = llm_client.generate(prompt)
  
  # Track the cost
  LLM::CostTracker.record(
    llm_response: response,
    trackable: assignment,
    user: user,
    request_type: :generate_rubric,
    prompt: prompt
  )
  
  # Process the response
  process_rubric_response(response.text)
end
```

### Future Reporting

The tracked data can be used for:

- Cost analysis per user, assignment, or time period
- Usage patterns and optimization opportunities
- Business intelligence and budgeting
- Performance monitoring

## Current Limitations

1. **Model Mapping**: The current model mapping is simplified - all Claude models map to `:claude_3_7_sonnet` and all Gemini models map to `:gemini_2_5_pro`. This should be improved for better granularity.

2. **Request Types**: The enum only includes `:generate_rubric` and `:grade_student_work`. Additional request types will need to be added as features expand.

3. **No Aggregation**: Currently only tracks individual requests. Future work may include pre-calculated aggregations for faster reporting. 