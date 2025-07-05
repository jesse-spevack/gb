# Assignment Progress Stepper

**Date:** 2025-01-14  
**Author:** Development Team  
**Status:** Planning

## Introduction/Overview

The assignment processing progress stepper provides users with clear, real-time visual feedback during AI-powered assignment processing. This feature replaces the current complicated and broken UX with a simplified 4-step progress indicator that shows users exactly what GradeBot is doing and how long it will take.

The current system uses complex broadcasting mechanisms that are unreliable and difficult to maintain. Users are left confused about processing status, leading to page refreshes, support tickets, and poor user experience.

## Goals

1. **Simplify Progress Communication**: Replace complex broadcasting with clear, visual progress steps
2. **Improve User Experience**: Eliminate confusion about processing time and status
3. **Reduce Support Load**: Decrease user-generated support tickets related to processing concerns
4. **Increase User Confidence**: Help users understand that GradeBot is actively working
5. **Enable Real-time Updates**: Provide accurate progress tracking based on actual backend processing

## User Stories

**As an educator using GradeBot, I want to:**
- See clear visual progress when my assignment is being processed
- Understand what specific task GradeBot is currently performing
- Know approximately how much time remains in the processing
- Feel confident that the system is working and hasn't frozen
- Navigate away and return to see current progress status

**As a product manager, I want to:**
- Reduce user confusion and support tickets related to processing
- Have reliable progress tracking that works across browser sessions
- Enable users to understand the value GradeBot provides during processing

## Functional Requirements

### Core Progress Display
1. **The system must display a 4-step visual progress indicator** showing:
   - Step 1: "Assignment Saved"
   - Step 2: "Creating Rubric"  
   - Step 3: "Grading Work"
   - Step 4: "Generating Summary"

2. **The system must show visual states for each step**:
   - Not Started: Gray circle with black number
   - In Progress: Blue circle with white number
   - Completed: Blue circle with white checkmark, muted text

3. **The system must display connecting lines** between steps that change from gray to blue as steps complete

4. **The system must show responsive design**:
   - Mobile: Vertical stack layout
   - Desktop: Horizontal layout with connecting lines

### Status Communication
5. **The system must display status text** below the progress indicator:
   - "Saving assignment..."
   - "GradeBot is generating a rubric..."
   - "GradeBot is analyzing student work..."
   - "GradeBot is summarizing analysis..."
   - "Assignment processing complete!"

6. **The system must show a spinner** during active processing steps

7. **The system must hide the spinner** when processing is complete

### Real-time Progress Tracking
8. **The system must create ProcessingStep records** in the database during AssignmentProcessor execution

9. **The system must poll for progress updates** via a new API endpoint that returns current processing steps

10. **The system must load existing progress** when users navigate to the assignment page

11. **The system must handle processing failures** gracefully with appropriate error messaging

### Data Model
12. **ProcessingStep model must include**:
    - `assignment_id` (foreign key)
    - `step_name` (enum: assignment_saved, creating_rubric, grading_work, generating_summary)
    - `started_at` (timestamp)
    - `ended_at` (timestamp, nullable)
    - `status` (enum: pending, in_progress, completed, failed)

## Non-Goals (Out of Scope)

- Real-time WebSocket connections
- Detailed progress percentages within each step
- Estimated time remaining calculations
- Ability to cancel processing mid-stream
- Historical progress tracking for completed assignments
- Integration with external progress tracking services

## Alternative Approaches

### Option 1: Timer-Based Animation (Current Prototype)
**Description**: Use JavaScript timers to simulate progress over fixed intervals.

**Pros**:
- Simple to implement
- No backend changes required
- Consistent timing regardless of actual processing
- Works offline for demonstration

**Cons**:
- Not reflective of actual progress
- Misleading to users
- No resilience to page refreshes
- Cannot handle processing failures
- Provides false sense of progress

### Option 2: WebSocket Real-time Updates
**Description**: Use WebSockets to push real-time updates from AssignmentProcessor to the frontend.

**Pros**:
- True real-time updates
- No polling overhead
- Immediate progress reflection
- Maintains existing broadcasting architecture

**Cons**:
- Complex infrastructure requirements
- WebSocket connection management challenges
- Scaling concerns with many concurrent users
- Connection reliability issues
- Increased system complexity

### Option 3: Database + Polling (Recommended)
**Description**: Store processing steps in database, poll via REST API for updates.

**Pros**:
- Simple, reliable architecture
- Survives page refreshes and navigation
- Easy to debug and monitor
- Scales well with existing infrastructure
- Clear separation of concerns
- Testable and maintainable

**Cons**:
- Slight delay in updates (polling interval)
- Additional database storage requirements
- Need to implement cleanup for old records

### Option 4: Server-Sent Events (SSE)
**Description**: Use SSE to stream progress updates from server to client.

**Pros**:
- Real-time updates
- Simpler than WebSockets
- HTTP-based (easier to debug)
- Automatic reconnection

**Cons**:
- Browser connection limits
- Doesn't survive page refreshes
- Additional complexity over polling
- Less widely supported than standard HTTP

## Recommended Solution: Database + Polling

After evaluating all options, **Database + Polling (Option 3)** is the best approach because:

1. **Reliability**: Progress survives page refreshes, browser crashes, and navigation
2. **Simplicity**: Uses existing HTTP/REST infrastructure
3. **Maintainability**: Easy to debug, test, and modify
4. **Scalability**: Fits well with current Rails architecture
5. **User Experience**: Provides accurate, persistent progress tracking

### Implementation Details

**Backend Changes**:
- Create `ProcessingStep` model
- Modify `AssignmentProcessor` to create/update steps instead of broadcasting
- Add REST endpoint: `GET /assignments/:id/processing_steps`

**Frontend Changes**:
- Update Stimulus controller to poll endpoint every 2 seconds
- Replace timer-based animation with real progress updates
- Handle loading existing steps on page load

## Technical Considerations

- **Database Performance**: Index `assignment_id` and `started_at` for efficient queries
- **Cleanup Strategy**: Implement job to clean up old ProcessingStep records
- **Error Handling**: Handle API failures gracefully with fallback states
- **Polling Frequency**: Balance between responsiveness and server load (2-second intervals recommended)
- **Caching**: Consider caching step data to reduce database load

## Success Metrics

- **User Experience**: 90% reduction in support tickets related to processing confusion
- **Technical Reliability**: 99.9% uptime for progress tracking functionality
- **User Engagement**: Users stay on assignment page during processing instead of navigating away
- **Performance**: Progress updates delivered within 5 seconds of actual backend changes
- **Launch Success**: Feature deployed without rollback within 2 weeks

## Open Questions

1. Should we implement automatic polling stop after completion, or continue polling for a period?
2. What's the appropriate cleanup schedule for old ProcessingStep records?
3. Should we track sub-steps within "Grading Work" for assignments with many students?
4. How should we handle processing that takes longer than expected?
5. Should we store processing duration metrics for future estimation features?

## Design Considerations

- Follow existing GradeBot design system (blue primary color, consistent spacing)
- Ensure accessibility compliance with proper ARIA labels
- Maintain responsive design across all device sizes
- Use Tailwind CSS classes consistent with existing codebase
- Integrate with existing Stimulus controller architecture 