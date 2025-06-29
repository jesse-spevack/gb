# Assignment Processing Pipeline Troubleshooting - 2025-06-03

## Issue Summary

**User reported**: "I just created a new assignment on localhost. It still looks to me like the job is not running."

**Actual Problem Found**: The SolidQueue workers ARE running correctly, but the AssignmentJob is failing during the rubric generation phase with validation errors. The job shows as "finished" in the queue but produces no results.

## Current Status

### ✅ Working Components
- **SolidQueue Workers**: Running correctly with dispatcher and supervisors active (PIDs 36548, 36534, 36505)
- **Job Enqueueing**: AssignmentJob is being created and processed
- **Job Execution**: Jobs run to completion but fail internally
- **Basic Pipeline Structure**: All pipeline classes are in place
- **Markdown Stripping**: Added comprehensive support across all LLM parsers/generators to handle markdown-wrapped JSON
- **Test Suite**: All 617 tests passing with comprehensive regression coverage

### ❌ Failing Components
- **Assignment 9 (New)**: Job completed but rubric has 0 criteria due to validation error
- **Rubric Generation**: Failing with "Points must be unique within criterion" validation error
- **Student Work Processing**: Cannot proceed without rubric (incomplete implementation anyway)
- **Assignment Summary**: Cannot proceed without student work

## Detailed Error Analysis

### Assignment 9 Failure Timeline

1. **Initial Log Error** (from `grep -E "(AssignmentJob|Assignment.*9)" log/development.log`):
   ```
   AssignmentJob failed for assignment 9: RubricPipeline failed: expected ',' or '}' after object value, got: '- 25
   ```

2. **Manual Testing Error** (after adding markdown stripping):
   ```
   Validation failed: Points must be unique within criterion
   ```

3. **Current State**:
   - Assignment 9 exists with title: "Analyze the causes and effects of Franklin D. Roosevelt's New Deal programs during the Great Depression"
   - Has a rubric (ID: 7) but with 0 criteria
   - Has 3 student works but 0 feedback items
   - No assignment summary

**Analysis**: The JSON parsing issue was resolved by our markdown stripping fixes, but now there's a database constraint violation during rubric storage.

## Investigation Done

1. **Worker Status**: Confirmed SolidQueue processes are running
2. **Job Execution**: Jobs are running but failing during rubric creation  
3. **JSON Parsing**: Added markdown stripping to all LLM clients and parsers
4. **Test Coverage**: Added comprehensive regression tests for markdown handling
5. **Error Logging**: Found specific validation errors in logs

## Logging Added for Debugging

### Files Modified with Logging:
- `/app/lib/llm/google_client.rb` - Raw Google API response logging
- `/app/lib/llm/anthropic_client.rb` - Raw Anthropic API response logging  
- `/app/models/llm_response.rb` - Extracted text logging for both providers
- `/app/services/llm/rubric/generator.rb` - LLM response logging
- `/app/services/llm/rubric/response_parser.rb` - Parsed structure logging

### Logging Flow:
1. Raw API response body (Google/Anthropic clients)
2. Extracted text from API response (LLMResponse model)
3. Final LLM response text (Rubric generator)
4. Parsed rubric structure with positions (Response parser)

## Root Cause Analysis

The "Points must be unique within criterion" error is a database constraint violation happening in `/app/models/level.rb:38`. The constraint ensures that within each criterion, all levels have unique point values.

**Current Points Logic** (from `/app/services/pipeline/storage/rubric_service.rb:91-97`):
```ruby
def self.calculate_points_from_position(position)
  # Map position to points inversely:
  # Position 1 (highest achievement) = 4 points
  # Position 2 = 3 points  
  # Position 3 = 2 points
  # Position 4 (lowest achievement) = 1 point
  5 - position
end
```

**Potential Causes**:
1. **Duplicate Positions**: Multiple levels within a criterion getting the same position value
2. **Position Assignment Logic**: The `build_level` method in response parser may assign duplicate positions
3. **LLM Response Format**: Varying response structures causing position calculation errors

**Key Insight**: Assignment 8 worked correctly with positions (4,3,2,1) and points (1,2,3,4). Assignment 9 is failing, suggesting different LLM response format.

## Files Involved

### Core Pipeline Files:
- `/app/services/rubric_pipeline.rb` - Main rubric generation pipeline
- `/app/services/llm/rubric/generator.rb` - LLM request handling
- `/app/services/llm/rubric/response_parser.rb` - Response parsing and validation
- `/app/services/pipeline/storage/rubric_service.rb` - Database persistence

### LLM Client Files:
- `/app/lib/llm/google_client.rb` - Google AI API client (used for rubrics)
- `/app/lib/llm/anthropic_client.rb` - Anthropic API client (student work/summaries)
- `/app/models/llm_response.rb` - Response processing

### Configuration:
- `/app/lib/llm/client_factory.rb` - Rubric generation uses GoogleClient
- `/app/models/level.rb` - Points uniqueness validation

## Next Steps for Debugging

### Immediate Actions (Priority Order):

1. **Run logged test to capture LLM response**:
   ```bash
   bin/rails runner "assignment = Assignment.find(9); result = RubricPipeline.call(assignment: assignment, user: assignment.user); puts 'Success: ' + result.success.to_s; puts 'Errors: ' + result.errors.inspect unless result.success"
   ```

2. **Analyze the logs** to see:
   - Raw Google API response format
   - Extracted text from response
   - Parsed rubric structure with position assignments

3. **Focus investigation on position assignment logic** in:
   - `/app/services/llm/rubric/response_parser.rb:205-237` (build_level method)
   - `/app/services/pipeline/storage/rubric_service.rb:91-97` (calculate_points_from_position)

### Additional Diagnostic Commands:
```ruby
# Check Assignment 8 (working) vs Assignment 9 (failing) rubric structures
[8, 9].each do |id|
  assignment = Assignment.find(id)
  puts "Assignment #{id}:"
  puts "  Criteria count: #{assignment.rubric.criteria.count}"
  assignment.rubric.criteria.each_with_index do |c, i|
    puts "  Criterion #{i+1}: #{c.title}"
    c.levels.each { |l| puts "    #{l.title}: position=#{l.position}, points=#{l.points}" }
  end
  puts ""
end

# Test manual rubric creation to isolate the issue
assignment = Assignment.find(9)
context = Pipeline::Context::Rubric.new
context.assignment = assignment
context.user = assignment.user
prompt_result = PromptInput::Rubric.call(context: context)
generator_result = LLM::Rubric::Generator.call(context: prompt_result)
parser_result = LLM::Rubric::ResponseParser.call(context: generator_result)
# Check parser_result.parsed_response.criteria for position assignments
```

### Investigation Focus:
1. **Position Assignment**: How are positions (1-4) being assigned to levels?
2. **Points Calculation**: How are points being calculated from positions?
3. **Duplicate Detection**: Why are duplicate points being created within criteria?

### Potential Fixes:
1. **Improve Position Logic**: Ensure positions are unique within each criterion
2. **Enhanced Validation**: Better error handling for position conflicts
3. **LLM Response Handling**: More robust parsing for varying response formats

## Background Context

### Previous Fixes Applied:
- Added `status` attribute to `Pipeline::Context::Base`
- Fixed JSON parsing with markdown stripping across all parsers
- Made rubric response parser flexible for varying LLM formats
- Updated tests to match flexible validation behavior
- Added comprehensive test coverage for markdown parsing

### Architecture:
- **Rubric Generation**: Uses Google AI API via GoogleClient
- **Student Work Processing**: Uses Anthropic API (incomplete implementation)
- **Assignment Summary**: Uses Anthropic API (depends on student work)

### Working Assignment (Reference):
- **Assignment 8**: Successfully created rubric with 5 criteria, 4 levels each
- All positions properly assigned (4,3,2,1) with corresponding points (1,2,3,4)
- Example working structure:
  ```
  Understanding of the Causes of the New Deal (25 points) (4 levels)
  Analysis of Key Programs and Reforms (25 points) (4 levels)  
  Impact on Different Groups of Americans (25 points) (4 levels)
  Lasting Impact on American Society and Government (25 points) (4 levels)
  Organization, Clarity, and Writing Quality (0-10 points) (4 levels)
  ```

### Student Work Pipeline Status:
- **Student Work Processing**: Uses `PromptInput::StudentWork` which is currently a placeholder returning "Analyze the student work and provide feedback"
- **Google Docs Integration**: Missing - no actual student content being fetched
- **Assignment Summary**: Depends on student work completion

## Critical Success Path

To get assignment processing fully working:

1. **IMMEDIATE**: Fix Assignment 9 rubric generation (this document focuses here)
2. **SHORT TERM**: Implement `PromptInput::StudentWork` with actual Google Docs content fetching
3. **MEDIUM TERM**: Complete student work feedback and assignment summary pipelines

## Files Ready for Investigation

All logging is in place. **The exact next steps are**:

1. **Run the logged test** (commands provided above) to capture logged output
2. **Examine the logs** for Raw Google API Response, Extracted text, and Parsed structure
3. **Compare LLM response format** between Assignment 8 (working) and Assignment 9 (failing)
4. **Fix position assignment logic** to prevent duplicate points within criteria
5. **Test the fix** with Assignment 9
6. **Verify end-to-end rubric generation** works consistently

The comprehensive logging will show exactly what the LLM is returning and how it's being processed, making the root cause identification straightforward.