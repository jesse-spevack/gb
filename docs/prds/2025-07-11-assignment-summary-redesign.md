# Assignment Summary Page Redesign

## Introduction/Overview

This PRD outlines the redesign of the assignment summary page to provide teachers with a comprehensive, visual overview of student performance across an entire assignment. The current implementation needs to be replaced with a more data-rich interface that displays aggregate performance metrics, criterion-by-criterion breakdowns, and synthesized feedback insights.

The goal is to help teachers quickly understand how their class performed on an assignment, identify patterns in student strengths and weaknesses, and make informed decisions about instructional next steps.

## Goals

1. **Provide visual clarity**: Display assignment performance data in an easily scannable, visual format
2. **Enable quick assessment**: Allow teachers to understand class performance patterns within 30 seconds of viewing
3. **Support instructional planning**: Present actionable insights about student strengths and areas for growth
4. **Maintain design consistency**: Use existing design system components and patterns

## User Stories

- **As a teacher**, I want to see overall class performance distribution so that I can quickly gauge whether my instruction was effective
- **As a teacher**, I want to see performance by individual criteria so that I can identify which learning objectives need reinforcement
- **As a teacher**, I want to see synthesized feedback themes so that I can understand common patterns across student work
- **As a teacher**, I want to easily navigate back to the assignment details so that I can access related information
- **As a teacher**, I want to see aggregate performance visually so that I can identify trends at a glance

## Functional Requirements

### Core Display Requirements
1. The system must display the assignment title and total number of student submissions
2. The system must show performance level distribution using data cards (Exceeds, Meets, Approaching, Below) with counts and percentages
3. The system must display an "Overall average" bar chart showing aggregate performance across all criteria
4. The system must show individual criterion performance with visual bar charts and breakdowns
5. The system must present key insights in a dedicated section with lightbulb icon
6. The system must display categorized feedback items in two columns (Strengths and Opportunities for Growth)

### Navigation Requirements
7. The system must provide a "Back to assignment" link that returns to the assignment show page
8. The system must maintain consistent navigation patterns with existing assignment views

### Data Requirements
9. The system must calculate performance level distributions from student_criterion_level data
10. The system must aggregate criterion-specific performance metrics
11. The system must display qualitative insights from the assignment_summary model
12. The system must show feedback items categorized by type (strengths vs opportunities)

### Error Handling
13. The system must display a clear message when assignment summary data hasn't been generated
14. The system must gracefully handle assignments with no submissions

## Non-Goals (Out of Scope)

- Export functionality for summary data
- Drill-down into individual student performance
- Filtering or sorting options
- Editing of summary data or feedback items
- Real-time data updates
- Mobile-specific optimizations beyond responsive design

## Design Considerations

### Layout Structure
- Use the exact layout from ui_4.html as the implementation target
- Maintain white background (`bg-white`) throughout
- Use `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10` for page container

### Component Reuse
- Reuse data card pattern from `app/views/student_works/show.html.erb` for performance level cards
- Use existing icons from `shared/icons` directory (checkmark, lightning_bolt, lightbulb)
- Apply standard section card pattern with `shadow-sm border border-gray-200`

### Visual Elements
- Performance level colors: green (Exceeds), blue (Meets), amber (Approaching), red (Below)
- Use progress bars for criterion performance visualization
- Apply sentence case to all headings per design system
- Use border-left accent bars for feedback items

## Technical Considerations

### Data Architecture Options
**Option 1: Extend AssignmentSummary Model**
- Add calculated fields to store aggregated performance metrics
- Pros: Simpler queries, faster page loads
- Cons: Data duplication, needs recalculation when student data changes

**Option 2: Create AssignmentPerformanceMetrics Model**
- New model to store pre-calculated aggregate data
- Pros: Separation of concerns, optimized for display
- Cons: Additional complexity, sync requirements

**Option 3: Real-time Calculations**
- Calculate metrics on-demand from StudentCriterionLevel data
- Pros: Always current, no data duplication
- Cons: Potentially slower, complex queries

**Recommendation**: Start with Option 3 for simplicity, move to Option 2 if performance becomes an issue.

### Required Calculations
- Performance level distribution (count and percentage by level)
- Average score per criterion
- Overall class average across all criteria
- Criterion-specific performance breakdowns

### Model Relationships
- `Assignment` → `AssignmentSummary` (existing)
- `Assignment` → `StudentWork` → `StudentCriterionLevel` (for calculations)
- `AssignmentSummary` → `FeedbackItem` (existing)

### Controller Structure
- Extend `AssignmentSummariesController#show`
- Add methods for calculating performance metrics
- Handle edge cases (no data, missing summary)

## Success Metrics

- Teachers can identify class performance patterns within 30 seconds
- Page loads in under 2 seconds with typical class sizes (20-30 students)
- Zero user-reported confusion about data interpretation
- Consistent visual design with existing application patterns

## Open Questions

1. Should we cache calculated metrics, and if so, when should cache be invalidated?
2. What is the maximum expected class size for performance optimization?
3. Should we add any loading states for slower calculations?
4. Are there specific accessibility requirements for the visual charts?
5. Should we add any hover states or tooltips for additional data context?

## Implementation Notes

- Follow existing ERB view patterns in the application
- Use Tailwind CSS classes consistent with the design system
- Ensure responsive design works on tablet and desktop
- Include proper semantic HTML structure for accessibility
- Add appropriate ARIA labels for chart elements