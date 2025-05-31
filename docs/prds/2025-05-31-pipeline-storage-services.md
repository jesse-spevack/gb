# Pipeline Storage Services PRD

## Introduction/Overview

The Pipeline Storage Services are critical components of GradeBot's processing pipeline that persist AI-generated content to the database. These services take parsed LLM responses and create the appropriate database records (rubrics, student feedback, and assignment summaries) that teachers can view and interact with. Without these storage services, the AI-generated insights would be lost, preventing teachers from accessing the core value of the application.

## Goals

1. Persist parsed LLM responses as structured database records that can be displayed in the UI
2. Ensure data integrity through atomic transactions - either all related records save successfully or none do
3. Provide clear error reporting when persistence fails so issues can be quickly identified and resolved
4. Enable the teacher workflow by making AI-generated content accessible for review and editing

## User Stories

1. As a teacher, I want my AI-generated rubric to be saved with all its criteria and levels so that I can review and use it for grading
2. As a teacher, I want each student's feedback and assessment scores to be saved so that I can review and customize them before sharing
3. As a teacher, I want the class-wide insights to be saved so that I can understand overall performance trends
4. As a teacher, I want to be notified if something goes wrong during processing so that I know to retry or contact support

## Functional Requirements

### Pipeline::Storage::RubricService

1. The service must accept a context object containing parsed rubric data
2. The service must create a Rubric record associated with the assignment
3. The service must create Criterion records for each rubric criterion with proper positioning
4. The service must create Level records for each criterion level with proper positioning
5. The service must use database transactions to ensure all records are saved atomically
6. The service must return the saved rubric in the context for downstream pipeline steps
7. The service must fail fast on validation errors and propagate error details

### Pipeline::Storage::StudentWorkService

8. The service must accept a context object containing parsed student work feedback
9. The service must update the StudentWork record with qualitative feedback text
10. The service must create FeedbackItem records for each strength and opportunity
11. The service must create StudentWorkCheck records for verification items
12. The service must create StudentCriterionLevel records linking work to rubric assessments
13. The service must save each student work individually (not in bulk)
14. The service must use database transactions for each student work and its children
15. The service must return the saved feedback in the context

### Pipeline::Storage::AssignmentSummaryService

16. The service must accept a context object containing parsed assignment summary data
17. The service must create an AssignmentSummary record with insights text
18. The service must create FeedbackItem records for class-wide strengths and opportunities
19. The service must update student work count on the summary
20. The service must use database transactions to ensure atomic saves
21. The service must return the saved summary in the context

### Common Requirements

22. All services must follow the standard `.call(context:)` interface pattern
23. All services must integrate with existing ActiveRecord validations
24. All services must preserve any existing context data while adding saved records
25. All services must provide detailed error messages on failure

## Non-Goals (Out of Scope)

1. This feature will NOT implement retry logic for failed saves
2. This feature will NOT include caching mechanisms
3. This feature will NOT handle asynchronous/background processing
4. This feature will NOT implement custom validation beyond ActiveRecord defaults
5. This feature will NOT aggregate validation errors - it will fail fast
6. This feature will NOT support partial success - transactions are all-or-nothing

## Design Considerations

- Services should follow existing pipeline patterns established in the codebase
- Use Rails' built-in transaction support for atomic operations
- Leverage ActiveRecord associations for efficient record creation
- Maintain consistency with existing service naming conventions

## Technical Considerations

- Maximum of 35 student works per assignment to consider for transaction size
- Services must integrate cleanly with Pipeline::Context objects
- Database transactions should wrap the smallest logical unit of work
- Consider using `create!` methods to ensure exceptions on validation failures

## Success Metrics

1. All parsed LLM responses are successfully persisted to the database
2. Zero data integrity issues - no orphaned or incomplete records
3. Clear error messages help developers quickly identify and fix issues
4. Teachers can view all AI-generated content after processing completes

## Open Questions

1. Should we add any database indexes to optimize queries for these new records?
2. Should the services log successful saves for debugging purposes?
3. Do we need any callbacks or hooks after successful persistence for future features?