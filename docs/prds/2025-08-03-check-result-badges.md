# Product Requirements Document: Check Result Badges

**Date:** August 3, 2025  
**Feature:** Replace percentage scores with descriptive badges for plagiarism and AI detection checks

## Introduction/Overview

Currently, the student work show page displays plagiarism and AI detection results as exact percentage scores (e.g., "15%", "72%"). This creates a false impression of precision when these checks are actually indicative signals rather than exact measurements. This feature will replace percentage displays with descriptive badges (Low, Unclear, High) that better communicate the nature of these detection results.

**Goal:** Provide more appropriate visual representation of check results that accurately conveys the uncertainty inherent in plagiarism and AI detection systems.

## Goals

1. Replace misleading percentage precision with appropriate confidence level indicators
2. Maintain visual consistency with existing performance badge design system
3. Improve user understanding of check result reliability
4. Reduce false confidence in detection accuracy
5. Preserve clean, professional UI appearance

## User Stories

- **As a teacher**, I want to see plagiarism results as confidence levels (Low, Unclear, High) so that I understand these are indicative rather than precise measurements
- **As a teacher**, I want AI detection results presented as confidence levels so that I can make informed decisions without over-relying on specific percentages
- **As a teacher**, I want the new badges to visually integrate with the existing UI so that the interface remains clean and professional
- **As a teacher**, I want clear labeling so I understand what each confidence level means for student work assessment

## Functional Requirements

### Badge Categories and Thresholds
1. **Low Confidence Badge:** 0-33% (Green, text: "Low")
2. **Unclear Confidence Badge:** 34-66% (Gray, text: "Unclear") 
3. **High Confidence Badge:** 67-100% (Red, text: "High")
4. **No Data Badge:** When check data is unavailable (Gray, text: "No data")

### Visual Design Requirements
5. Badges must follow the same visual style as existing performance badges (Exceeds, Meets, etc.)
6. Use design system colors: Green (low), Gray (unclear/no data), Red (high)
7. Text-only badges without icons
8. Maintain consistent sizing with current performance badges
9. Preserve existing tile layout and spacing

### Content and Labeling
10. **Plagiarism Check Tile:**
    - Header: "Plagiarism check" with help icon linking to documentation
    - Badge: [Low/Unclear/High/No data]
    - Subtext: "Chance of plagiarism"

11. **AI Detection Tile:**
    - Header: "AI detection" with help icon linking to documentation
    - Badge: [Low/Unclear/High/No data] 
    - Subtext: "Chance of AI generated content"

### Data Handling
12. Apply same percentage thresholds to both plagiarism and AI detection checks
13. Handle missing/null data by displaying "No data" badge
14. Completely remove percentage number display

### Documentation and Help System
15. **Documentation Page Creation:**
    - Create `/docs` route with index and show pages
    - First documentation page explains check result badges (Low, Unclear, High meanings)
    - Clear explanations of what each confidence level indicates
    - **Design Reference**: Use UI2 design (3-step guide format) from `/ui_iterations/ui_2.html`
    - Structure: Learn badge types → Understand confidence → Take appropriate action
    - Quick reference section at top of action steps for busy teachers

16. **Help Icon Integration:**
    - Add question mark circle icon next to tile headers
    - Icons link to relevant documentation pages
    - Use existing design system icon conventions

## Non-Goals (Out of Scope)

- Modifying the underlying detection algorithms or data sources
- Changing the layout or positioning of the tiles (except for help icon addition)
- Adding icons to the badges themselves
- Modifying other percentage displays elsewhere in the application
- Adding user preferences for display format

## Design Considerations

- Badges should integrate seamlessly with existing `performance_badge` partial system
- Use existing design system color classes for consistency
- Maintain the current tile structure with header, main content, and subtext
- Ensure badges are sized consistently with performance badges on the same page

## Technical Considerations

### Badge Implementation
- Leverage existing `performance_badge_size_classes` helper for consistent sizing
- Create new helper methods for check result badge colors and text
- Modify student work show view template to use new badge rendering
- Consider creating a new partial for check result badges to maintain code organization
- Ensure proper handling of nil/missing check data
- Create `question-mark-circle` icon following existing icon conventions

### Documentation System Architecture
- **Simple Controller Approach**: Static content in ERB templates for minimal overhead
- **DocsController** with `show` action handling doc routing by ID parameter
- **Static Templates**: Content stored in `app/views/docs/` templates (e.g., `check_results.html.erb`)
- **Simple Routing**: `get '/docs/:id', to: 'docs#show', as: :doc`
- **Help Link Integration**: Direct links from tile headers to `doc_path('check-results')`
- **Future Migration Path**: Can easily upgrade to file-based or database system without breaking existing URLs

## Success Metrics

- **User Understanding:** Teachers report better understanding of check result reliability in user feedback
- **Visual Consistency:** New badges integrate seamlessly without visual disruption to existing UI
- **Reduced Confusion:** Decrease in support questions about exact percentage meanings
- **Implementation Quality:** No visual regressions in student work show page layout

## Decisions Made

- **No hover states or tooltips:** Help documentation links provide sufficient explanation
- **No changes to other percentage indicators:** Limiting scope to plagiarism and AI detection only
- **Documentation scope:** Check result badges documentation is the only doc page needed initially
- **Documentation design:** Selected UI2 design variant - clean 3-step guide without animations or interactive elements