# Product Requirements Document: Rubric Toggle Simplification

## Introduction/Overview

This feature simplifies the rubric section in the assignment creation form by removing the ability to paste custom rubrics and making AI-generated rubrics the only option. The toggle switch will remain visible but in a permanently "on" state to indicate that future flexibility may be added. This change makes the application more user-friendly for initial test users while preserving the infrastructure for future enhancement.

## Goals

1. Simplify the assignment creation experience for initial test users
2. Ensure all assignments use AI-generated rubrics for consistent quality
3. Maintain visual indication that rubric generation is an active feature
4. Preserve the underlying infrastructure for future flexibility

## User Stories

1. As a teacher creating an assignment, I want to see clearly that GradeBot will generate a rubric for me, so I understand what to expect
2. As a teacher, I want a simplified interface without confusing options, so I can focus on describing my assignment
3. As a product team, we want to maintain the toggle infrastructure, so we can easily re-enable manual rubric input in the future

## Functional Requirements

1. The rubric section must display a toggle switch that is always in the "on" position
2. The toggle switch must be visually disabled (non-clickable) but still appear as a toggle control
3. The text must clearly state "GradeBot will generate an AI rubric based on your assignment details"
4. The textarea for pasting rubrics must be permanently disabled and display the AI generation message as placeholder text
5. The system must continue to store `rubric_text` as null/empty in the database
6. The form must continue to submit without requiring rubric text input
7. The existing Stimulus controller must be modified to prevent toggle interaction

## Non-Goals (Out of Scope)

1. Removing the toggle switch entirely from the UI
2. Removing the `rubric_text` database field
3. Removing the rubric toggle Stimulus controller
4. Changing how rubrics are generated or stored
5. Modifying the rubric display on the assignment show page

## Design Considerations

- Maintain consistency with the existing design system (DESIGN_SYSTEM.md)
- Keep the current card-based layout with icon and heading
- Ensure the disabled toggle uses appropriate visual cues (cursor, opacity, or color)
- The toggle should visually indicate it's in the "on" state even though it's disabled

## Technical Considerations

- Modify `app/views/assignments/new.html.erb` rubric section
- Update the `rubric_toggle_controller.js` to prevent toggling
- No database migrations needed (preserving `rubric_text` field)
- Update `docs/changelog.md` with this change
- Ensure `bin/check` passes before committing

## Success Metrics

1. Reduced confusion during user testing sessions
2. 100% of new assignments created with AI-generated rubrics
3. No support requests about rubric paste functionality
4. Successful completion of demo scenarios without rubric-related issues

## Open Questions

1. Should we add a tooltip or help text explaining why the toggle is disabled?
2. Do we need to update any help documentation or user guides?
3. Should the disabled toggle have a specific visual treatment (e.g., lock icon)?