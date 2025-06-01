# Task List: Pipeline Storage Services

## Relevant Files

- `app/services/pipeline/storage/rubric_service.rb` - Service for persisting rubric data with criteria and levels
- `test/services/pipeline/storage/rubric_service_test.rb` - Unit tests for RubricService
- `app/services/pipeline/storage/student_work_service.rb` - Service for persisting student feedback and assessments
- `test/services/pipeline/storage/student_work_service_test.rb` - Unit tests for StudentWorkService
- `app/services/pipeline/storage/assignment_summary_service.rb` - Service for persisting class-wide insights
- `test/services/pipeline/storage/assignment_summary_service_test.rb` - Unit tests for AssignmentSummaryService
- `app/models/pipeline/context/rubric.rb` - Context object that will be updated with saved rubric
- `app/models/pipeline/context/student_work.rb` - Context object that will be updated with saved feedback
- `app/models/pipeline/context/assignment_summary.rb` - Context object that will be updated with saved summary

### Notes

- All services should follow the existing pipeline pattern with `.call(context:)` interface
- Use Rails' built-in transaction support for atomic operations
- Leverage ActiveRecord's `create!` to ensure exceptions on validation failures
- Run tests with `bin/rails test test/services/pipeline/storage/`

## Tasks

| Task ID | Subtask ID | Workstream | Status | Task Title | Task Description | Details |
| --- | --- | --- | --- | --- | --- | --- |
| 1.0 | 1.1 | ws1 | 🟢 completed | Create storage service directory structure | Create the app/services/pipeline/storage directory | [Details 1.1](#task-1.1) |
| 1.0 | 1.2 | ws1 | 🟢 completed | Create test directory structure | Create the test/services/pipeline/storage directory | [Details 1.2](#task-1.2) |
| 2.0 | 2.1 | ws1 | 🟢 completed | Create RubricService class skeleton | Define the basic class structure with call method | [Details 2.1](#task-2.1) |
| 2.0 | 2.2 | ws1 | 🟢 completed | Implement rubric creation logic | Add transaction block and rubric record creation | [Details 2.2](#task-2.2) |
| 2.0 | 2.3 | ws1 | 🟢 completed | Implement criteria creation logic | Add logic to create criterion records with positioning | [Details 2.3](#task-2.3) |
| 2.0 | 2.4 | ws1 | 🟢 completed | Implement levels creation logic | Add logic to create level records for each criterion | [Details 2.4](#task-2.4) |
| 2.0 | 2.5 | ws1 | 🟢 completed | Add error handling and context update | Handle validation errors and update context with saved rubric | [Details 2.5](#task-2.5) |
| 2.0 | 2.6 | ws1 | 🟢 completed | Write RubricService tests | Create comprehensive test suite for RubricService | [Details 2.6](#task-2.6) |
| 3.0 | 3.1 | ws1 | 🟢 completed | Create StudentWorkService class skeleton | Define the basic class structure with call method | [Details 3.1](#task-3.1) |
| 3.0 | 3.2 | ws1 | 🟢 completed | Implement student work update logic | Add transaction block and update student work qualitative feedback | [Details 3.2](#task-3.2) |
| 3.0 | 3.3 | ws1 | 🟢 completed | Implement feedback items creation | Add logic to create strength and opportunity feedback items | [Details 3.3](#task-3.3) |
| 3.0 | 3.4 | ws1 | 🟢 completed | Implement checks creation | Add logic to create student work check records | [Details 3.4](#task-3.4) |
| 3.0 | 3.5 | ws1 | 🟢 completed | Implement criterion levels creation | Add logic to create student criterion level associations | [Details 3.5](#task-3.5) |
| 3.0 | 3.6 | ws1 | 🟢 completed | Add error handling and context update | Handle validation errors and update context with saved data | [Details 3.6](#task-3.6) |
| 3.0 | 3.7 | ws1 | 🟢 completed | Write StudentWorkService tests | Create comprehensive test suite for StudentWorkService | [Details 3.7](#task-3.7) |
| 4.0 | 4.1 | ws1 | 🟢 completed | Create AssignmentSummaryService class skeleton | Define the basic class structure with call method | [Details 4.1](#task-4.1) |
| 4.0 | 4.2 | ws1 | 🟢 completed | Implement summary creation logic | Add transaction block and create assignment summary record | [Details 4.2](#task-4.2) |
| 4.0 | 4.3 | ws1 | 🟢 completed | Implement summary feedback items | Add logic to create class-wide feedback items | [Details 4.3](#task-4.3) |
| 4.0 | 4.4 | ws1 | 🟢 completed | Update student work count | Add logic to calculate and update student work count | [Details 4.4](#task-4.4) |
| 4.0 | 4.5 | ws1 | 🟢 completed | Add error handling and context update | Handle validation errors and update context with saved summary | [Details 4.5](#task-4.5) |
| 4.0 | 4.6 | ws1 | 🟢 completed | Write AssignmentSummaryService tests | Create comprehensive test suite for AssignmentSummaryService | [Details 4.6](#task-4.6) |
| 5.0 | 5.1 | ws1 | 🟢 completed | Create integration test | Test all storage services working together in a pipeline | [Details 5.1](#task-5.1) |
| 5.0 | 5.2 | ws1 | 🟢 completed | Update pipeline documentation | Document how storage services integrate with pipelines | [Details 5.2](#task-5.2) |
| 5.0 | 5.3 | ws1 | 🟢 completed | Run full test suite | Ensure all tests pass and no regressions | [Details 5.3](#task-5.3) |

## Implementation plan

### Task 1.1
Create the directory structure for the storage services:
- Create `app/services/pipeline/storage/` directory if it doesn't exist
- This will house all three storage service classes

### Task 1.2
Create the test directory structure:
- Create `test/services/pipeline/storage/` directory if it doesn't exist
- This will house all test files for the storage services

### Task 2.1
Create the basic RubricService class:
```ruby
module Pipeline
  module Storage
    class RubricService
      def self.call(context:)
        # Implementation will go here
        context
      end
    end
  end
end
```

### Task 2.2
Implement the main rubric creation logic:
- Extract assignment from context
- Extract parsed rubric data from context
- Use ActiveRecord transaction to ensure atomicity
- Create Rubric record using `create!` to raise on validation errors

### Task 2.3
Within the transaction, implement criteria creation:
- Iterate through parsed criteria data
- Create Criterion records with proper positioning (use index for position)
- Associate each criterion with the rubric
- Use `create!` to ensure validation errors are raised

### Task 2.4
Within the transaction, implement level creation for each criterion:
- For each criterion, iterate through its levels
- Create Level records with proper positioning
- Associate each level with its criterion
- Use `create!` for validation error handling

### Task 2.5
Add error handling and context updates:
- Wrap transaction in begin/rescue block
- On success, update context with `saved_rubric`
- On validation errors, let them propagate (fail fast)
- Ensure context is always returned

### Task 2.6
Write comprehensive tests for RubricService:
- Test successful rubric creation with criteria and levels
- Test transaction rollback on validation errors
- Test context is updated with saved rubric
- Test proper positioning of criteria and levels
- Use fixtures or factories for test data

### Task 3.1
Create the basic StudentWorkService class:
```ruby
module Pipeline
  module Storage
    class StudentWorkService
      def self.call(context:)
        # Implementation will go here
        context
      end
    end
  end
end
```

### Task 3.2
Implement student work update logic:
- Extract student work from context
- Extract parsed feedback data from context
- Use ActiveRecord transaction
- Update student work with qualitative feedback using `update!`

### Task 3.3
Within the transaction, implement feedback item creation:
- Iterate through strengths and opportunities
- Create FeedbackItem records with proper type
- Associate with the student work
- Use `create!` for validation handling

### Task 3.4
Within the transaction, implement check creation:
- Iterate through parsed checks data
- Create StudentWorkCheck records
- Set type, score, and explanation
- Use `create!` for validation

### Task 3.5
Within the transaction, implement criterion level associations:
- Iterate through criterion assessments
- Create StudentCriterionLevel join records
- Link student work, criterion, and selected level
- Include explanation text
- Use `create!` for validation

### Task 3.6
Add error handling and context updates:
- Wrap transaction in begin/rescue block
- On success, update context with `saved_feedback`
- Let validation errors propagate
- Ensure context is always returned

### Task 3.7
Write comprehensive tests for StudentWorkService:
- Test successful feedback persistence
- Test all child record types are created
- Test transaction rollback on any validation error
- Test context is updated properly
- Test individual student work processing (not bulk)

### Task 4.1
Create the basic AssignmentSummaryService class:
```ruby
module Pipeline
  module Storage
    class AssignmentSummaryService
      def self.call(context:)
        # Implementation will go here
        context
      end
    end
  end
end
```

### Task 4.2
Implement assignment summary creation:
- Extract assignment from context
- Extract parsed summary data from context
- Use ActiveRecord transaction
- Create AssignmentSummary record with insights text

### Task 4.3
Within the transaction, implement feedback item creation:
- Iterate through class-wide strengths and opportunities
- Create FeedbackItem records associated with the summary
- Set proper type for each item
- Use `create!` for validation

### Task 4.4
Within the transaction, update student work count:
- Calculate count from processed student works
- Update the student_work_count field on summary
- This provides quick access to class size

### Task 4.5
Add error handling and context updates:
- Wrap transaction in begin/rescue block
- On success, update context with `saved_summary`
- Let validation errors propagate
- Ensure context is always returned

### Task 4.6
Write comprehensive tests for AssignmentSummaryService:
- Test successful summary creation with feedback items
- Test student work count is set correctly
- Test transaction rollback on validation errors
- Test context is updated with saved summary
- Test association with assignment

### Task 5.1
Create an integration test that simulates the full pipeline:
- Set up contexts with parsed data for all three services
- Call services in sequence (rubric → student work → summary)
- Verify all records are created properly
- Test that contexts are passed between services correctly

### Task 5.2
Update documentation:
- Add comments to each service explaining usage
- Document expected context structure
- Add examples of how services integrate with pipelines
- Update any existing pipeline documentation

### Task 5.3
Run the complete test suite:
- Execute `bin/rails test test/services/pipeline/storage/`
- Fix any failing tests
- Ensure no regressions in existing functionality
- Verify all new tests pass