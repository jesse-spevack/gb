# Changelog
All notable changes to this project will be documented in this file.

## [2025-05-24]
- Implemented `ProcessingResult` PORO class in `app/models/processing_result.rb` for consistent pipeline result handling
- Created `ProcessingPipeline` orchestration class in `app/services/processing_pipeline.rb` implementing the 5-step processing workflow
- Designed ProcessingPipeline to handle: collect data → build prompt → send to LLM → parse response → store result
- Added comprehensive error handling with proper logging, metrics collection, and failure recovery
- Implemented status management and real-time broadcasting throughout pipeline execution
- Created extensive test coverage following TDD approach with 9 comprehensive tests for ProcessingPipeline
- Built mock classes for all processing components (MockPromptTemplate, MockResponseParser, MockStorageService, MockBroadcaster, MockStatusManager)
- Added 8 comprehensive tests for ProcessingResult covering all initialization scenarios and helper methods
- Followed Rails error handling guidelines with natural exception propagation and direct finder usage
- Applied Rails code organization principles: method simplicity, clean service patterns, single responsibility
- Integrated timing and metrics collection with existing ProcessingTask infrastructure
- Completed Task 44: "Create ProcessingPipeline class" with full test coverage and documentation
- All 227 tests passing with new implementation fully integrated into existing codebase

## [2025-05-23]
- Implemented `ProcessingTaskConfiguration` PORO for clean encapsulation of processing components
- Created `ProcessingTask` class for managing LLM processing task configuration and state
- Added validation for required components (prompt_template, response_parser, storage_service, broadcaster, status_manager)
- Implemented process type validation against VALID_PROCESS_TYPES (generate_rubric, grade_student_work, generate_summary_feedback)
- Added timing methods (mark_started, mark_completed, processing_time_ms) for performance tracking
- Implemented metric recording system with indifferent access for flexible metric tracking
- Created comprehensive test coverage for both ProcessingTaskConfiguration and ProcessingTask classes
- Designed classes to work seamlessly with upcoming ProcessingPipeline (task 44)
- Followed PORO simplicity principles with focused responsibilities and minimal methods
- Implemented `LLM::CostTracker` service class for recording LLM usage data and costs to the database
- Created comprehensive LLMUsageRecord model with polymorphic trackable associations and proper validations
- Major database schema improvements:
  - Renamed LLMRequest model to LLMUsageRecord for better clarity
  - Added `llm_model` field for exact model tracking (e.g., "claude-3-5-haiku-20241022")
  - Changed provider enum from `llm` to `llm_provider` with values `:google`, `:anthropic`
  - Removed `prompt` column to ensure PII compliance and reduce storage overhead
  - Added performance indexes on `llm_model`, `created_at`, `user_id`, and `trackable`
- Enhanced CostTracker to use centralized `LLM::ModelsConfig` instead of hardcoded regex patterns for model-to-provider mapping
- Added comprehensive error handling with custom `UnknownModelError` for unsupported models
- Integrated automatic cost calculation using existing `LLM::CostCalculator` with micro-USD precision
- Created extensive test coverage including unit tests, integration tests, and error scenarios
- Updated integration tests to remove deprecated prompt parameter and fix cost calculations to match actual model pricing
- Added complete documentation in `app/lib/llm/README.md` with usage examples and configuration guidance
- Ensured full backward compatibility while improving maintainability and extensibility

## [2025-05-22]
- Implemented `LLM::CostCalculator` class for calculating API costs based on token usage
- Added comprehensive LLM model configuration system with centralized YAML-based pricing data
- Updated model catalog with latest Anthropic models (Claude Opus 4, Sonnet 4, Sonnet 3.7) and Google models (Gemini 2.5 Flash Preview, 2.5 Pro Preview, 2.0 Flash-Lite)
- Added descriptive documentation for each model explaining optimal use cases and capabilities
- Implemented explicit default model selection system using `default: true` flags in configuration
- Changed default models to most cost-effective options: Claude 3.5 Haiku for Anthropic ($0.80/$4.00 per million tokens) and Gemini 2.0 Flash-Lite for Google ($0.075/$0.30 per million tokens)
- Created comprehensive YAML validation tests ensuring configuration integrity, required fields, proper data types, and exactly one default model per provider
- Enhanced `LLM::ModelsConfig` module with memoized configuration loading and default model resolution
- Updated both AnthropicClient and GoogleClient to use centralized YAML configuration instead of hardcoded model constants
- Added cost calculation support for all models with micro-USD precision for accurate billing tracking
- Removed unused `reload!` method to clean up codebase

## [2025-05-19]
- Integrated RetryHandler with HTTP requests in LLM client for improved resilience
- Enhanced RetryHandler to handle network-level exceptions (timeouts, connection issues)
- Updated RetryHandler API with consistent method naming (changed `with_retry` to `with_retries`)
- Optimized interaction between CircuitBreaker and RetryHandler for proper error handling
- Applied layered resilience pattern with CircuitBreaker (outer) → RetryHandler (inner) → API call

## [2025-05-18]
- Enhanced `LLMResponse.from_google` to extract and use the actual model version from Google API responses
- Fixed deprecation warning by updating `Net::HTTPServerException` to `Net::HTTPServerError` in LLM client error handling
- Ensured proper handling of Google Gemini API response structure in the LLM client
- Implemented `LLM::ClientFactory` with task-specific methods for selecting appropriate LLM providers
- Added factory methods for rubric generation (Google), student work feedback (Anthropic), and assignment summary feedback (Anthropic)
- Implemented `LLM::RetryHandler` with exponential backoff and jitter for handling transient API failures

## [2025-05-17]
- Created `Rubric::CreationService` to handle rubric creation for assignments
- Implemented `AssignmentJob` for background processing of assignments
- Updated `Assignments::CreationService` to create rubrics and enqueue assignment processing jobs
- Adopted exception-based error handling pattern instead of result objects
- Added documentation to standardize coding conventions across the application
- Improved test structure with combined assertions and focused test cases
- Created shared admin navigation links partial for consistent UI across mobile and desktop sidebars

## [2025-05-11]
- Improved error handling in the `Assignments::CreationService` with a structured Result object that includes success state and error messages
- Enhanced the assignments controller with proper authorization checks for show and destroy actions
- Added before_action filters in AssignmentsController to set assignment and verify ownership
- Updated controller actions to properly handle service results with appropriate flash messages and status codes
- Implemented code to leverage Rails 8's `params.expect` for type-safe parameter handling
- Cleaned up debugging logs in the document picker controller
- Added default scope to Assignment model to order by creation date (newest first)
- Redesigned the assignments index view to display assignments with folder icons and links
- Added service objects for bulk creation of selected documents and student works
- Expanded routing to include show, create, and destroy actions for assignments

## [2025-05-10]
- Fixed Google Picker integration by enhancing token refresh logic in `Google::TokenService` to handle nil access tokens
- Updated environment variable loading from Kamal secrets to properly map credentials
- Refactored credential handling for Google APIs to improve reliability
- Removed dotenv gem
- Cleaned up debugging logs and console output for production readiness
- Created and implemented `rubric_toggle_controller.js` to enable toggling between AI-generated and manually entered rubrics
- Refactored toggle controller to use Stimulus CSS Classes API for better separation of concerns and maintainability
- Added accessibility enhancements including ARIA attributes and screen reader announcements

## [2025-05-07]
- Added Google::TokenService with methods for creating Google Drive and Docs clients, and accessing access tokens.
- Added tests for Google::TokenService.
- Added Google::DriveService with method for fetching document content.
- Added tests for Google::DriveService.
- Added Google::DocsService with method for appending content to document. This service only logs.
- Added tests for Google::DocsService.
- Added Google::PickerService with method for generating picker token, oauth token, and app id.
- Added tests for Google::PickerService.

## [2025-05-05]
- Updated the landing page copy to better reflect the value of GradeBot.
- Added the assignment form

## [2025-05-04]

### Added
- Added StudentWorkCheck model with validations for student work, check type, score, and explanation.
- Added AssignmentSummary model with validations for assignment, student work count, and qualitative insights.
- Added LLMRequest model with validations for trackable, user, llm, request type, token count, micro USD, and prompt.
- Added ProcessingMetric model with validations for processable, completed at, duration ms, and status.
- Added new home page with Google sign-in button.

## [2025-05-03]

### Added
- Restored tailwind classes.
- Added favicon.
- Updated `application.html.erb` and `home/index.html.erb` with tailwind classes.
- Added Assignment model with validations for title, instructions, grade level, and feedback tone.
- Added SelectedDocument model with validations for assignment, google_doc_id, title, and url.
- Added "Just finished" to home page.
- Added Rubric model with validations for assignment.
- Added Criterion model with validations for rubric, title, description, and position.
- Added Level model with validations for criterion, title, description, and position.
- Added StudentWork model with validations for assignment and selected document.
- Added StudentCriterionLevel model with validations for student work, explanation, criterion, and level.
- Added FeedbackItem model.

### Removed
- Removed all classes from `application.html.erb` and `home/index.html.erb`, created backups of each.
- Added remote build to `deploy.yml`. - THIS FIXED THE STYLES

## [2025-05-02]

### Added

- Created `UserToken` model with `access_token`, `refresh_token`, `expires_at`, validations, `default_scope`, and `most_recent_for` method.
- Added migration to create `user_tokens` table with references to `users` and timestamps.
- Added tests for `UserToken` covering `most_recent_for`, validations, default scope ordering, `expired?`, and `will_expire_soon?` methods.
- Added `Current` module to manage the current session and user.
- Added `Authentication` concern to handle authentication.
- Added `SessionsController` to handle session creation and destruction.
- Added `Authorization::UserService` to handle user authentication.

## [2025-05-01]

### Added

- Initial commit
- Root route to "coming soon" page
- Prefixes for ids
- Added tasks.json
- Generated User model with validations for email, name, and google_uid
- Added test fixtures for admin and teacher users
- Created bin/check script for running Brakeman, Rubocop, and Rails tests
- Created Session model with user, user_agent, and ip_address attributes
- Added Session model validations and tests
- Added test fixtures for user sessions