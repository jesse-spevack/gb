## Relevant Files

- `app/services/assignment_processor.rb` - Main orchestrator class that coordinates all three pipelines ✓
- `test/services/assignment_processor_test.rb` - Unit tests for the AssignmentProcessor ✓
- `app/jobs/assignment_job.rb` - Background job that invokes the AssignmentProcessor (existing, needs modification)
- `app/services/rubric_pipeline.rb` - Existing pipeline for rubric generation
- `app/services/student_work_feedback_pipeline.rb` - Existing pipeline for student feedback
- `app/services/assignment_summary_pipeline.rb` - Existing pipeline for assignment summary
- `app/services/broadcast_service.rb` - Existing service for broadcasting progress updates
- `app/services/status_manager_factory.rb` - Existing factory for managing assignment status
- `app/services/assignments/progress_calculator.rb` - Existing service for calculating progress
- `app/models/processing_metric.rb` - Existing model for tracking LLM call metrics

### Notes

- Unit tests should be placed in the `test` directory following the existing pattern
- Use `bin/rails test [optional/path/to/test/file]` to run tests. Running without a path executes all tests
- The AssignmentProcessor will be invoked by the existing AssignmentJob, so integration testing will be important
- Follow TDD principles - write tests first, then implement to make them pass

## Tasks

| Task ID | Subtask ID | Workstream | Status | Task Title | Task Description | Details |
| --- | --- | --- | --- | --- | --- | --- |
| 1.0 | 1.1 | ws1 | 🟢 completed | Write tests for AssignmentProcessor initialization | Create test file and write tests for class initialization with assignment ID | [Details 1.1](#task-1.1) |
| 1.0 | 1.2 | ws1 | 🟢 completed | Implement AssignmentProcessor class initialization | Create the class with initialize method and basic structure | [Details 1.2](#task-1.2) |
| 1.0 | 1.3 | ws1 | 🟢 completed | Write tests for process method interface | Test the main public interface method | [Details 1.3](#task-1.3) |
| 1.0 | 1.4 | ws1 | 🟢 completed | Implement process method skeleton | Create the main process method with basic structure | [Details 1.4](#task-1.4) |
| 2.0 | 2.1 | ws1 | 🟢 completed | Write tests for rubric pipeline execution | Test that RubricPipeline is called correctly | [Details 2.1](#task-2.1) |
| 2.0 | 2.2 | ws1 | 🟢 completed | Implement rubric pipeline execution | Execute RubricPipeline and capture results | [Details 2.2](#task-2.2) |
| 2.0 | 2.3 | ws1 | 🟢 completed | Write tests for student feedback pipeline execution | Test sequential processing of student work | [Details 2.3](#task-2.3) |
| 2.0 | 2.4 | ws1 | 🟢 completed | Implement student feedback pipeline execution | Process each student work sequentially with rubric context | [Details 2.4](#task-2.4) |
| 2.0 | 2.5 | ws1 | 🟢 completed | Write tests for assignment summary pipeline execution | Test summary generation with aggregated contexts | [Details 2.5](#task-2.5) |
| 2.0 | 2.6 | ws1 | 🟢 completed | Implement assignment summary pipeline execution | Execute summary pipeline with all student contexts | [Details 2.6](#task-2.6) |
| 3.0 | 3.1 | ws1 | 🟢 completed | Write tests for progress broadcasting | Test broadcast messages at each pipeline stage | [Details 3.1](#task-3.1) |
| 3.0 | 3.2 | ws1 | 🟢 completed | Implement pipeline-level progress broadcasting | Send progress updates for each major milestone | [Details 3.2](#task-3.2) |
| 3.0 | 3.3 | ws1 | 🟢 completed | Write tests for status updates | Test assignment status changes during processing | [Details 3.3](#task-3.3) |
| 3.0 | 3.4 | ws1 | 🟢 completed | Implement status management | Update assignment status using StatusManagerFactory | [Details 3.4](#task-3.4) |
| 3.0 | 3.5 | ws1 | 🟢 completed | Write tests for progress calculation | Test overall progress percentage calculation | [Details 3.5](#task-3.5) |
| 3.0 | 3.6 | ws1 | 🟢 completed | Implement progress percentage calculation | Use ProgressCalculator for completion tracking | [Details 3.6](#task-3.6) |
| 4.0 | 4.1 | ws1 | 🟢 completed | Write tests for critical pipeline failures | Test handling of RubricPipeline and AssignmentSummaryPipeline failures | [Details 4.1](#task-4.1) |
| 4.0 | 4.2 | ws1 | 🟢 completed | Implement critical pipeline error handling | Mark assignment as failed when critical pipelines fail | [Details 4.2](#task-4.2) |
| 4.0 | 4.3 | ws1 | 🟢 completed | Write tests for student feedback failures | Test continuing processing when individual student feedback fails | [Details 4.3](#task-4.3) |
| 4.0 | 4.4 | ws1 | 🟢 completed | Implement student feedback error handling | Continue processing remaining students on individual failures | [Details 4.4](#task-4.4) |
| 4.0 | 4.5 | ws1 | 🟢 completed | Write tests for processing metrics tracking | Test that ProcessingMetric records are created | [Details 4.5](#task-4.5) |
| 4.0 | 4.6 | ws1 | 🟢 completed | Ensure processing metrics are saved | Verify all pipelines save metrics correctly | [Details 4.6](#task-4.6) |
| 5.0 | 5.1 | ws1 | 🟢 completed | Write tests for AssignmentJob integration | Test that AssignmentJob calls AssignmentProcessor | [Details 5.1](#task-5.1) |
| 5.0 | 5.2 | ws1 | 🟢 completed | Modify AssignmentJob to use AssignmentProcessor | Replace existing logic with AssignmentProcessor call | [Details 5.2](#task-5.2) |
| 5.0 | 5.3 | ws1 | 🟢 completed | Write integration tests for full workflow | Test complete assignment processing from job to completion | [Details 5.3](#task-5.3) |
| 5.0 | 5.4 | ws1 | 🟢 completed | Handle edge cases | Test and handle zero student submissions and other edge cases | [Details 5.4](#task-5.4) |

## Implementation plan

### Task 1.1
**Write tests for AssignmentProcessor initialization**

Create `test/services/assignment_processor_test.rb` and write tests for:
- Initializing with a valid assignment ID
- Storing the assignment instance
- Raising error for invalid assignment ID
- Setting up instance variables for pipeline results

Testing strategy: Use minitest with fixtures for test data

### Task 1.2
**Implement AssignmentProcessor class initialization**

Create `app/services/assignment_processor.rb` with:
- Initialize method that accepts assignment_id
- Find and store the assignment record
- Initialize instance variables for tracking results
- Basic class structure following Rails conventions

### Task 1.3
**Write tests for process method interface**

Add tests for:
- Process method returns a result object
- Process method can be called without arguments
- Result object contains success status and data

### Task 1.4
**Implement process method skeleton**

Implement:
- Public `process` method
- Basic result structure
- Method stubs for private pipeline execution methods
- Ensure method returns appropriate result object

### Task 2.1
**Write tests for rubric pipeline execution**

Test that:
- RubricPipeline is instantiated with correct assignment
- Pipeline process method is called
- Results are captured and stored
- Context is extracted for use in student pipelines

### Task 2.2
**Implement rubric pipeline execution**

Implement private method to:
- Create RubricPipeline instance
- Call process and capture results
- Extract rubric context from results
- Store results for aggregation

### Task 2.3
**Write tests for student feedback pipeline execution**

Test that:
- StudentWorkFeedbackPipeline is called for each student work
- Pipelines receive rubric context
- Processing happens sequentially (not in parallel)
- Results are collected for each student

### Task 2.4
**Implement student feedback pipeline execution**

Implement private method to:
- Iterate through assignment.student_works
- Create pipeline instance for each with rubric context
- Process sequentially and collect results
- Build array of student contexts for summary

### Task 2.5
**Write tests for assignment summary pipeline execution**

Test that:
- AssignmentSummaryPipeline receives all student contexts
- Pipeline is only called after all student feedback completes
- Results are captured correctly

### Task 2.6
**Implement assignment summary pipeline execution**

Implement private method to:
- Create AssignmentSummaryPipeline with aggregated contexts
- Process and capture results
- Add to final result aggregation

### Task 3.1
**Write tests for progress broadcasting**

Test that BroadcastService is called with:
- "Creating rubric" message
- "Generating student feedback (X of Y)" messages
- "Creating assignment summary" message
- Correct assignment and channel parameters

### Task 3.2
**Implement pipeline-level progress broadcasting**

Add broadcasting calls:
- Before each pipeline execution
- Update student progress counter during iteration
- Use existing BroadcastService infrastructure
- Include appropriate progress messages

### Task 3.3
**Write tests for status updates**

Test that assignment status changes to:
- 'processing' when starting
- 'completed' on success
- 'failed' on critical failures
- Uses StatusManagerFactory correctly

### Task 3.4
**Implement status management**

Add status updates:
- Set initial processing status
- Update on major milestones
- Set final status based on results
- Use StatusManagerFactory for all updates

### Task 3.5
**Write tests for progress calculation**

Test that:
- ProgressCalculator is used correctly
- Progress updates at each pipeline stage
- Percentage reflects actual completion
- Student processing shows incremental progress

### Task 3.6
**Implement progress percentage calculation**

Integrate ProgressCalculator:
- Calculate weights for each pipeline stage
- Update progress after each milestone
- Include in broadcast messages
- Ensure accurate percentage reporting

### Task 4.1
**Write tests for critical pipeline failures**

Test scenarios where:
- RubricPipeline fails (should stop processing)
- AssignmentSummaryPipeline fails (after successful student processing)
- Assignment is marked as failed in both cases
- Appropriate error messages are set

### Task 4.2
**Implement critical pipeline error handling**

Add error handling for:
- RubricPipeline failures (stop processing immediately)
- AssignmentSummaryPipeline failures (after collecting results)
- Set assignment status to failed
- Capture and report error details

### Task 4.3
**Write tests for student feedback failures**

Test that when student feedback fails:
- Other students continue processing
- Failed student work is marked appropriately
- Processing continues to summary pipeline
- Failed students are tracked in results

### Task 4.4
**Implement student feedback error handling**

Add resilient processing:
- Wrap each student pipeline in error handling
- Mark individual failures without stopping
- Collect both successful and failed results
- Continue to next student on failure

### Task 4.5
**Write tests for processing metrics tracking**

Test that ProcessingMetric records are created:
- For each LLM call in any pipeline
- With correct assignment association
- With timing and usage data
- Metrics are persisted even on failures

### Task 4.6
**Ensure processing metrics are saved**

Verify implementation:
- All pipelines already save ProcessingMetric records
- Add any missing metric tracking
- Ensure metrics are saved in error scenarios
- No additional implementation needed if pipelines handle this

### Task 5.1
**Write tests for AssignmentJob integration**

Write tests in `test/jobs/assignment_job_test.rb` for:
- Job creates AssignmentProcessor instance
- Job calls process method
- Job handles processor errors appropriately
- Job completes successfully when processor succeeds

### Task 5.2
**Modify AssignmentJob to use AssignmentProcessor**

Update `app/jobs/assignment_job.rb` to:
- Create AssignmentProcessor instance with assignment_id
- Call process method
- Handle any errors from processor
- Remove or refactor existing pipeline calls

### Task 5.3
**Write integration tests for full workflow**

Create integration test that:
- Creates assignment with student works
- Runs AssignmentJob
- Verifies all pipelines execute
- Checks final assignment state
- Verifies broadcasts were sent

### Task 5.4
**Handle edge cases**

Test and implement handling for:
- Assignment with zero student submissions
- Assignment with only document selection (no submissions)
- Very large number of students
- Timeout scenarios (if needed)