# LLM Response Parser Classes PRD

## Introduction/Overview

This feature implements a set of parser classes that transform raw JSON responses from Large Language Models (LLMs) into structured application data for GradeBot. These parsers serve as a critical bridge between the AI-generated content and the application's data models, ensuring that LLM outputs are properly validated, sanitized, and structured for use throughout the system.

The parsers handle responses from the three main LLM generation tasks: rubric generation, student work feedback, and assignment summaries. They are designed to be provider-agnostic and include robust error handling to manage potential issues with LLM-generated JSON.

## Goals

1. Transform raw LLM JSON responses into structured Ruby objects with dot notation access
2. Provide robust JSON parsing with automatic retry triggering on invalid JSON
3. Ensure data validation and sanitization before storage
4. Maintain consistency across all parser implementations
5. Enable seamless integration with the existing pipeline architecture
6. Support provider-agnostic parsing (works with Anthropic, Google, etc.)

## User Stories

1. As a developer, I want parsers that automatically handle malformed JSON from LLMs so that the system can recover gracefully
2. As a developer, I want parsed data accessible via dot notation so that I can work with objects instead of hash access
3. As a system, I need to validate parsed data against model requirements so that invalid data doesn't corrupt the database
4. As a pipeline component, I need parsers that integrate seamlessly with the existing context flow so that data moves smoothly through the system

## Functional Requirements

### LLM::Rubric::ResponseParser

1. The parser must extract rubric data from JSON responses containing criteria and levels
2. The parser must validate that each criterion has:
   - A title (required string)
   - A description (required string)
   - A position (required integer)
   - An array of levels
3. The parser must validate that each level has:
   - A name/title (required string)
   - A description (required string)
   - A position (required integer, 1-4)
4. The parser must return an object structure matching the Rubric/Criterion/Level models
5. The parser must raise a JSON::ParserError if the response is not valid JSON

### LLM::StudentWork::ResponseParser

6. The parser must extract student feedback data including:
   - Qualitative feedback (required string)
   - Feedback items array (required)
   - Criterion levels array (required)
   - Checks array (required)
7. The parser must validate feedback items contain:
   - item_type (required, must be "strength" or "opportunity")
   - title (required string)
   - description (required string)
   - evidence (required string)
8. The parser must validate criterion_levels contain:
   - criterion_id (required integer)
   - level_id (required integer)
   - explanation (required string)
9. The parser must validate checks contain:
   - check_type (required, must be "plagiarism" or "llm_generated")
   - score (required integer, 0-100)
   - explanation (required string)
10. The parser must return structured objects accessible via dot notation

### LLM::AssignmentSummary::ResponseParser

11. The parser must extract assignment summary data including:
    - Qualitative insights (required string)
    - Feedback items array (required, min 2 items)
12. The parser must validate feedback items follow the same structure as StudentWork feedback items
13. The parser must ensure at least one strength and one opportunity are present

### Common Requirements

14. All parsers must implement a consistent `.call(context:)` interface
15. All parsers must log parsing failures using Rails.logger.error
16. All parsers must handle missing required fields by raising descriptive errors
17. All parsers must sanitize string inputs (strip whitespace, handle nil values)
18. All parsers must return objects that support dot notation access (e.g., parsed.criteria[0].title)
19. All parsers must preserve the original LLM response in the context for debugging
20. All parsers must add parsed_response to the context object

## Non-Goals (Out of Scope)

1. This feature will NOT retry LLM requests - that's handled by the generator classes
2. This feature will NOT persist data to the database - that's handled by storage services
3. This feature will NOT make additional LLM calls to fix malformed responses
4. This feature will NOT handle authentication or authorization
5. This feature will NOT track costs or metrics - that's handled by other components
6. This feature will NOT broadcast status updates - that's handled by the pipeline

## Design Considerations

### Object Structure
The parsers should return OpenStruct or similar objects that allow dot notation access while being flexible enough to handle varying response structures. This provides a clean API for downstream consumers.

### Error Handling Strategy
When JSON parsing fails, the parser should raise a JSON::ParserError that can be caught by the generator to trigger a retry. For validation errors (missing fields, invalid values), the parser should raise descriptive custom errors.

### Integration Points
The parsers will be called within the pipeline flow after the LLM generators and before the storage services. They receive a Pipeline::Context object and must update it with the parsed_response.

## Technical Considerations

1. **Base Parser Class**: Consider implementing a base parser class with common functionality like JSON parsing, error logging, and validation helpers
2. **Validation Library**: Could use ActiveModel validations or a lightweight validation approach
3. **Testing**: Each parser needs comprehensive test coverage including happy path, malformed JSON, missing fields, and edge cases
4. **Performance**: Parsing should be synchronous and efficient as it's in the critical path
5. **Logging**: Use structured logging for better debugging of parsing failures

## Success Metrics

1. 100% of valid JSON responses are successfully parsed
2. 100% of invalid JSON responses raise appropriate errors for retry
3. 0% of invalid data makes it past validation
4. All three parsers maintain consistent interfaces and behavior
5. Integration with existing pipeline requires no changes to other components

## Open Questions

1. Should we implement a base parser class to reduce code duplication?
- Yes, but only as a refactoring step at the end and only if it does not make the code harder to understand.
2. What specific validation rules should we enforce beyond required fields?
- The validation rules are defined on the models and also specified in the /prompts. If the JSON returned by the LLM isn't in the format specified in the prompts, the parser should raise a descriptive error.
3. Should we implement any data transformation (e.g., score normalization)?
- No.
4. How should we handle extra/unexpected fields in the JSON response?
- Extra data should be ignored.
5. Should parsed objects be frozen/immutable after creation?
- Does not matter, so no.