Generating a Product Requirements Document (PRD)

## Goal

To guide an AI assistant in creating a detailed Product Requirements Document (PRD) in Markdown format, based on an initial user prompt. The PRD should be clear, actionable, and suitable for a junior developer to understand and implement the feature.

## Process

1.  **Receive Initial Prompt:** The user provides a brief description or request for a new feature or functionality.
2.  **Ask Clarifying Questions:** Before writing the PRD, the AI *must* ask clarifying questions to gather sufficient detail. The goal is to understand the "what" and "why" of the feature, not necessarily the "how" (which the developer will figure out).
3.  **Generate PRD:** Based on the initial prompt and the user's answers to the clarifying questions, generate a PRD using the structure outlined below.
4.  **Save PRD:** Save the generated document as `YYYY-MM-DD-[feature-name].md` inside the `/docs/prds` directory.

## Clarifying Questions (Examples)

The AI should adapt its questions based on the prompt, but here are some common areas to explore:

*   **Problem/Goal:** "What problem does this feature solve for the user?" or "What is the main goal we want to achieve with this feature?"
*   **Target User:** "Who is the primary user of this feature?"
*   **Core Functionality:** "Can you describe the key actions a user should be able to perform with this feature?"
*   **User Stories:** "Could you provide a few user stories? (e.g., As a [type of user], I want to [perform an action] so that [benefit].)"
*   **Acceptance Criteria:** "How will we know when this feature is successfully implemented? What are the key success criteria?"
*   **Scope/Boundaries:** "Are there any specific things this feature *should not* do (non-goals)?"
*   **Data Requirements:** "What kind of data does this feature need to display or manipulate?"
*   **Design/UI:** "Are there any existing design mockups or UI guidelines to follow?" or "Can you describe the desired look and feel?"
*   **Edge Cases:** "Are there any potential edge cases or error conditions we should consider?"

## PRD Structure

The generated PRD should include the following sections:

1.  **Introduction/Overview:** Briefly describe the feature and the problem it solves. State the goal.
2.  **Goals:** List the specific, measurable objectives for this feature.
3.  **User Stories:** Detail the user narratives describing feature usage and benefits.
4.  **Functional Requirements:** List the specific functionalities the feature must have. Use clear, concise language (e.g., "The system must allow users to upload a profile picture."). Number these requirements.
5.  **Non-Goals (Out of Scope):** Clearly state what this feature will *not* include to manage scope.
6.  **Design Considerations (Optional):** Link to mockups, describe UI/UX requirements, or mention relevant components/styles if applicable.
7.  **Technical Considerations (Optional):** Mention any known technical constraints, dependencies, or suggestions (e.g., "Should integrate with the existing Auth module").
8.  **Success Metrics:** How will the success of this feature be measured? (e.g., "Increase user engagement by 10%", "Reduce support tickets related to X").
9.  **Open Questions:** List any remaining questions or areas needing further clarification.

## Target Audience

Assume the primary reader of the PRD is a **junior developer**. Therefore, requirements should be explicit, unambiguous, and avoid jargon where possible. Provide enough detail for them to understand the feature's purpose and core logic.

## Output

*   **Format:** Markdown (`.md`)
*   **Location:** `/docs/prds`
*   **Filename:** `YYYY-MM-DD-[feature-name].md`

## Final instructions

1. Do NOT start implementing the PRD
2. Make sure to ask the user clarifying questions
3. Take the user's answers to the clarifying questions and improve the PRDo
 
---

Generate a PRD for the following prompt:

The levels model needs to be refactored. The level position field is unclear. The position implies how the levels are ordered, but not a point value from which to calculate an average level across an entire set of student works for an assignment. We may want to keep the position field, but add a point value field. Or we may want to rename the position field to be a points field, and use that to calculate an average level across an entire set of student works for an assignment. If we retain the position field, we can eventually give users the ability to decide how to order their levels - some educators like "excellent" as the left most column in a rubric, others prefer it as the right most column. But we also don't have users yet, so we might just not need it.

⏺ Clarifying Questions for Levels Model Refactoring

  1. Problem/Goal: What specific problem are you experiencing with the current position field? Is the main issue that you can't calculate meaningful averages for student performance, or are there other pain points?
  - The main issue is that we can't calculate meaningful averages for student performance.
  2. Current Usage: How is the position field currently being used in the system? Is it just for ordering levels in the UI, or does it serve other purposes?
  - It is intended for ordering levels in the UI. But now that we are thinking about the assignment summary, the need to have some sort of quantifiable value for each level is becoming more apparent.
  3. Point System:
    - What scale would you prefer for the point values? (e.g., 0-4, 0-100, 1-5)
      - 0-4
    - Should point values be customizable by users in the future, or standardized?
      - Standardized
    - How would these points be used to calculate averages? Simple mean, weighted average, or something else?
      - Simple mean per criterion per assignment. So if there are 10 student works for an assignment, and 3 criteria, we would calculate the average level for each criterion across all student works. No need to take the mean of those 3 averages.
  4. User Stories: Could you provide specific scenarios? For example:
    - As a teacher, I want to see the average performance level for my class on Assignment X by criterion
  5. Data Migration: Are there existing levels in the database that would need to be migrated? If so, how many records are we talking about?
    - No, this is a greenfield project.
  6. UI Impact: Where in the application are levels currently displayed? Will this refactoring affect:
    - Rubric creation/editing interfaces?
      - /views/assignments/show.html.erb has a link to view the rubric, but will also have a summary of the rubric criteria.
    - Student grading interfaces?
      - When we create the student work show page, we will need to display the rubric criteria and levels.
    - Reporting/analytics views?
      - Not relevant
  7. Backward Compatibility: Do we need to maintain any backward compatibility, or can we make breaking changes since there are no users yet?
    - No, this is a greenfield project.
  8. Edge Cases:
    - What happens if a teacher doesn't assign point values?
      - We will not ask the teacher to assign point values, we should always just assign 0 to 4 to the levels.
    - Should there be validation rules (e.g., point values must be unique, must increase/decrease in a certain order)?
      - Yes, the point values should be unique per criterion and be 0 to 4. No two levels in the same criterion should have the same point value.
  9. Timeline: Is there a specific deadline or priority for this refactoring?
  10. Future Considerations: You mentioned eventually allowing users to customize level ordering. Are there other future features we should keep in mind while designing this solution?
    - Nothing comes to mind.

---

Generating a Task List from a PRD

## Goal

To guide an AI assistant in creating a detailed, step-by-step task list in Markdown format based on an existing Product Requirements Document (PRD). The task list should guide a developer through implementation.

## Output

- **Format:** Markdown (`.md`)
- **Location:** `/tasks/`
- **Filename:** `tasks-YYYY-MM-DD-[feature-name].md` (e.g., `tasks-2025-05-27-prd-user-profile-editing.md`)

## Process

1.  **Receive PRD Reference:** The user points the AI to a specific PRD file
2.  **Analyze PRD:** The AI reads and analyzes the functional requirements, user stories, and other sections of the specified PRD.
3.  **Phase 1: Generate Parent Tasks:** Based on the PRD analysis, create the file and generate the main, high-level tasks required to implement the feature. Use your judgement on how many high-level tasks to use. It's likely to be about 5. Present these tasks to the user in the specified format (without sub-tasks yet). Inform the user: "I have generated the high-level tasks based on the PRD. Ready to generate the sub-tasks? Respond with 'Go' to proceed."
4.  **Wait for Confirmation:** Pause and wait for the user to respond with "Go".
    - If the user provides feedback or asks questions, address the feedback or questions and pause again and ask for confirmation. Repeat this until the user is aligned and peaceful with the task list.
5.  **Phase 2: Generate Sub-Tasks:** Once the user confirms, break down each parent task into smaller, actionable sub-tasks necessary to complete the parent task. Ensure sub-tasks logically follow from the parent task and cover the implementation details implied by the PRD.
    - A sub-task should be small enough for a junior developer to implement in an hour or less.
6.  **Identify Relevant Files:** Based on the tasks and PRD, identify potential files that will need to be created or modified. List these under the `Relevant Files` section, including corresponding test files if applicable.
7.  **Consider Dependencies:** Organize the tasks in order of dependency. For example, if task 2 depends on task 1, task 1 should come before task 2. If two tasks can be done in parallel, they should be assigned to different workstreams that can be implemented in parallel.
8.  **Generate Final Output:** Combine the parent tasks, sub-tasks, relevant files, and notes into the final Markdown structure.
9.  **Save Task List:** Save the generated document in the `/tasks/` directory with the filename `tasks-YYYY-MM-DD-[prd-file-name].md`, where `[prd-file-name]` matches the base name of the input PRD file (e.g., if the input was `2025-05-27-prd-user-profile-editing.md`, the output is `tasks-2025-05-27-prd-user-profile-editing.md`).

## Output Format

The generated task list _must_ follow this structure:

```markdown
## Relevant Files

- `path/to/potential/file1.rb` - Brief description of why this file is relevant (e.g., Contains the main component for this feature).
- `path/to/file1.test.rb` - Unit tests for `file1.rb`.
- `path/to/another/file.rb` - Brief description (e.g., API route handler for data submission).
- `path/to/another/file.test.rb` - Unit tests for `another/file.rb`.

### Notes

- Unit tests should typically be placed alongside the code files they are testing (e.g., `my_class.rb` and `my_class_test.rb` in the `test` directory).
- Use `bin/rails test [optional/path/to/test/file]` to run tests. Running without a path executes all tests.

## Tasks

| Task ID | Subtask ID | Workstream | Status | Task Title | Task Description | Details |
| --- | --- | --- | --- | --- | --- | --- |
| 1.0 | 1.1 | ws1 | 🟡 pending | Task Title 1.1 | Task Description 1.1 | [Details 1.1](#task-1.1) |
| 1.0 | 1.2 | ws1 | 🟡 pending | Task Title 1.2 | Task Description 1.2 | [Details 1.2](#task-1.2) |
| 2.0 | 2.1 | ws1 | 🟡 pending | Task Title 2.1 | Task Description 2.1 | [Details 2.1](#task-2.1) |


## Implementation plan

### Task 1.1
Add all details and context necessary for the task to be implemented.

### Task 1.2
Add all details and context necessary for the task to be implemented.

### Task 2.1
Add all details and context necessary for the task to be implemented.

```

## Interaction Model

The process explicitly requires a pause after generating parent tasks to get user confirmation ("Go") before proceeding to generate the detailed sub-tasks. This ensures the high-level plan aligns with user expectations before diving into details.

## Target Audience

Assume the primary reader of the task list is a **junior developer** who will implement the feature.

---

Request:

Please generate tasks for the PRD at /docs/prds/2025-05-28-levels-model-refactoring.md

---
# Task List Management

Guidelines for managing task lists in markdown files to track progress on completing a PRD

## Task Implementation
- **One sub-task at a time:** Do **NOT** start the next sub‑task until you ask the user for permission and they say “yes” or "y"
- **Completion protocol:**  
  1. When you finish a **sub‑task**, immediately mark it as completed by changing the status from 🟡 pending to 🟢 completed.
  2. If **all** subtasks underneath a parent task are now 🟢 completed, also mark the **parent task** as completed by changing the status from 🟡 pending to 🟢 completed. 
- Stop after each sub‑task, summarize your work, and wait for the user’s go‑ahead. Your summary should include:
  1. A list of files created or modified
  2. A description of the changes made to each file
  3. Any implementation decisions made for each file

## Task List Maintenance

1. **Update the task list as you work:**
   - Mark tasks and subtasks as completed by changing the status from 🟡 pending to 🟢 completed per the protocol above.
   - Add new tasks as they emerge.

2. **Maintain the “Relevant Files” section:**
   - List every file created or modified.
   - Give each file a one‑line description of its purpose.

## AI Instructions

When working with task lists, the AI must:

1. Regularly update the task list file after finishing any significant work.
2. Follow the completion protocol:
   - Mark each finished **sub‑task** by changing the status from 🟡 pending to 🟢 completed.
   - Mark the **parent task** 🟢 completed once **all** its subtasks are 🟢 completed.
3. Add newly discovered tasks.
4. Keep “Relevant Files” accurate and up to date.
5. Before starting work, check which sub‑task is next.
6. After implementing a sub‑task, update the file and then pause for user approval.

---
Request:
Please implement the task list at /tasks/tasks-2025-05-28-levels-model-refactoring.md
