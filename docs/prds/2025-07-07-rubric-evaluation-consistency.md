# Rubric Evaluation Consistency and Simplification

## Introduction/Overview

This feature aims to standardize and simplify the rubric evaluation system across the application. Currently, the system has inconsistencies in level naming, position/points mapping, and color coding that make it difficult to maintain and reason about. This refactoring will create a consistent, predictable system for displaying rubric evaluations while maintaining the current user experience.

## Goals

1. Standardize performance level names to "Exceeds", "Meets", "Approaching", and "Below" across the entire system
2. Consolidate the position/points system to use a single concept that focuses on feedback rather than grading
3. Implement actual averaging for overall performance calculations instead of using the mode
4. Centralize color mapping logic using the design system colors
5. Create reusable helper methods and partials for rubric visualization
6. Prepare the system for future configurability of level names

## User Stories

1. As a teacher, I want to see consistent performance level names throughout the application so that I can easily understand student performance at a glance.

2. As a teacher, I want to see an accurate average of student performance across all criteria so that I can better understand overall student achievement.

3. As a teacher, I want the rubric display to use consistent colors that match the performance levels so that I can quickly identify patterns in student work.

4. As a developer, I want centralized logic for performance levels and colors so that I can maintain the system more easily.

5. As a teacher, I expect the rubrics to read left to right, exceeds, meets, approaching, and below consistently across all interfaces.

## Functional Requirements

1. The system must standardize all performance level references to use "Exceeds", "Meets", "Approaching", and "Below".

2. The system must add a `performance_level` field to the Level model with values: `exceeds`, `meets`, `approaching`, `below`.

3. The system must update the rubric generation prompt to create levels with the standardized names.

4. The system must consolidate the position/points system to use a single concept (recommendation: use position 1-4 where 1=Exceeds, 2=Meets, 3=Approaching, 4=Below).

5. The system must calculate the overall performance as an actual average based on level positions and map it back to the appropriate performance category.

6. The system must create a centralized helper module for performance level styling that returns appropriate Tailwind classes based on the performance category.

7. The system must use the following color scheme from the design system:
   - Exceeds: green (`text-green-800` on `bg-green-100`)
   - Meets: blue (`text-blue-800` on `bg-blue-100`)
   - Approaching: orange (`text-amber-800` on `bg-amber-100`)
   - Below: yellow (`text-yellow-800` on `bg-yellow-100`)

8. The system must create reusable view partials for:
   - Rubric overview table
   - Rubric assessment details
   - Performance level badge (update existing)

9. The system must does not need to maintain backward compatibility with existing rubrics by mapping old level names to the new performance levels. Instead, create a rake task to update existing rubrics.

10. The system must display the average performance at both the student work level and eventually at the assignment level by criteria, though this latter piece is not to be implemented as part of this PRD.

11. Ensure consistent style by adhering to the docs/DESIGN_SYSTEM.md. If a new UI pattern is needed, it must be documented in the design system.

## Non-Goals (Out of Scope)

1. This feature will NOT implement configurable level names per rubric (this is noted as a future enhancement).
2. This feature will NOT change the visual layout or level of detail in the student work show view.
3. This feature will NOT implement grading calculations or grade export functionality.
4. This feature will NOT modify the number of performance levels (will remain at 4).
5. This feature will NOT change the rubric generation AI prompts beyond updating level names.

## Design Considerations

1. The performance badge partial should be updated to use the new performance level system.
2. Colors should remain in the view layer as helper methods, not stored in the database.
3. All text should continue to use sentence case as specified in the design system.
4. The rubric visualization components should follow the existing card and table patterns from the design system.

## Technical Considerations

1. Add a migration to add the `performance_level` field to the Level model.
2. Create a data migration to map existing level names to performance levels.
3. Update the `Pipeline::Storage::RubricService` to set performance levels when creating levels.
4. Create a `RubricHelper` module for centralized view logic.
5. Update `StudentWork#high_level_feedback_average` to calculate actual averages, but return the corresponding performance level (round the average to the nearest whole number to arrive at the average performance level).
6. Use Rails enums for the performance_category field.
7. Ensure all changes maintain the existing Stimulus controller functionality.

## Success Metrics

1. All rubric evaluations display consistent performance level names.
2. Teachers report improved clarity in understanding student performance.
3. Reduced code duplication in rubric-related views.
4. Faster development time for new rubric-related features.
5. No regression in existing rubric functionality.

## Open Questions

1. Should we migrate existing rubrics to use the new standardized level names, or maintain a mapping?
   - migrate existing rubrics
2. For the average calculation, how should we handle edge cases (e.g., no evaluations, partial evaluations)?
   - we can render a "unknown" performance level
3. Should the performance category enum be stored as an integer or string in the database?
   - integer
4. Do we need to update the teacher-provided rubric text parsing to recognize various level name synonyms?
   - no
5. Should we provide a way for teachers to preview how their custom level names will map to the standard categories?
   - no