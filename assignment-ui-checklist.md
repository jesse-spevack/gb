# Assignment Processing UI Checklist

Use this checklist to verify the UI updates correctly during assignment processing.

## Initial Submission & Redirect
- [x] After submitting assignment form, redirected to `/assignments/:id`
- [x] Page loads without errors
- [ ] Turbo Stream subscription established (check browser console for ActionCable connection)

## Progress Card Display
- [x] Blue progress card appears at top of page
- [x] Progress card shows:
  - [x] Overall progress percentage starting at 0%
    - Note: the progress never updates.
  - [ ] Three phase indicators: Rubric ⏳ | Student Works ⏳ | Summary ⏳
    - Note: Rubric shows `in_progress` forever.
    - 
  - [ ] Estimated completion time (e.g., "~2 minutes remaining")
    - Shows 0 seconds remaining 0 out of 5 steps complete
  - [ ] Current status message (e.g., "Creating rubric...")
    - No status message
- [x] Progress card has `data-turbo-permanent` attribute


## Rubric Processing Phase
- [ ] Progress card updates to show "Creating rubric..." message
- [ ] Rubric phase icon changes from ⏳ to animated spinner
  - Rubric only shows animated spinner
- [ ] Progress percentage increases
  - no
- [ ] When complete:
  - no
  - [ ] Rubric phase shows ✅ checkmark
  - [ ] Rubric tab gets green completion dot
  - [ ] Rubric content appears in rubric tab with fade-in animation
  - [ ] Rubric displays criteria and levels correctly

## Student Work Processing Phase
  - no
- [ ] Progress updates to "Processing student work..."
- [ ] Student Works phase icon shows animated spinner
- [ ] Progress shows count (e.g., "2 of 5 completed")
- [ ] For each student work:
  - [ ] Row shows spinning indicator while processing
  - [ ] Row updates with feedback when complete
  - [ ] Green checkmark appears when done
  - [ ] Feedback content fades in smoothly
- [ ] Overall progress percentage continues increasing

## Summary Generation Phase
  - no
- [ ] Progress updates to "Generating summary..."
- [ ] Summary phase icon shows animated spinner
- [ ] When complete:
  - [ ] Summary phase shows ✅ checkmark
  - [ ] Summary tab gets green completion dot
  - [ ] Summary content appears with class insights

## Completion State
  - no
- [ ] All three phases show ✅ checkmarks
- [ ] Progress card fades out after 3 seconds
- [ ] All content tabs are clickable and show data
- [ ] No loading spinners remain visible

## Connection Monitoring
  - no
- [ ] No yellow "Connection lost" banner appears
- [ ] Browser console shows ActionCable messages
- [ ] Updates arrive in real-time without page refresh

## Error Scenarios (if applicable)
- [ ] If processing fails, error message appears
- [ ] Failed phases show ❌ instead of ✅
- [ ] Error details are visible to user

## Additional Observations
- [ ] Animations are smooth (no jarring updates)
- [ ] Content appears without layout shift
- [ ] Mobile responsive (if testing on mobile)
- [ ] No JavaScript errors in browser console

---

## Notes Section
Use this space to note any unexpected behavior or issues:

### What worked as expected:
- Assignment was created
- All associated models were created
- LLM requests executed

### What didn't work as expected:
- No realtime UI updates

### Error messages or console warnings:
- None

### Suggestions for improvement:
- I want the UI to update without require the user to refresh


---

## Debug Information
If updates aren't working, check these:

1. **Browser Console**: Look for ActionCable connection logs
2. **Network Tab**: Check for WebSocket connection to `/cable`
3. **Rails Logs**: Look for broadcast messages like "Turbo::StreamsChannel transmitting"
4. **Background Jobs**: Ensure Solid Queue workers are running (`ps aux | grep solid_queue`)

## Better Ways to Help Debug

To help me understand current functionality better, you could:

1. **Record a screen capture** of the assignment creation flow
2. **Export browser console logs** during the process
3. **Share Rails server logs** from the assignment processing
4. **Take screenshots** at key moments (initial load, during processing, completion)
5. **Run this command** during processing to see real-time broadcasts:
   ```bash
   tail -f log/development.log | grep -E "(Broadcast|Turbo::StreamsChannel|AssignmentProcessor)"
   ```

This will help identify exactly which broadcasts are firing and which UI updates are missing.

---


```
I just tested the assignment creation and processing UI flow using the checklist in assignment-ui-checklist.md. Here are my findings:

**What worked:**
- Assignment was created
- All associated models were created
- LLM requests executed
**What didn't work:**
- No realtime UI updates
**Error messages/warnings:**
- None

**Additional context:**
- The expected behavior is documented in assignment-ui-checklist.md
- The UI should update in real-time using Turbo Streams and ActionCable
- Key files involved:
  - app/services/broadcast_service.rb (handles broadcasting)
  - app/services/progress_broadcast_service.rb (progress updates)
  - app/javascript/controllers/assignment_progress_controller.js (frontend)
  - app/views/assignments/show.html.erb (main view)
  - app/views/assignments/_progress_card.html.erb (progress UI)

**Rails log output during processing:**
- It wil be useful to view current development logs

Please help me:
1. Diagnose why the UI updates aren't working as expected
2. Fix the specific issues I encountered
3. Ensure all Turbo Stream broadcasts are firing correctly
4. Verify the ActionCable connection is established and stable

The assignment processing backend is working (jobs complete successfully), but the real-time UI updates need attention.
```