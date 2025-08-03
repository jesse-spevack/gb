# Task List: Rubric Toggle Simplification

**Generated**: 2025-08-03  
**Based on PRD**: 2025-08-03-rubric-toggle-simplification.md  
**Estimated Total**: 2-3 days

## Architecture Overview

This feature modifies the assignment creation form to simplify the rubric input section. The toggle switch will be permanently set to "on" and disabled, while the textarea for manual rubric input will be removed from user interaction. The Stimulus controller will be updated to prevent toggle state changes while maintaining the visual component for future re-enablement.

## File Planning

### Modified Files
- `app/views/assignments/new.html.erb` - Update rubric section HTML structure and text
- `app/javascript/controllers/rubric_toggle_controller.js` - Disable toggle functionality
- `docs/changelog.md` - Document the feature change
- `spec/features/assignment_creation_spec.rb` - Update feature tests (if exists)
- `spec/javascript/controllers/rubric_toggle_controller_spec.js` - Update controller tests (if exists)

### No New Files Required
This is a simplification feature that modifies existing functionality rather than adding new components.

## Implementation Tasks

### Phase 1: View Updates (P0)

- [ ] **1.1** Update rubric section text and structure `[Simple]`
  - **Dependencies**: None
  - **Files**: `app/views/assignments/new.html.erb` (lines 91)
  - **Description**: 
    - Keep the "Rubric" heading (line 89) as is
    - Update the paragraph text on line 91 from "Choose how to provide the grading rubric. You can generate one using AI based on the assignment details or paste your own." to "GradeBot will generate an AI rubric based on your assignment details."
    - This is the gray explanatory text below the Rubric heading
  - **Testing**: Visual verification, ensure form still renders correctly

- [ ] **1.2** Disable toggle interaction in HTML `[Simple]`
  - **Dependencies**: None
  - **Files**: `app/views/assignments/new.html.erb`
  - **Description**: 
    - Add appropriate HTML attributes to disable the toggle switch
    - Ensure toggle appears in "on" state visually
    - Add visual indicators (cursor style, opacity) for disabled state
  - **Testing**: Manual interaction test, verify toggle cannot be clicked

- [ ] **1.3** Update textarea placeholder and disable state `[Simple]`
  - **Dependencies**: None
  - **Files**: `app/views/assignments/new.html.erb`
  - **Description**: 
    - Update placeholder text to indicate AI generation only
    - Ensure textarea is permanently disabled
    - Consider hiding textarea entirely or showing informational message
  - **Testing**: Verify textarea state and placeholder text

### Phase 2: JavaScript Updates (P1)

- [ ] **2.1** Detach Stimulus controller from HTML `[Simple]`
  - **Dependencies**: Requires 1.1, 1.2
  - **Files**: `app/views/assignments/new.html.erb` (line 79)
  - **Description**: 
    - Remove `data-controller="rubric-toggle"` from the rubric card div
    - Remove all other `data-rubric-toggle-*` attributes from the card
    - This will prevent the JavaScript from attaching to the HTML elements
  - **Testing**: Manual verification that toggle no longer responds to clicks

- [ ] **2.2** Add documentation comment to Stimulus controller `[Simple]`
  - **Dependencies**: Requires 2.1
  - **Files**: `app/javascript/controllers/rubric_toggle_controller.js`
  - **Description**: 
    - Add comment at top of file: "// This controller is temporarily disabled. To re-enable: add data-controller='rubric-toggle' to the rubric card div in app/views/assignments/new.html.erb"
    - No functional changes to the controller code itself
  - **Testing**: None required

### Phase 3: Documentation & Testing (P1)

- [ ] **3.1** Update changelog with feature change `[Simple]`
  - **Dependencies**: Requires 2.1, 2.2
  - **Files**: `docs/changelog.md`
  - **Description**: 
    - Add entry for 2025-08-03
    - Document the deliberate simplification for demo purposes
    - Note that infrastructure is preserved for future use
  - **Testing**: Markdown formatting verification

- [ ] **3.2** Run full test suite and fix any breaks `[Medium]`
  - **Dependencies**: Requires all previous tasks
  - **Files**: Various test files
  - **Description**: 
    - Run `bin/check` to execute all tests
    - Fix any feature tests that expect toggle functionality
    - Ensure Rubocop and Brakeman pass
  - **Testing**: Full test suite must pass

### Phase 4: Polish & Edge Cases (P2)

- [ ] **4.1** Add visual polish for disabled state `[Simple]`
  - **Dependencies**: Requires 3.2
  - **Files**: `app/views/assignments/new.html.erb`
  - **Description**: 
    - Ensure disabled toggle follows design system guidelines
    - Consider adding subtle visual cues (e.g., lock icon)
    - Verify mobile responsiveness
  - **Testing**: Cross-browser visual testing

- [ ] **4.2** Verify form submission behavior `[Simple]`
  - **Dependencies**: Requires 3.2
  - **Files**: Browser testing only
  - **Description**: 
    - Test full assignment creation flow
    - Ensure form submits successfully without rubric text
    - Verify no validation errors occur
    - Check that rubric is generated as expected
  - **Testing**: End-to-end manual testing

## Development Notes

### Testing Strategy
- Focus on visual regression - the form should look intentional, not broken
- Ensure all existing assignment creation flows continue to work
- Test with keyboard navigation to ensure accessibility
- Run `bin/check` before any commits

### Key Considerations
- This is a deliberate UX simplification, not a bug fix
- The disabled state should communicate "coming soon" rather than "broken"
- All infrastructure must remain in place for easy re-enablement
- The change should feel polished despite being a restriction

### Implementation Tips
1. Start with the view changes to get visual feedback quickly
2. Test the form submission early to ensure no breaking changes
3. Keep git commits small and focused on each task
4. Consider taking screenshots before/after for the changelog

### Potential Gotchas
- Ensure the Stimulus controller doesn't throw errors when disabled
- Watch for any CSS classes that might be toggled dynamically
- Test that the form's `raw_rubric_text` field submits as empty/null
- Verify no JavaScript console errors appear