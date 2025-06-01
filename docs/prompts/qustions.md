Clarifying Questions for AssignmentProcessor
1. Problem/Goal: What is the main problem this AssignmentProcessor solves? Is it automating the grading process for teachers, or is there a specific workflow challenge it addresses?
2. Pipeline Dependencies: You mentioned three pipelines (RubricPipeline, StudentWorkFeedbackPipeline, AssignmentSummaryPipeline). Can you describe:
  - What each pipeline does?
  - What are the dependencies between them? (e.g., does StudentWorkFeedbackPipeline require RubricPipeline to complete first?)
  - Are there any data outputs from one pipeline that serve as inputs to another?
3. Multiple Instances: You mentioned "multiple StudentWorkFeedbackPipeline instances" - does this mean processing multiple student submissions in parallel or sequentially? What determines how many instances are needed?
4. Progress Updates:
  - What specific progress information should teachers see? (e.g., "Processing student 3 of 25", percentage complete, estimated time remaining?)
  - How frequently should updates be sent?
  - Through what mechanism should these updates be delivered (websockets, polling, etc.)?
5. Error Handling:
  - If one pipeline fails, should the entire process stop, or should it continue with the remaining pipelines?
  - What types of errors are expected (network failures, invalid data, etc.)?
  - How should errors be reported to teachers?
6. Final Results:
  - What constitutes the "final result" that needs to be aggregated?
  - What assignment status transitions are expected? (e.g., from "pending" to "graded"?)
7. User Stories: Could you provide 2-3 specific user stories? For example, "As a teacher, I want to process all student submissions for an assignment so that I can review automated feedback before releasing grades."
8. Performance: Are there any performance requirements or constraints? (e.g., process 100 student submissions within 5 minutes)
9. Non-Goals: Are there any specific things this AssignmentProcessor should NOT handle? (e.g., manual grading override, grade distribution visualization)

  