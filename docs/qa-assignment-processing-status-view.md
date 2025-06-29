# QA Plan: Assignment Processing Status View

## Overview
This QA plan covers manual testing of the Assignment Processing Status View feature implementation. Execute these test scenarios in your browser to verify all functionality works as expected.

## Prerequisites
- Local development environment running
- At least one assignment with student works created
- Google Docs integration functional
- Database seeded with test data

## Test Environment Setup
1. Start the Rails server: `bin/rails server`
2. Navigate to: `http://localhost:3000`
3. Sign in with Google OAuth
4. Have browser developer tools open to monitor network requests and console

---

## Test Suite 1: Basic Progress Display

### Test 1.1: Initial Progress Card Display
**Objective**: Verify progress card appears and shows correct initial state

**Steps**:
1. Create a new assignment with 2-3 student works
2. Navigate to the assignment show page immediately after creation
3. Verify progress card is visible at the top of the page

**Expected Results**:
- [ ] Progress card displays with "Processing Progress" header
- [ ] Overall percentage shows (likely 0% initially)
- [ ] Three phase indicators visible: Rubric, Student Work, Summary
- [ ] Rubric phase shows "pending" (gray dot)
- [ ] Student Work phase shows "pending" (gray dot)
- [ ] Summary phase shows "pending" (gray dot)
- [ ] Progress bar width matches percentage
- [ ] ETA display shows estimated time remaining

### Test 1.2: Progress Card Responsiveness
**Objective**: Verify progress card adapts to different screen sizes

**Steps**:
1. View assignment show page on desktop (full width)
2. Resize browser to tablet width (~768px)
3. Resize browser to mobile width (~375px)

**Expected Results**:
- [ ] **Desktop**: 3-column phase layout, full padding
- [ ] **Tablet**: 3-column phase layout, medium padding
- [ ] **Mobile**: 1-column phase layout, reduced padding
- [ ] All text remains readable at all sizes
- [ ] Progress bar maintains proper proportions

---

## Test Suite 2: Real-Time Progress Updates

### Test 2.1: Rubric Generation Phase
**Objective**: Verify real-time updates during rubric generation

**Steps**:
1. Create a new assignment (trigger processing)
2. Immediately navigate to assignment show page
3. Watch for rubric phase updates

**Expected Results**:
- [ ] Rubric phase initially shows "pending" status
- [ ] Phase changes to "in_progress" with spinning indicator
- [ ] Overall progress bar updates from 0%
- [ ] When complete: green checkmark appears
- [ ] Rubric tab indicator shows green dot
- [ ] Rubric content becomes available in Rubric section
- [ ] No page refresh required for updates

### Test 2.2: Student Work Processing Phase
**Objective**: Verify individual student work status updates

**Steps**:
1. Navigate to "Student Work" tab during processing
2. Observe individual student work rows
3. Watch status changes in real-time

**Expected Results**:
- [ ] Each student work shows initial "Pending" status
- [ ] Status changes to processing animation when active
- [ ] "Generating student feedback (X of Y)" message updates
- [ ] Individual rows update with completion status
- [ ] Green checkmarks appear for completed works
- [ ] Student work count in phase indicator updates
- [ ] Overall progress percentage increases with each completion

### Test 2.3: Assignment Summary Phase
**Objective**: Verify summary generation updates

**Steps**:
1. Wait for all student works to complete processing
2. Watch summary phase status
3. Check summary tab indicator

**Expected Results**:
- [ ] Summary phase shows "in_progress" with spinner
- [ ] "Creating assignment summary..." message appears
- [ ] Summary tab indicator shows green dot when complete
- [ ] Overall progress reaches 100%
- [ ] Summary content becomes available

---

## Test Suite 3: Error State Handling

### Test 3.1: Simulate Processing Failure
**Objective**: Test error display and recovery

**Note**: This may require simulating errors through database manipulation or by interrupting processing.

**Steps**:
1. Create assignment and start processing
2. Simulate a failure condition (if possible)
3. Observe error state display

**Expected Results**:
- [ ] Failed phase shows red X indicator
- [ ] Error message displays clearly
- [ ] Processing continues for remaining items (partial failure)
- [ ] User is informed about the failure
- [ ] Recovery guidance is provided

### Test 3.2: Individual Student Work Failure
**Objective**: Test partial failure handling

**Steps**:
1. If possible, simulate one student work failing
2. Verify system continues processing others

**Expected Results**:
- [ ] Failed student work shows red error indicator
- [ ] Error message appears below failed work
- [ ] Other student works continue processing
- [ ] Summary still generates with successful works
- [ ] Overall progress accounts for failures

---

## Test Suite 4: Connection Failure Handling

### Test 4.1: TurboStream Connection Loss
**Objective**: Test fallback polling mechanism

**Steps**:
1. Start assignment processing
2. Open browser Network tab
3. Throttle network to "Slow 3G" or disable TurboStream connections
4. Observe fallback behavior

**Expected Results**:
- [ ] Yellow connection status banner appears
- [ ] "Connection lost - using fallback updates" message shows
- [ ] Progress continues updating every 10 seconds via polling
- [ ] Console shows fallback polling activity
- [ ] When connection restores, banner disappears

### Test 4.2: Complete Network Interruption
**Objective**: Test behavior during total network loss

**Steps**:
1. Start assignment processing
2. Disconnect internet completely for 30 seconds
3. Reconnect and observe recovery

**Expected Results**:
- [ ] Connection status indicator appears
- [ ] Polling attempts continue (will fail)
- [ ] Upon reconnection, updates resume
- [ ] No data loss or corruption
- [ ] User is informed of connection issues

---

## Test Suite 5: Mobile Responsiveness

### Test 5.1: Mobile Layout Verification
**Objective**: Test mobile-specific optimizations

**Steps**:
1. Open assignment show page on mobile device or mobile emulator
2. Test all interactive elements
3. Verify touch targets are adequate

**Expected Results**:
- [ ] Progress phases stack vertically on mobile
- [ ] Navigation tabs scroll horizontally if needed
- [ ] All buttons have minimum 44x44px touch targets
- [ ] Text remains readable
- [ ] No horizontal scrolling required
- [ ] Spacing is appropriate for mobile

### Test 5.2: Touch Target Testing
**Objective**: Verify all interactive elements are touch-friendly

**Steps**:
1. Use mobile device or touch emulator
2. Test tapping all interactive elements:
   - Navigation tabs
   - Back button
   - View buttons on student works
   - Delete button

**Expected Results**:
- [ ] All elements respond to touch accurately
- [ ] No accidental taps on adjacent elements
- [ ] Touch feedback is appropriate
- [ ] Elements are sized appropriately for fingers

---

## Test Suite 6: Performance and UX

### Test 6.1: Animation Smoothness
**Objective**: Verify smooth animations and transitions

**Steps**:
1. Watch progress bar animations during updates
2. Observe phase transitions
3. Check for layout shifts

**Expected Results**:
- [ ] Progress bar animates smoothly (no jumping)
- [ ] Phase indicators transition cleanly
- [ ] No jarring layout shifts during updates
- [ ] Fade-in effects work properly
- [ ] Spinning indicators animate continuously

### Test 6.2: Information Clarity
**Objective**: Test information presentation

**Steps**:
1. Review all status messages
2. Check progress indicators
3. Verify ETA accuracy

**Expected Results**:
- [ ] Status messages are clear and informative
- [ ] Progress percentages are accurate
- [ ] ETA updates as processing progresses
- [ ] Phase statuses are unambiguous
- [ ] Error messages provide actionable information

---

## Test Suite 7: Cross-Browser Compatibility

### Test 7.1: Browser Testing
**Objective**: Verify functionality across browsers

**Browsers to Test**:
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (if on Mac)
- [ ] Edge (if on Windows)

**Test Steps**:
1. Open assignment processing in each browser
2. Verify TurboStream functionality
3. Test responsive behavior
4. Check JavaScript console for errors

**Expected Results**:
- [ ] All features work consistently across browsers
- [ ] No JavaScript errors in console
- [ ] Animations work in all browsers
- [ ] WebSocket connections establish properly

---

## Test Suite 8: Edge Cases

### Test 8.1: No Student Works
**Objective**: Test assignment with zero student works

**Steps**:
1. Create assignment without adding student works
2. Observe processing behavior

**Expected Results**:
- [ ] Processing completes gracefully
- [ ] Appropriate messaging for empty assignment
- [ ] No errors in student work phase
- [ ] Summary still generates

### Test 8.2: Very Large Assignment
**Objective**: Test with many student works (if feasible)

**Steps**:
1. Create assignment with maximum allowed student works
2. Monitor performance and UI behavior

**Expected Results**:
- [ ] UI remains responsive
- [ ] Progress updates efficiently
- [ ] No performance degradation
- [ ] Scrolling works smoothly in student work list

### Test 8.3: Page Refresh During Processing
**Objective**: Test state persistence

**Steps**:
1. Start assignment processing
2. Refresh the page mid-processing
3. Verify state recovery

**Expected Results**:
- [ ] Progress state loads correctly after refresh
- [ ] TurboStream connection re-establishes
- [ ] Processing continues seamlessly
- [ ] No duplicate updates occur

---

## Test Suite 9: Accessibility

### Test 9.1: Keyboard Navigation
**Objective**: Test keyboard accessibility

**Steps**:
1. Navigate entire interface using only keyboard
2. Test tab order and focus indicators

**Expected Results**:
- [ ] All interactive elements accessible via keyboard
- [ ] Tab order is logical
- [ ] Focus indicators are visible
- [ ] No keyboard traps

### Test 9.2: Screen Reader Compatibility
**Objective**: Test with screen reader (if available)

**Steps**:
1. Enable screen reader
2. Navigate through progress interface
3. Listen to announcements

**Expected Results**:
- [ ] Progress updates are announced
- [ ] Status changes are communicated
- [ ] All content is readable
- [ ] Semantic structure is clear

---

## Bug Reporting Template

When a test fails, document using this template:

```
**Test Case**: [Test number and name]
**Browser/Device**: [Browser version and device info]
**Steps to Reproduce**:
1. 
2. 
3. 

**Expected Result**: 
**Actual Result**: 
**Screenshots/Video**: [If applicable]
**Console Errors**: [Any JavaScript errors]
**Additional Notes**: 
```

---

## Test Completion Checklist

After completing all tests:

- [ ] All core functionality works as expected
- [ ] Real-time updates function properly
- [ ] Error states display correctly
- [ ] Mobile responsiveness is adequate
- [ ] Connection fallbacks work
- [ ] Performance is acceptable
- [ ] No critical bugs found
- [ ] Documentation updated if needed

## Notes
- Some tests may require simulating specific conditions
- Network throttling tools in browser dev tools are helpful
- Consider testing during actual processing workloads
- Document any performance issues or unexpected behaviors