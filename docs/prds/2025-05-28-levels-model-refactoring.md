# Levels Model Refactoring PRD

## Introduction/Overview

The current levels model uses a `position` field that only handles UI ordering of rubric levels. This limitation prevents us from calculating meaningful performance averages for student work. This refactoring will add a standardized point value system (0-4 scale) to enable quantitative analysis of student performance while maintaining the flexibility for future UI ordering customization.

## Goals

1. Enable calculation of average performance levels per criterion across all student works for an assignment
2. Maintain clear separation between display ordering (position) and quantitative value (points)
3. Establish a standardized 0-4 point scale for all rubric levels
4. Ensure data integrity through proper validation rules

## User Stories

1. As a teacher, I want to see the average performance level for my class on each criterion of an assignment, so that I can understand overall class performance and identify areas needing additional instruction.

2. As a teacher, I want the system to automatically assign point values (0-4) to my rubric levels, so that I don't need to manually configure scoring.

3. As a teacher, I want to view rubric criteria summaries on the assignment page, so that I can quickly understand the assessment structure.

## Functional Requirements

1. The Level model must include a `points` field (integer) that stores values from 0 to 4
2. The system must automatically assign point values 0-4 to levels within each criterion
3. Point values must be unique within each criterion (no two levels in the same criterion can have the same point value)
4. The system must validate that:
   - Point values are integers between 0 and 4 (inclusive)
   - Point values are unique per criterion
   - All levels within a criterion have point values assigned
5. The system must calculate the average performance level per criterion by:
   - Taking the sum of point values for all student works for that criterion
   - Dividing by the number of student works
   - Returning a decimal value (e.g., 2.75)
6. The assignment show page (`/views/assignments/show.html.erb`) must display:
   - A link to view the full rubric
   - A summary of rubric criteria with average performance levels
7. The future student work show page must display the rubric criteria and levels with their associated point values

## Non-Goals (Out of Scope)

1. This refactoring will NOT implement user-customizable point values
2. This refactoring will NOT implement user-customizable level ordering at this time
3. This refactoring will NOT calculate overall assignment averages (mean of criterion averages)
4. This refactoring will NOT modify the teacher's rubric creation workflow to manually assign points
5. This refactoring will NOT implement weighted averages or complex scoring algorithms

## Design Considerations

1. **Database Schema**: 
   - Add `points` integer field to the levels table
   - Maintain existing `position` field for future UI ordering flexibility
   
2. **UI Display**:
   - Assignment show page should clearly display criterion averages
   - Consider using visual indicators (progress bars, color coding) for average levels
   - Ensure point values are visible but not editable in the UI

## Technical Considerations

1. **Model Validations**:
   - Implement Rails validations for point value range (0-4)
   - Implement custom validation for uniqueness of points within a criterion
   
2. **Auto-assignment Logic**:
   - When creating levels, automatically assign points 0-4 based on position or creation order
   - Ensure consistent point assignment (lowest performance = 0, highest = 4)

3. **Performance**:
   - Consider adding database indexes for efficient average calculations
   - May want to cache calculated averages if performance becomes an issue

4. **Testing**:
   - Unit tests for point value validations
   - Integration tests for average calculation logic
   - System tests for UI display of averages

## Success Metrics

1. Teachers can view average performance levels per criterion within 2 seconds of page load
2. 100% of rubric levels have valid point values (0-4) assigned
3. Zero data integrity issues related to duplicate point values within criteria
4. Successful calculation of criterion averages for assignments with 1-100+ student works

## Open Questions

1. Should we display decimal averages (e.g., 2.75) or round to nearest half point (e.g., 2.5)?
  - Two decimal places is fine.
2. How should we handle assignments where not all student works have been evaluated for all criteria?
  - We should provide the average but also show number of assignments that were evaluated for that criterion. e.g. "Average: 2.5 (5 of 10 assignments evaluated)"
3. Should there be a visual representation of the 0-4 scale in the UI (e.g., stars, progress bar)?
  - No we should just show the number.
4. What happens if a rubric is edited after student works have been graded? Should we recalculate or lock the rubric?
  - Lock the rubric, we will not provide the ability to edit rubrics at this time.
