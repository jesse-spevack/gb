# Simplified Assignment Creation Flow

## Introduction/Overview

This feature redesigns the assignment creation user experience to provide a streamlined, more intuitive flow for teachers. Instead of the current complex workflow, teachers will create assignments using a simple form, then see a visual progress tracking page while the Assignment Processor handles the automated grading workflow in the background. The goal is to reduce cognitive load and provide clear feedback about the processing status.

The new flow will be: Assignment Form → Loading/Progress Page → Assignment Summary Page.

## Goals

1. **Simplify the user experience** by reducing the assignment creation flow to essential steps only
2. **Provide clear progress feedback** during the automated processing phases
3. **Reduce cognitive load** for teachers by eliminating complex UI during processing
4. **Improve perceived performance** through better progress communication
5. **Create a clean, modern interface** that follows existing design patterns in the application

## User Stories

**As a teacher, I want to:**
- Quickly create an assignment with basic information without overwhelming interface elements
- See clear progress when my assignment is being processed by the system
- Understand what stage the processing is in and what's happening
- Know when processing is complete and be able to navigate to my assignment
- Have confidence that the system is working and not stuck or broken

**As a teacher, I want to:**
- See my assignment details, rubric, student work, and summary in an organized way
- Navigate easily between different aspects of my assignment
- Have a clear way to return to my assignments list

## Functional Requirements

### Loading/Progress Page

1. **Page Structure**: Display a centered loading interface with consistent branding
2. **Header**: Show "Processing assignment" as the main heading
3. **Subheading**: Display "GradeBot is analyzing student work and generating feedback"
4. **Progress Steps**: Show 4 numbered circles representing:
   - Step 1: "Assignment saved"
   - Step 2: "Creating Rubric" 
   - Step 3: "Analyzing student work"
   - Step 4: "Generating summary"
5. **Step Status Updates**: 
   - Initial state: All steps show numbers 1-4
   - As processing progresses: Completed steps display checkmark icons instead of numbers
   - Visual indication of current active step
6. **Progress Polling**: Page polls server every 3-5 seconds to check assignment status
7. **Status Determination**: 
   - Step 1 complete: Assignment record exists in database
   - Step 2 complete: Rubric, criteria, and levels exist for the assignment
   - Step 3 complete: All student work has been graded
   - Step 4 complete: Assignment summary exists
8. **Completion Behavior**: When all steps are complete, show "View Assignment" link/button
9. **URL Persistence**: If user refreshes page, current progress state is maintained
10. **Responsive Design**: Works on mobile and desktop devices

### Assignment Show Page (Redesigned)

1. **Header Section**: 
   - Back button linking to assignments index
   - Assignment title display
   - Brief description text
2. **Assignment Metadata Display**:
   - Subject, grade level, instructions, feedback tone
   - Clean, card-based layout
3. **Navigation Links**:
   - Link to rubric show page
   - Link to student work index  
   - Link to assignment summary page
4. **Visual Design**: Follow existing design system patterns and styling

### Form Integration

1. **Assignment Creation Form**: Use existing form fields (title, subject, grade level, instructions, feedback tone, Google Docs selection)
2. **Form Submission**: On submit, redirect to loading/progress page instead of assignment show page
3. **Background Processing**: Trigger Assignment Processor after form submission

## Non-Goals (Out of Scope)

1. **Real-time WebSocket updates** - Using periodic polling instead for simplicity
2. **Progress bar visualization** - Using step indicators only
3. **Error handling and recovery** - Will be addressed in future iterations
4. **Progress bar animation** - Step indicators provide sufficient feedback
5. **Access control changes** - Using existing permission system
6. **Editing capabilities** - Assignment editing remains unchanged
7. **Mobile-specific features** - Responsive design handles mobile needs

## Design Considerations

1. **Consistency**: Follow existing design patterns from current show page (app/views/assignments/show.html.erb)
2. **Visual Hierarchy**: Use established icon and color systems from the application
3. **Loading States**: Design should clearly communicate that processing is active
4. **Step Indicators**: Use numbered circles that transform to checkmarks for completion
5. **Typography**: Maintain consistent heading and text styling
6. **Spacing**: Follow existing card-based layout patterns
7. **Accessibility**: Ensure screen reader compatibility and keyboard navigation

## Technical Considerations

1. **Polling Implementation**: JavaScript polling mechanism every 1-3 seconds
   - Only use Stimulus
2. **Status Endpoint**: Create API endpoint that returns current processing status
3. **Database Queries**: Efficiently check completion status for each step:
   - Assignment exists: `Assignment.exists?(id)`
   - Rubric complete: Check for associated rubric with criteria and levels
   - Student work complete: Check that all student_works have grades
   - Summary complete: Check for assignment_summary record
4. **Assignment Processor Integration**: Leverage existing `broadcast_progress` and status management
5. **Routing**: Add new route for progress page, modify form submission redirect
6. **Progressive Enhancement**: Ensure basic functionality works without JavaScript
7. **Caching**: Consider caching status checks for performance

## Success Metrics

1. **User Experience**: Well-crafted UI that feels intuitive and professional
2. **Time to Complete**: Reduced perceived time from assignment creation to viewing results
3. **User Confusion**: Fewer support requests related to assignment creation workflow
4. **Completion Rate**: Higher percentage of teachers completing the full assignment creation process
5. **User Satisfaction**: Positive feedback on the streamlined interface

## Open Questions

1. **Timeout Handling**: What should happen if processing takes an unusually long time?
2. **Navigation During Processing**: Should users be able to navigate away from the progress page?
3. **Multiple Assignment Processing**: How should the system handle if users create multiple assignments simultaneously?
4. **Assignment Processor Failures**: While error handling is out of scope, should there be a basic "something went wrong" state?
5. **Polling Frequency**: Is 1-3 second polling optimal, or should it be adjusted based on processing stage?
6. **Progress Page URL**: Should the progress page have a unique URL that can be bookmarked/shared?