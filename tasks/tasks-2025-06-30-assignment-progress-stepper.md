# Assignment Progress Stepper Implementation Tasks

**Date:** 2025-01-14  
**PRD Reference:** `docs/prds/2025-06-30-assignment-progress-stepper.md`  
**Feature:** Assignment Progress Stepper

## Relevant Files

- `app/models/processing_step.rb` - Model to track assignment processing progress steps
- `test/models/processing_step_test.rb` - Unit tests for ProcessingStep model
- `app/controllers/assignments/processing_steps_controller.rb` - API controller for progress step endpoints
- `test/controllers/assignments/processing_steps_controller_test.rb` - Unit tests for processing steps controller
- `app/services/assignment_processor.rb` - Modified to create ProcessingStep records instead of broadcasting
- `test/services/assignment_processor_test.rb` - Updated tests for assignment processor changes
- `app/views/assignments/_progress_stepper.html.erb` - Visual progress stepper component partial
- `app/javascript/controllers/assignment_progress_controller.js` - Stimulus controller for polling and progress updates
- `config/routes.rb` - Routes for processing steps API endpoint
- `db/migrate/[timestamp]_create_processing_steps.rb` - Migration to create processing_steps table

### Notes

- Unit tests should typically be placed alongside the code files they are testing (e.g., `my_class.rb` and `my_class_test.rb` in the `test` directory).
- Use `bin/rails test [optional/path/to/test/file]` to run tests. Running without a path executes all tests.

## Tasks

| Task ID | Subtask ID | Workstream | Status | Task Title | Task Description | Details |
| --- | --- | --- | --- | --- | --- | --- |
| 1.0 | 1.1 | ws1 | 🟡 pending | Create ProcessingStep Migration | Generate and configure database migration for processing_steps table | [Details 1.1](#task-11) |
| 1.0 | 1.2 | ws1 | 🟡 pending | Implement ProcessingStep Model | Create model with validations, enums, and associations | [Details 1.2](#task-12) |
| 1.0 | 1.3 | ws1 | 🟡 pending | Write ProcessingStep Model Tests | Create comprehensive test coverage for model behavior | [Details 1.3](#task-13) |
| 2.0 | 2.1 | ws1 | 🟡 pending | Analyze Authentication Requirements | Study existing authentication patterns for API endpoint security | [Details 2.1](#task-21) |
| 2.0 | 2.2 | ws1 | 🟡 pending | Create Processing Steps Controller | Implement REST API controller for processing step retrieval | [Details 2.2](#task-22) |
| 2.0 | 2.3 | ws1 | 🟡 pending | Add Processing Steps Routes | Configure routing for the new API endpoint | [Details 2.3](#task-23) |
| 2.0 | 2.4 | ws1 | 🟡 pending | Write Controller Tests | Create comprehensive test coverage for API endpoint | [Details 2.4](#task-24) |
| 3.0 | 3.1 | ws2 | 🟡 pending | Analyze Broadcast Infrastructure | Identify all broadcast and turbo stream related files for removal | [Details 3.1](#task-31) |
| 3.0 | 3.2 | ws2 | 🟡 pending | Update AssignmentProcessor | Modify service to create ProcessingStep records instead of broadcasting | [Details 3.2](#task-32) |
| 3.0 | 3.3 | ws2 | 🟡 pending | Remove Broadcast Services | Safely remove broadcast and turbo stream infrastructure | [Details 3.3](#task-33) |
| 3.0 | 3.4 | ws2 | 🟡 pending | Update AssignmentProcessor Tests | Modify tests to verify ProcessingStep creation instead of broadcasts | [Details 3.4](#task-34) |
| 4.0 | 4.1 | ws3 | 🟡 pending | Create Progress Stimulus Controller | Implement Stimulus controller for polling and UI state management | [Details 4.1](#task-41) |
| 4.0 | 4.2 | ws3 | 🟡 pending | Integrate Controller with Assignment View | Connect Stimulus controller to existing assignment show page | [Details 4.2](#task-42) |
| 4.0 | 4.3 | ws3 | 🟡 pending | Add Cleanup Job for Old ProcessingSteps | Create background job to clean up old processing step records | [Details 4.3](#task-43) |

## Implementation Plan

### Task 1.1
Create a Rails migration for the `processing_steps` table with the following schema:
- `assignment_id` (foreign key, indexed)
- `step_name` (enum: assignment_saved, creating_rubric, grading_work, generating_summary)
- `started_at` (timestamp, indexed for cleanup queries)
- `ended_at` (timestamp, nullable)
- `status` (enum: pending, in_progress, completed, failed)
- `created_at` and `updated_at` timestamps

**Testing Strategy**: Run migration against test database and verify schema matches requirements.

### Task 1.2
Implement the ProcessingStep model with:
- Belongs_to association with Assignment
- Enum definitions for `step_name` and `status` 
- Validations for required fields and enum values
- Scopes for querying by status and assignment
- Class methods for step progression logic

**Testing Strategy**: Write unit tests first for validations, associations, and class methods before implementation.

### Task 1.3
Create comprehensive test coverage for ProcessingStep model including:
- Validation tests for all required fields and enums
- Association tests with Assignment model
- Scope tests for filtering and querying
- Edge cases for step progression and status changes

**Testing Strategy**: Follow TDD approach - write failing tests first, then implement model features to make tests pass.

### Task 2.1
Analyze the existing authentication system by examining:
- `Authentication` concern methods (`require_authentication`, `authenticate_user!`)
- Session-based auth with signed cookies and `Current.session`
- How other API endpoints handle authentication in the app
- Determine if new endpoint should use `authenticate_user!` for JSON responses

**Testing Strategy**: Review existing controller tests to understand authentication testing patterns.

### Task 2.2
Create `Assignments::ProcessingStepsController` with:
- Inherit from ApplicationController to get authentication concern
- `show` action that returns JSON of processing steps for an assignment
- Proper error handling for missing assignments or unauthorized access
- Response format: `{ steps: [...], current_step: "...", completed: boolean }`

**Testing Strategy**: Write controller tests first, including authentication scenarios, then implement controller.

### Task 2.3
Add route configuration in `config/routes.rb`:
- Nested resource under assignments: `resources :assignments do resources :processing_steps, only: [:show] end`
- Follow existing routing patterns in the application
- Ensure route follows RESTful conventions

**Testing Strategy**: Verify routes with `bin/rails routes | grep processing` and test route helpers.

### Task 2.4
Create comprehensive controller tests covering:
- Successful processing step retrieval with proper authentication
- Authentication failure scenarios (redirects or JSON error responses)
- Assignment not found error handling
- Response format validation
- Integration with ProcessingStep model

**Testing Strategy**: Use TDD approach - write failing tests first, then implement controller features.

### Task 3.1
Systematically identify all broadcast/turbo stream infrastructure for safe removal:
- Inventory all files: search for `broadcast`, `turbo`, `stream` in codebase
- Analyze `ProgressBroadcastService` and its usage
- Find turbo stream view templates and partials
- Identify broadcast-related methods in controllers and services
- Document dependencies and safe removal order

**Testing Strategy**: Create removal plan with rollback steps before making changes.

### Task 3.2
Update `AssignmentProcessor` service to:
- Replace broadcast calls with ProcessingStep record creation
- Create "assignment_saved" step at start
- Create "creating_rubric" step before rubric generation
- Create "grading_work" step before student work processing  
- Create "generating_summary" step before summary generation
- Update step status to "completed" when each phase finishes
- Handle failures by marking steps as "failed"

**Testing Strategy**: Write tests to verify ProcessingStep records are created correctly, then update service implementation.

### Task 3.3
Safely remove broadcast infrastructure:
- Remove `ProgressBroadcastService` and related broadcast service files
- Remove turbo stream view templates and partials
- Remove broadcast-related controller methods and calls
- Clean up any broadcast-related JavaScript or Stimulus controllers
- Update any remaining references to use new progress system

**Testing Strategy**: Run full test suite after each removal to ensure no broken dependencies.

### Task 3.4
Update `AssignmentProcessor` tests to:
- Remove broadcast expectation tests
- Add ProcessingStep creation verification tests
- Test proper step progression through processing phases
- Test error scenarios create failed ProcessingStep records
- Ensure all processing phases have corresponding ProcessingStep coverage

**Testing Strategy**: Update existing tests to verify new behavior, run tests to ensure coverage maintained.

### Task 4.1
Create Stimulus controller `assignment_progress_controller.js` with:
- `connect()` method to start polling when controller connects
- `disconnect()` method to cleanup polling intervals
- `poll()` method to fetch progress from API endpoint
- `updateProgress()` method to update UI based on API response
- Error handling for API failures
- Stop polling when processing completes

**Testing Strategy**: Manual testing with assignment processing, verify polling starts/stops correctly.

### Task 4.2
Integrate the Stimulus controller with the assignment show page:
- Add `data-controller="assignment-progress"` to progress stepper container
- Add `data-assignment-id` attribute for API endpoint construction
- Ensure existing progress stepper UI works with new polling data
- Test progressive enhancement if JavaScript fails

**Testing Strategy**: Test with JavaScript enabled/disabled, verify graceful degradation.

### Task 4.3
Create background job to clean up old ProcessingStep records:
- Generate job class `ProcessingStepCleanupJob`
- Delete ProcessingStep records older than 30 days
- Add to recurring job schedule
- Include logging and monitoring for cleanup activity

**Testing Strategy**: Write job tests to verify cleanup logic, test scheduling configuration. 