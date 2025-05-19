# Changelog
All notable changes to this project will be documented in this file.

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