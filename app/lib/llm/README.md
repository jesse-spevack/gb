# LLM Library

This library provides utilities for working with Large Language Models (LLMs) including cost tracking, cost calculation, and response handling.

## Components

### LLM::CostTracker

A service class for recording LLM usage data and costs to the database.

**Key Features:**
- Automatic cost calculation using `LLM::CostCalculator`
- Automatic provider detection using centralized model configuration
- Comprehensive error handling for invalid models and missing data
- Support for various trackable entity types (Users, Assignments, Rubrics, etc.)

**Usage:**
```ruby
# Record LLM usage
record = LLM::CostTracker.record(
  llm_response: response,
  trackable: user,
  user: current_user,
  request_type: :generate_rubric
)
```

**Model/Provider Mapping:**
The CostTracker automatically maps model names to providers using the centralized configuration in `config/llm_models.yml`. This ensures consistency across the application and makes it easy to add new models without code changes.

Currently supported providers:
- `:anthropic` - Claude models (claude-3-5-sonnet, claude-3-5-haiku, etc.)
- `:google` - Gemini models (gemini-2.0-flash, gemini-2.5-flash-preview, etc.)

### LLM::CostCalculator

Calculates usage costs in micro-USD based on model pricing and token counts.

**Features:**
- Uses centralized model configuration for pricing data
- Returns costs in micro-USD (1 USD = 1,000,000 micro-USD) for precision
- Handles both input and output token pricing
- Comprehensive error handling for unknown models

### LLMResponse

A Plain Old Ruby Object (PORO) representing an LLM response with token tracking.

**Attributes:**
- `text` - The response text
- `input_tokens` - Number of input tokens (optional)
- `output_tokens` - Number of output tokens (optional) 
- `model` - Model identifier string
- `raw_response` - Original response data (optional)

**Methods:**
- `total_tokens` - Sum of input and output tokens (nil-safe)

### LLMUsageRecord

ActiveRecord model for persisting LLM usage data.

**Fields:**
- `trackable` - Polymorphic association to any entity the LLM interaction relates to
- `user` - The user who initiated the request
- `llm_provider` - Enum: `:google`, `:anthropic`
- `llm_model` - Exact model name used (e.g., "claude-3-5-sonnet-20241022")
- `request_type` - Enum: `:generate_rubric`, `:grade_student_work`
- `token_count` - Total tokens used
- `micro_usd` - Cost in micro-USD

**Methods:**
- `dollars` - Convert micro_usd to dollar amount for display

## Configuration

Model definitions, pricing, and provider mappings are centralized in `config/llm_models.yml`. This YAML file contains:

- Model identifiers and display names
- Provider mappings (anthropic, google)
- Input/output costs per million tokens
- Context window sizes
- Descriptions and metadata

To add support for a new model:
1. Add the model definition to `config/llm_models.yml`
2. Ensure the provider is supported in `CostTracker#map_model_to_provider`
3. Update the `llm_provider` enum in `LLMUsageRecord` if needed

## Error Handling

**LLM::CostTracker::UnknownModelError** - Raised when:
- Model name is nil
- Model is not found in configuration
- Provider is not supported by the system

**LLM::CostCalculator::UnknownModelError** - Raised when:
- Model configuration is missing pricing data
- Model name cannot be resolved

**ArgumentError** - Raised for missing required parameters

## Examples

### Basic Usage
```ruby
# Create an LLM response object
response = LLMResponse.new(
  text: "Generated rubric content...",
  input_tokens: 150,
  output_tokens: 300,
  model: "claude-3-5-haiku-20241022"
)

# Record the usage
record = LLM::CostTracker.record(
  llm_response: response,
  trackable: assignment,
  user: current_user,
  request_type: :generate_rubric
)

puts "Cost: $#{record.dollars}"
puts "Provider: #{record.llm_provider}"
puts "Model: #{record.llm_model}"
```

### Cost Calculation Only
```ruby
cost_micro_usd = LLM::CostCalculator.get_cost(response)
puts "Cost: $#{cost_micro_usd / 1_000_000.0}"
```

### Different Trackable Types
```ruby
# Track usage for different entity types
rubric_record = LLM::CostTracker.record(
  llm_response: response,
  trackable: rubric,
  user: current_user,
  request_type: :generate_rubric
)

user_record = LLM::CostTracker.record(
  llm_response: response,
  trackable: student,
  user: current_user,
  request_type: :grade_student_work
)
```

## Testing

Comprehensive test coverage includes:
- Valid usage recording with different models and providers
- Error handling for invalid inputs
- Token count calculations including nil/zero values
- Different trackable entity types
- Cost calculations and conversions

Run tests with:
```bash
bundle exec ruby -Itest test/lib/llm/cost_tracker_test.rb
```

## Current Limitations

1. **Model Mapping**: The current model mapping is simplified - all Claude models map to `:claude_3_7_sonnet` and all Gemini models map to `:gemini_2_5_pro`. This should be improved for better granularity.

2. **Request Types**: The enum only includes `:generate_rubric` and `:grade_student_work`. Additional request types will need to be added as features expand.

3. **No Aggregation**: Currently only tracks individual requests. Future work may include pre-calculated aggregations for faster reporting. 