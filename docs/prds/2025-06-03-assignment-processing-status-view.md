# Assignment Processing Status View PRD

## Introduction/Overview

This feature provides teachers with a comprehensive, real-time view of their assignment processing status after they submit an assignment for automated grading. The view displays live progress updates as the system generates rubrics, processes individual student work, and creates assignment summaries. This transparency increases teacher awareness of the grading process, provides accurate time estimates, and builds trust in the automated grading process.

## Goals

1. Provide real-time visibility into the three-phase assignment processing pipeline (rubric generation, student feedback, assignment summary)
2. Display accurate progress indicators and time estimates to help teachers plan their time effectively
3. Show processing results inline as they complete, allowing teachers to review content while processing continues
4. Handle error states gracefully with clear messaging and recovery options
5. Deliver a responsive, mobile-friendly experience that works seamlessly across all devices
6. Implement a beautiful high-craft design that is in line with the rest of the best design aspects of the application

## User Stories

1. As a teacher, I want to see when rubric generation starts and completes so I can review the criteria while student work is being processed
2. As a teacher, I want to track which student's work is currently being processed so I understand the system's progress
3. As a teacher, I want to see an accurate time estimate for completion so I know when the process will be complete
4. As a teacher, I want to view completed rubric criteria inline so I can understand how students will be evaluated
5. As a teacher, I want to see that student work status changes from pending to in_progress to completed so I can understand the system's progress
6. As a teacher, I want clear indication when the assignment summary is being generated so I know the process is nearly complete
7. As a teacher on a mobile device, I want the same progress visibility in a format optimized for smaller screens

## Functional Requirements

### Progress Display Components

1. **Overall Progress Bar**: The system must display a master progress bar showing overall completion percentage (0-100%)
2. **ETA Display**: The system must show estimated time remaining, updated dynamically as processing progresses
3. **Phase Indicators**: The system must display the three processing phases with visual status indicators:
   - Rubric Generation (pending → in_progress → completed)
   - Student Work Processing (pending → in_progress → completed)
   - Assignment Summary (pending → in_progress → completed)

### Rubric Generation Phase

4. **Pre-Processing Notification**: The system must display "Creating rubric..." message immediately before LLM request
5. **Rubric Display**: Upon completion, the system must update the view to show:
   - Rubric criteria list (titles only)
   - "View full rubric" link
   - Green completion indicator

### Student Work Processing Phase

6. **Individual Progress**: The system must display "Generating student feedback (X of Y)" during processing
7. **Student Work List**: The system must show a list of all student works with status indicators:
   - Pending (gray indicator)
   - Processing (animated spinner)
   - Completed (green checkmark)
   - Failed (red X with error message)
8. **Live Updates**: Each student work row must update via TurboStream when processing completes

### Assignment Summary Phase

9. **Summary Notification**: The system must display "Creating assignment summary..." when this phase begins
10. **Completion Update**: The system must show a green indicator when summary generation completes

### Error Handling

11. **Error Display**: The system must show inline error messages for failed processing steps
12. **Partial Failures**: The system must continue processing remaining items if individual student works fail
13. **Critical Failures**: The system must stop processing and display clear error messaging if rubric generation fails

### Mobile Responsiveness

14. **Responsive Layout**: The system must adapt the layout for mobile devices using Tailwind CSS breakpoints
15. **Touch-Friendly**: All interactive elements must be sized appropriately for touch interaction (minimum 44x44px)
16. **Priority Information**: Mobile view must prioritize overall progress and current processing step

### Real-Time Updates

17. **TurboStream Integration**: All progress updates must use TurboStream for live updates without page refresh
18. **Update Frequency**: Progress updates must occur at minimum when:
    - Each phase starts/completes
    - Each student work starts/completes processing

## Non-Goals (Out of Scope)

1. Ability to cancel or pause processing once started
2. Detailed processing logs or step-by-step LLM request visibility
3. Email or push notifications for completion
4. Ability to modify assignment details during processing
5. Batch processing multiple assignments simultaneously
6. Sound notifications or desktop alerts
7. Processing history or analytics

## Design Considerations

### Visual Hierarchy
- Overall progress bar should be most prominent
- Current processing step highlighted with animation
- Completed sections should be visually de-emphasized
- Use color coding: gray (pending), blue (processing), green (complete), red (error)

### Layout Structure
- Desktop: Single column with generous spacing
- Mobile: Stacked cards with collapsible completed sections
- Consistent use of Tailwind utility classes for maintainability

### Animation and Transitions
- Smooth progress bar animations
- Subtle fade-in for completed items
- Spinning indicators for active processing
- No jarring layout shifts when content updates

## Technical Considerations

1. **Broadcast Targets**: Use specific DOM IDs for TurboStream updates:
   - `assignment_#{id}_progress` for overall progress
   - `student_work_#{id}` for individual work rows
   - `rubric_content` for rubric display
   - `rubric_tab_indicator`, `summary_tab_indicator` for phase indicators

2. **Progress Calculation**: Leverage existing `Assignments::ProgressCalculator` service

3. **Partial Rendering**: Use Rails partials for reusable components:
   - `assignments/progress_card`
   - `assignments/student_work_row`
   - `assignments/rubric_section`

4. **Error Boundaries**: Implement graceful fallbacks if TurboStream connections fail

## Success Metrics

1. **User Engagement**: 90% of teachers remain on the page during processing (don't navigate away)
2. **Error Visibility**: 100% of processing errors are clearly communicated to teachers
3. **Mobile Usage**: 40% of teachers successfully use the feature on mobile devices
4. **Time Estimation Accuracy**: ETA estimates are within 20% of actual completion time
5. **Feature Satisfaction**: 85% positive feedback on the processing visibility feature

## Open Questions

1. Should we implement a notification system for when teachers navigate away during processing? - NO
2. What's the preferred behavior if a teacher closes their browser during processing - should processing continue?  - Processing should absolutely continue.
3. Should we add a "minimize" option to collapse the progress view while staying on the page? - No, but the progress bar should be removed when the processing is complete.
4. Do we need to implement rate limiting for TurboStream broadcasts to prevent performance issues? - NO
5. Should completed rubric criteria be immediately interactive (expandable) or just display titles? - Just titles.