# Task List: LLM Response Parser Classes

## Relevant Files

- `app/services/llm/rubric/response_parser.rb` - Parser for transforming rubric generation JSON responses
- `test/services/llm/rubric/response_parser_test.rb` - Unit tests for rubric response parser
- `app/services/llm/student_work/response_parser.rb` - Parser for transforming student work feedback JSON responses
- `test/services/llm/student_work/response_parser_test.rb` - Unit tests for student work response parser
- `app/services/llm/assignment_summary/response_parser.rb` - Parser for transforming assignment summary JSON responses
- `test/services/llm/assignment_summary/response_parser_test.rb` - Unit tests for assignment summary response parser
- `app/services/rubric_pipeline.rb` - Existing pipeline that will integrate the rubric parser
- `app/services/student_work_feedback_pipeline.rb` - Existing pipeline that will integrate the student work parser
- `app/services/assignment_summary_pipeline.rb` - Existing pipeline that will integrate the assignment summary parser

### Notes

- Unit tests should be placed in the `test` directory mirroring the app structure
- Use `bin/rails test [optional/path/to/test/file]` to run tests. Running without a path executes all tests.
- Parsers should follow the existing pipeline pattern with `.call(context:)` interface
- OpenStruct will be used for dot notation access to parsed data

## Tasks

| Task ID | Subtask ID | Workstream | Status | Task Title | Task Description | Details |
| --- | --- | --- | --- | --- | --- | --- |
| 1.0 | 1.1 | ws1 | 🟢 completed | Write Rubric Parser Tests | Create comprehensive test suite for rubric response parser | [Details 1.1](#task-11) |
| 1.0 | 1.2 | ws1 | 🟢 completed | Implement Rubric Parser Class | Create LLM::Rubric::ResponseParser with JSON parsing and validation | [Details 1.2](#task-12) |
| 1.0 | 1.3 | ws1 | 🟢 completed | Add Rubric Parser Error Handling | Implement error handling for invalid JSON and missing fields | [Details 1.3](#task-13) |
| 2.0 | 2.1 | ws1 | 🟢 completed | Write Student Work Parser Tests | Create comprehensive test suite for student work response parser | [Details 2.1](#task-21) |
| 2.0 | 2.2 | ws1 | 🟢 completed | Implement Student Work Parser Class | Create LLM::StudentWork::ResponseParser with JSON parsing and validation | [Details 2.2](#task-22) |
| 2.0 | 2.3 | ws1 | 🟢 completed | Add Student Work Parser Error Handling | Implement error handling for invalid JSON and validation errors | [Details 2.3](#task-23) |
| 3.0 | 3.1 | ws1 | 🟢 completed | Write Assignment Summary Parser Tests | Create comprehensive test suite for assignment summary response parser | [Details 3.1](#task-31) |
| 3.0 | 3.2 | ws1 | 🟢 completed | Implement Assignment Summary Parser Class | Create LLM::AssignmentSummary::ResponseParser with JSON parsing and validation | [Details 3.2](#task-32) |
| 3.0 | 3.3 | ws1 | 🟢 completed | Add Assignment Summary Parser Error Handling | Implement error handling for invalid JSON and validation errors | [Details 3.3](#task-33) |
| 4.0 | 4.1 | ws1 | 🟢 completed | Integrate Rubric Parser into Pipeline | Update RubricPipeline to use the new parser after generator | [Details 4.1](#task-41) |
| 4.0 | 4.2 | ws1 | 🟢 completed | Integrate Student Work Parser into Pipeline | Update StudentWorkFeedbackPipeline to use the new parser | [Details 4.2](#task-42) |
| 4.0 | 4.3 | ws1 | 🟢 completed | Integrate Assignment Summary Parser into Pipeline | Update AssignmentSummaryPipeline to use the new parser | [Details 4.3](#task-43) |
| 4.0 | 4.4 | ws1 | 🟢 completed | Test Pipeline Integration | Run integration tests to verify parsers work within pipelines | [Details 4.4](#task-44) |
| 5.0 | 5.1 | ws1 | 🟢 completed | Analyze Parser Code Duplication | Review all three parsers for common patterns and functionality | [Details 5.1](#task-51) |
| 5.0 | 5.2 | ws1 | 🟢 completed | Extract Base Parser (If Beneficial) | Create base parser class only if it improves code clarity | [Details 5.2](#task-52) |

## Implementation plan

### Task 1.1
**Write Rubric Parser Tests**

Create `test/services/llm/rubric/response_parser_test.rb` with test cases for:
- Valid JSON parsing with complete rubric data
- Invalid JSON that should raise JSON::ParserError
- Missing required fields (title, description, position)
- Invalid data types (e.g., position as string instead of integer)
- Missing levels array
- Invalid level positions (outside 1-4 range)
- Empty criteria array
- Verify parsed response is added to context
- Verify dot notation access works (e.g., parsed.criteria[0].title)
- Test string sanitization (whitespace trimming)

### Task 1.2
**Implement Rubric Parser Class**

Create `app/services/llm/rubric/response_parser.rb`:
- Implement `.call(context:)` class method
- Parse JSON from `context.llm_response.text`
- Create OpenStruct objects for dot notation access
- Validate required fields: criteria array with title, description, position
- Validate each level has: name/title, description, position (1-4)
- Add `parsed_response` to context object
- Return the updated context

### Task 1.3
**Add Rubric Parser Error Handling**

Enhance the rubric parser with:
- Catch JSON::ParserError and re-raise with descriptive message
- Create custom validation errors for missing fields
- Log errors using Rails.logger.error with structured data
- Include original response in error logs for debugging
- Ensure extra/unexpected fields are ignored
- Handle nil values gracefully

### Task 2.1
**Write Student Work Parser Tests**

Create `test/services/llm/student_work/response_parser_test.rb` with test cases for:
- Valid JSON parsing with complete student feedback data
- Invalid JSON that should raise JSON::ParserError
- Missing qualitative_feedback field
- Invalid feedback_items (missing type, title, description, evidence)
- Invalid item_type values (not "strength" or "opportunity")
- Missing criterion_levels array
- Invalid criterion_id or level_id (non-integer)
- Missing explanation in criterion_levels
- Invalid checks array (missing type, score, explanation)
- Invalid check_type values (not "plagiarism" or "llm_generated")
- Score validation (must be 0-100)
- Verify parsed response is added to context
- Test dot notation access for nested structures

### Task 2.2
**Implement Student Work Parser Class**

Create `app/services/llm/student_work/response_parser.rb`:
- Implement `.call(context:)` class method
- Parse JSON from `context.llm_response.text`
- Create OpenStruct objects for all nested data
- Validate qualitative_feedback is present and is a string
- Validate feedback_items array structure and item_type values
- Validate criterion_levels with criterion_id, level_id, explanation
- Validate checks array with check_type, score (0-100), explanation
- Add `parsed_response` to context object
- Return the updated context

### Task 2.3
**Add Student Work Parser Error Handling**

Enhance the student work parser with:
- Comprehensive error messages for each validation failure
- Log errors with context about which student work failed
- Handle edge cases like empty arrays
- Validate score ranges (0-100)
- Ensure string fields are properly sanitized

### Task 3.1
**Write Assignment Summary Parser Tests**

Create `test/services/llm/assignment_summary/response_parser_test.rb` with test cases for:
- Valid JSON parsing with complete assignment summary
- Invalid JSON that should raise JSON::ParserError
- Missing qualitative_insights field
- Feedback items validation (min 2 items required)
- At least one strength and one opportunity validation
- Feedback item structure validation (same as student work)
- Verify parsed response is added to context
- Test dot notation access

### Task 3.2
**Implement Assignment Summary Parser Class**

Create `app/services/llm/assignment_summary/response_parser.rb`:
- Implement `.call(context:)` class method
- Parse JSON from `context.llm_response.text`
- Create OpenStruct objects for structured access
- Validate qualitative_insights is present
- Validate feedback_items array (min 2 items)
- Ensure at least one strength and one opportunity
- Reuse validation logic from student work parser for feedback items
- Add `parsed_response` to context object
- Return the updated context

### Task 3.3
**Add Assignment Summary Parser Error Handling**

Enhance the assignment summary parser with:
- Specific error for insufficient feedback items
- Validation for strength/opportunity balance
- Clear error messages for missing fields
- Structured logging of parsing failures

### Task 4.1
**Integrate Rubric Parser into Pipeline**

Update `app/services/rubric_pipeline.rb`:
- Add `LLM::Rubric::ResponseParser` to STEPS array after `LLM::Rubric::Generator`
- Ensure context flows properly from generator to parser
- Verify parsed_response is available for storage service
- Update any pipeline tests affected by this change

### Task 4.2
**Integrate Student Work Parser into Pipeline**

Update `app/services/student_work_feedback_pipeline.rb`:
- Add `LLM::StudentWork::ResponseParser` to STEPS array after generator
- Ensure context maintains student_work reference
- Verify parsed data structure matches storage service expectations
- Update pipeline tests

### Task 4.3
**Integrate Assignment Summary Parser into Pipeline**

Update `app/services/assignment_summary_pipeline.rb`:
- Add `LLM::AssignmentSummary::ResponseParser` to STEPS array
- Ensure assignment context is preserved
- Verify integration with storage service
- Update pipeline tests

### Task 4.4
**Test Pipeline Integration**

Run comprehensive tests:
- Execute `bin/rails test` to run all tests
- Verify all parser tests pass
- Verify pipeline integration tests pass
- Test error scenarios through the full pipeline
- Ensure JSON parsing errors trigger retries in generators
- Verify context preservation through pipeline steps

### Task 5.1
**Analyze Parser Code Duplication**

Review all three parser implementations:
- Identify common JSON parsing logic
- Find shared validation patterns
- Look for repeated error handling code
- Document potential extraction points
- Consider if extraction would improve maintainability

### Task 5.2
**Extract Base Parser (If Beneficial)**

Only implement if analysis shows clear benefits:
- Create base parser with common JSON parsing
- Extract shared validation helpers
- Implement common error handling
- Ensure base class doesn't add unnecessary complexity
- Update all parsers to inherit from base
- Verify all tests still pass
- Document the abstraction clearly for junior developers