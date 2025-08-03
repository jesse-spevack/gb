# Rubric Toggle Feature Documentation

## Overview

The rubric toggle feature allows users to choose between AI-generated rubrics and manually pasted rubrics in the assignment creation form. This feature has been temporarily disabled to simplify the user experience during initial testing phases.

## Current Status

**Status**: Temporarily Disabled (August 2025)  
**Reason**: Simplified UX for initial user testing and demos  
**Infrastructure**: Fully preserved and ready for re-enablement

## Re-enabling the Feature

To re-enable the rubric toggle functionality, follow these steps:

### 1. Update the Assignment Form View

In `app/views/assignments/new.html.erb`, add the following data attributes to the rubric card div (around line 78):

```erb
<div class="bg-white rounded-lg shadow-md p-6 transition-all hover:shadow-lg" 
     data-controller="rubric-toggle"
     data-rubric-toggle-switch-active-class="bg-blue-600"
     data-rubric-toggle-switch-inactive-class="bg-gray-200"
     data-rubric-toggle-knob-active-class="translate-x-5"
     data-rubric-toggle-knob-inactive-class="translate-x-0"
     data-rubric-toggle-textarea-disabled-class="bg-gray-100"
     data-rubric-toggle-text-light-class="text-gray-500"
     data-rubric-toggle-hidden-class="hidden">
```

### 2. Restore Toggle Button Functionality

Update the toggle button to remove the disabled state and restore click handling:

```erb
<button type="button"
  id="rubric-toggle-switch"
  class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent bg-blue-600 transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-blue-600 focus:ring-offset-2" 
  role="switch"
  aria-checked="true" 
  aria-labelledby="rubric-toggle-label"
  data-action="click->rubric-toggle#toggle" 
  data-rubric-toggle-target="switch">
```

### 3. Restore Data Targets

Add back the data-rubric-toggle-target attributes:

```erb
<!-- Generate Label -->
<span class="text-sm font-medium text-gray-900 flex items-center gap-1" 
      id="rubric-generate-label" 
      data-rubric-toggle-target="generateLabel">

<!-- Paste Label -->
<span class="text-sm font-medium text-gray-900 flex items-center gap-1 hidden" 
      id="rubric-paste-label" 
      data-rubric-toggle-target="pasteLabel">

<!-- Toggle Knob -->
<span aria-hidden="true" 
      id="rubric-toggle-knob" 
      class="pointer-events-none inline-block h-5 w-5 translate-x-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out" 
      data-rubric-toggle-target="knob">

<!-- Textarea -->
<%= form.text_area :raw_rubric_text, 
      data: { rubric_toggle_target: "textarea" } %>
```

### 4. Unhide the Textarea

Remove the "hidden" class from the textarea container:

```erb
<!-- Change from: -->
<div class="hidden">

<!-- To: -->
<div>
```

### 5. Update Explanatory Text

Change the explanatory text back to the original:

```erb
<p class="text-sm text-gray-500 mb-4">
  Choose how to provide the grading rubric. You can generate one using AI based on the assignment details or paste your own.
</p>
```

### 6. Remove Controller Comment

Remove or update the comment at the top of `app/javascript/controllers/rubric_toggle_controller.js`:

```javascript
// Remove this line:
// This controller is temporarily disabled. To re-enable, add these attributes...
```

## Data Attributes Reference

| Attribute | Purpose | Value |
|-----------|---------|-------|
| `data-controller` | Connects Stimulus controller | `"rubric-toggle"` |
| `data-rubric-toggle-switch-active-class` | Active toggle background | `"bg-blue-600"` |
| `data-rubric-toggle-switch-inactive-class` | Inactive toggle background | `"bg-gray-200"` |
| `data-rubric-toggle-knob-active-class` | Active knob position | `"translate-x-5"` |
| `data-rubric-toggle-knob-inactive-class` | Inactive knob position | `"translate-x-0"` |
| `data-rubric-toggle-textarea-disabled-class` | Disabled textarea styling | `"bg-gray-100"` |
| `data-rubric-toggle-text-light-class` | Muted text styling | `"text-gray-500"` |
| `data-rubric-toggle-hidden-class` | Hidden element class | `"hidden"` |

## Stimulus Targets

| Target | Element | Purpose |
|--------|---------|---------|
| `switch` | Toggle button | Main toggle control |
| `knob` | Toggle knob span | Visual knob that moves |
| `generateLabel` | Generate label span | "Generate rubric" text |
| `pasteLabel` | Paste label span | "Paste rubric" text |
| `textarea` | Textarea input | Manual rubric input field |

## Testing

After re-enabling, test the following:

1. **Toggle Functionality**: Click the toggle switch and verify it changes between states
2. **Visual States**: Ensure the toggle shows correct active/inactive styling
3. **Label Switching**: Verify labels change between "Generate rubric" and "Paste rubric"
4. **Textarea States**: Confirm textarea enables/disables based on toggle state
5. **Form Submission**: Test that both generated and pasted rubrics submit correctly
6. **Accessibility**: Verify screen readers can interact with the toggle properly

## Files Involved

- `app/views/assignments/new.html.erb` - Main form view
- `app/javascript/controllers/rubric_toggle_controller.js` - Stimulus controller
- `app/models/assignment.rb` - Backend model (already supports rubric_text field)

## Database Schema

The `assignments` table already includes the `rubric_text` field:

```ruby
t.text "rubric_text"
```

No database migrations are required for re-enablement.

## Decision History

- **August 2025**: Temporarily disabled for initial user testing
- **Original Implementation**: Full toggle functionality between AI and manual rubrics
- **Future**: Re-enable when manual rubric processing is fully supported