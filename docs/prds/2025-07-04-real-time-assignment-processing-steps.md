# Real-Time Assignment Processing Steps

## Overview
Replace the hard-coded time-based transitions in the assignment processing UI with real-time state updates from the backend. This will make the UI accurately reflect the actual processing status and be resilient to page refreshes and browser sessions.

## Background
Currently, the assignment show page displays a 4-step progress indicator that transitions through states based on hard-coded timers in JavaScript. While this provides a good UX mockup, it doesn't reflect the actual backend processing state. The backend already processes assignments through multiple stages (rubric generation, student work grading, summary generation) using the AssignmentProcessor service.

## Goals
1. Make the UI accurately reflect real backend processing state
2. Ensure state persistence across page refreshes and browser sessions
3. Use Rails 8 conventions (Turbo Streams, Stimulus)
4. Keep implementation simple and extensible for future enhancements
5. Maintain the current polished UI experience

## Non-Goals
1. Error handling in the UI (will log errors but not display error states)
2. Granular progress within each step (e.g., individual student processing)
3. Modifying the visual design of the progress indicator

## Design

### Data Model
Create a new `ProcessingStep` model to track the state of each processing step:

```ruby
class ProcessingStep < ApplicationRecord
  belongs_to :assignment
  
  STEP_KEYS = [
    'assignment_saved',
    'creating_rubric',
    'generating_feedback', 
    'summarizing_feedback'
  ].freeze
  
  enum status: {
    pending: 0,
    in_progress: 1,
    completed: 2
  }
  
  validates :step_key, presence: true, inclusion: { in: STEP_KEYS }
  validates :step_key, uniqueness: { scope: :assignment_id }
end
```

Migration:
```ruby
create_table :processing_steps do |t|
  t.references :assignment, null: false, foreign_key: true
  t.string :step_key, null: false
  t.integer :status, default: 0, null: false
  t.datetime :started_at
  t.datetime :completed_at
  t.jsonb :metadata, default: {}
  t.timestamps
  
  t.index [:assignment_id, :step_key], unique: true
end
```

### Backend Implementation

1. **Step Creation**: When an assignment is created, immediately create all 4 ProcessingStep records with status `pending`

2. **Step Updates**: AssignmentProcessor will update steps at key points:
   - Start of processing → mark 'assignment_saved' as completed
   - Before rubric generation → mark 'creating_rubric' as in_progress
   - After rubric generation → mark 'creating_rubric' as completed, 'generating_feedback' as in_progress
   - After student work processing → mark 'generating_feedback' as completed, 'summarizing_feedback' as in_progress
   - After summary generation → mark 'summarizing_feedback' as completed

3. **Broadcasting**: Each step update will broadcast a Turbo Stream update:
   ```ruby
   Turbo::StreamsChannel.broadcast_replace_to(
     "assignment_#{assignment.id}_steps",
     target: "assignment-processing-steps",
     partial: "assignments/processing_steps",
     locals: { 
       assignment: assignment,
       processing_steps: assignment.processing_steps.ordered
     }
   )
   ```

### Frontend Implementation

1. **Turbo Stream Subscription**: Add to show.html.erb:
   ```erb
   <%= turbo_stream_from "assignment_#{@assignment.id}_steps" %>
   ```

2. **HTML Structure**: Replace current static HTML with a partial that renders based on ProcessingStep data:
   ```erb
   <div id="assignment-processing-steps" 
        data-controller="assignment-processor"
        data-assignment-processor-steps-value="<%= processing_steps.to_json %>">
     <!-- Render steps based on processing_steps data -->
   </div>
   ```

3. **Stimulus Controller**: Update to:
   - Remove timer-based transitions
   - Add value tracking for steps data
   - Update UI when steps value changes
   - Keep animation/transition logic for smooth visual updates

### Technical Architecture

```
[Assignment Created] 
    ↓
[Create 4 ProcessingSteps (pending)]
    ↓
[AssignmentProcessor Job]
    ├─→ [Update Step 1: completed]
    ├─→ [Broadcast Turbo Stream]
    ├─→ [Update Step 2: in_progress]
    ├─→ [Broadcast Turbo Stream]
    └─→ ... (continue for each step)
         ↓
[Browser receives Turbo Stream]
    ↓
[DOM updated with new partial]
    ↓
[Stimulus controller reacts to DOM change]
    ↓
[Visual transitions applied]
```

## Implementation Plan

1. Create ProcessingStep model and migration
2. Update AssignmentProcessor to create and update steps
3. Create processing_steps partial
4. Update assignment show view with Turbo Stream subscription
5. Update Stimulus controller to work with real data
6. Remove old artifacts (ProgressCalculator, sample broadcasts)
7. Test full flow with real processing

## Future Extensibility

The `metadata` jsonb field on ProcessingStep allows for future enhancements:
- Track individual student processing progress
- Store error information
- Add timing metrics
- Include additional state information

## Success Metrics

1. UI accurately reflects backend processing state
2. State persists across page refreshes
3. No regression in visual polish or user experience
4. Clean, maintainable code following Rails conventions