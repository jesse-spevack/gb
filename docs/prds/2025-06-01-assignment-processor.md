# AssignmentProcessor Class PRD

## Introduction/Overview

The AssignmentProcessor class serves as the main orchestrator for automating the entire grading process. It coordinates the sequential execution of three core pipelines: RubricPipeline (generates rubrics from assignment information), StudentWorkFeedbackPipeline (generates feedback for each student submission), and AssignmentSummaryPipeline (creates a comprehensive summary of all student work). The processor ensures proper dependency management, handles errors across all pipelines, and provides real-time progress updates to teachers through the existing broadcast infrastructure.

## Goals

1. Automate the complete grading workflow from rubric generation to assignment summary creation
2. Ensure proper sequential execution of pipelines with dependency management
3. Provide real-time, granular progress updates to teachers during processing
4. Handle errors gracefully across all pipeline stages with appropriate status updates
5. Track processing metrics for each LLM call throughout the workflow
6. Aggregate results from all pipelines into a cohesive final result

## User Stories

1. **As a teacher**, I want to see the grading process start automatically after creating an assignment, so that I don't need to manually trigger each step.

2. **As a teacher**, I want to see real-time progress updates showing which stage of grading is active and how many students have been processed, so that I know how long the process will take.

3. **As a teacher**, I want to see clear status indicators for each stage (rubric creation, student feedback, summary), so that I understand what has been completed and what's in progress.

4. **As a teacher**, I want the system to continue processing even if some student feedback fails, so that I can still get results for successful submissions.

5. **As a system administrator**, I want processing metrics tracked for each LLM call, so that I can monitor system performance and costs.

## Functional Requirements

1. **Pipeline Orchestration**
   - The system must execute pipelines in this exact sequence: RubricPipeline → StudentWorkFeedbackPipeline (for each student) → AssignmentSummaryPipeline
   - The system must wait for RubricPipeline to complete successfully before starting any StudentWorkFeedbackPipeline
   - The system must wait for all StudentWorkFeedbackPipeline instances to complete before starting AssignmentSummaryPipeline

2. **Progress Tracking and Broadcasting**
   - The system must broadcast progress updates using the existing BroadcastService and ProgressBroadcaster
   - The system must show pipeline-level progress: "Creating rubric", "Generating student feedback (3 of 10)", "Creating assignment summary"
   - The system must update assignment status at each major milestone using StatusManagerFactory
   - The system must use ProgressCalculator to determine overall completion percentage

3. **Context Management**
   - The system must pass the rubric context from RubricPipeline to each StudentWorkFeedbackPipeline instance
   - The system must aggregate all student feedback contexts for use by AssignmentSummaryPipeline
   - The system must preserve pipeline context objects for result aggregation

4. **Error Handling**
   - The system must utilize the existing CircuitBreaker and RetryHandler for LLM request failures
   - The system must mark individual student works as failed if they fail after all retry attempts
   - The system must mark the entire assignment as failed if any critical pipeline fails (RubricPipeline or AssignmentSummaryPipeline)
   - The system must continue processing remaining students even if some student feedback generation fails

5. **Processing Metrics**
   - The system must save ProcessingMetric records for each LLM call made by any pipeline
   - The system must track timing and usage data as defined by the existing metrics infrastructure

6. **Integration Points**
   - The system must be invokable from AssignmentJob (enqueued by AssignmentCreationService)
   - The system must accept an assignment ID as its primary input parameter
   - The system must update the assignment record with final status upon completion or failure

7. **Sequential Processing**
   - The system must process one LLM request at a time (no parallel processing for now)
   - The system must process student work feedback sequentially, one student at a time

## Non-Goals (Out of Scope)

1. Manual retry functionality for failed pipelines or student work
2. Parallel processing of multiple student feedback pipelines
3. Configuration parameters for retry counts, timeouts, or other settings
4. Resource management, rate limiting, or throttling
5. Resumable processing if the job is interrupted
6. Direct UI rendering or user interface components
7. Partial assignment summary generation when some student feedback fails

## Design Considerations

- The AssignmentProcessor should follow the existing pipeline pattern established by RubricPipeline, StudentWorkFeedbackPipeline, and AssignmentSummaryPipeline
- Progress updates should integrate seamlessly with the existing Turbo Streams implementation
- The class should be designed to work within the Rails job infrastructure (AssignmentJob)
- Error messages should be clear and actionable for debugging purposes

## Technical Considerations

- Integrate with existing pipeline classes without modifying their core functionality
- Use dependency injection for pipeline instances to facilitate testing
- Ensure proper transaction handling when updating assignment status
- Consider memory usage when aggregating contexts from many student feedback pipelines
- Implement comprehensive logging for debugging pipeline execution flow

## Success Metrics

1. 100% of assignments successfully complete the full grading workflow when all LLM requests succeed
2. Teachers receive progress updates within 1 second of each pipeline milestone
3. Failed student feedback does not prevent assignment summary generation (in future iterations)
4. All LLM calls have associated ProcessingMetric records for cost tracking
5. Assignment status accurately reflects the current processing state at all times

## Open Questions

1. Should there be a maximum number of student submissions that can be processed in a single assignment?
2. How should the system handle assignments with zero student submissions?
3. Should processing metrics be aggregated at the assignment level for reporting?
4. What specific error messages should be shown to teachers when pipelines fail?
5. Should there be a timeout for the overall assignment processing job?