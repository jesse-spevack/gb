
  Clarifying Questions

  1. Problem/Goal

  - What specific problems are teachers experiencing that these storage services will solve? Is it about data reliability, performance, or something else?
  - Beyond persisting data, are there any specific data integrity concerns we need to address (e.g., preventing duplicate records, handling partial failures)?

  These storage services will ensure that the LLM responses are saved properly. We need to make sure that the parsed rubric is stored as a rubric with criteria and levels, the student work is stored as a student work with feedback items and checks, and the assignment summary with its associated feedback items. Storing this in the DB will allow us to show it to the user, which is the main value proposition of the application.

  2. Transaction Safety Requirements

  - When you mention "rollback on errors," should we implement a specific rollback strategy (e.g., database transactions, compensation logic)?
  - Should we notify users when a rollback occurs, or handle it silently?
  - Are there specific error scenarios we should prioritize (e.g., network failures, validation errors, concurrent updates)?

  If any of the child objects (e.g. levels, feedback items, checks) fail to save, we should fail fast and show the error to the user and not save the parent object (e.g. rubric, student work, assignment summary).
  
  1. Data Validation

  - What specific validations should each service perform before persistence?
  - Should validation errors be aggregated and returned together, or fail fast on first error?
  - Are there any business rules that span multiple models (e.g., a rubric must have at least 2 criteria)?

  Keep it simple and follow rails conventions. The models have the validations already. If the data is valid, save it. If it is not valid, fail fast and show the error to the user.

  4. Bulk Operations

  - What constitutes a "large dataset" in this context? (e.g., how many student works per assignment typically?)
  - Should bulk operations be atomic (all succeed or all fail) or should we support partial success?
  - Do we need progress tracking for bulk operations?

  We will have no more than 35 pieces of student work per assignment, but each should be saved individually along with its child objects - feedback items and checks.

  5. Integration Points

  - How should these storage services interact with the existing broadcasting system for real-time updates?
  - Should storage services trigger any notifications or events after successful persistence?
  - Are there any existing services or callbacks that need to be called after data is saved?

  6. Performance Requirements

  - Are there specific performance targets for these operations (e.g., save 30 student works in under 5 seconds)?
  - Should we implement any caching strategies?
  - Do we need to support asynchronous/background processing for very large operations?

  7. Error Handling

  - How should different types of errors be categorized and reported back to the pipeline?
  - Should we implement retry logic for transient failures?
  - What level of error detail should be logged vs. shown to users?

  8. Testing & Quality

  - Are there specific edge cases you're concerned about that we should ensure are tested?
  - Should we include performance benchmarks in our test suite?