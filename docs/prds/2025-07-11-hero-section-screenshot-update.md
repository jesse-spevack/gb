# Hero Section Screenshot Update PRD

## Introduction/Overview

Update the hero section screenshot in the landing page (`views/home/index.html.erb`) to accurately represent the actual product functionality. The current hero section contains a hardcoded HTML mockup that doesn't reflect the real Assignment Summary view that users experience. This update will replace the inaccurate representation with the design from `ui_1.html`, which showcases the actual Assignment Summary functionality.

**Goal:** Improve landing page conversion rate by showing visitors an accurate representation of the product's core value proposition through real assignment summary analytics.

## Goals

1. Replace the current hardcoded HTML mockup with the Assignment Summary design from `ui_1.html`
2. Maintain all existing hero section elements (logo, headlines, CTA button)
3. Follow the established design system guidelines for consistency
4. Improve conversion rate by showing accurate product representation
5. Maintain responsive design across all device sizes

## User Stories

**As a potential customer visiting the landing page:**
- I want to see what the actual product looks like so that I can understand its value before signing up
- I want to see realistic assignment data so that I can envision how it would work with my classes
- I want the demo to be visually appealing and professional so that I trust the product quality

**As a marketing team member:**
- I want the hero section to accurately represent our product so that we set proper expectations
- I want to improve our conversion rate by showing compelling real functionality
- I want the update to be maintainable and aligned with our design system

## Functional Requirements

1. **Replace Screenshot Content**: Remove the existing hardcoded HTML mockup (lines 52-153 in current `views/home/index.html.erb`) and replace with the Assignment Summary design from `ui_1.html`

2. **Preserve Hero Structure**: Maintain the existing hero section layout including:
   - GradeBot logo and positioning
   - "Your AI feedback assistant" headline
   - "Transform hours of grading into minutes of strategic review" subheadline  
   - "Start saving time today" CTA button with Google sign-in styling
   - Blue gradient background pattern

3. **Assignment Summary Content**: Include the following hardcoded data elements from `ui_1.html`:
   - Assignment title: "Persuasive Essay Assignment"
   - 28 student submissions
   - Performance distribution: 29% Exceeds, 46% Meets, 18% Approaching, 7% Below
   - Overall class average: 3.1/4
   - Key insights text: "Students demonstrated strong understanding of persuasive techniques..."
   - Strengths section with 3 bullet points
   - Growth areas section with 3 bullet points
   - Generation time indicator: "Generated in 2.3 seconds"

4. **Design System Compliance**: Use Tailwind CSS classes following the design system:
   - Blue color palette (`blue-600`, `blue-500`, `blue-100`)
   - Gray neutral colors (`gray-900`, `gray-700`, `gray-600`)
   - Semantic colors for performance levels (green, blue, amber, red)
   - Typography scale (`text-sm`, `text-lg`, `font-medium`, `font-semibold`)
   - Spacing patterns (`px-6 py-4`, `space-y-4`, `gap-6`)

5. **Responsive Design**: Ensure the assignment summary displays properly across breakpoints:
   - Mobile: Single column layout
   - Tablet (`sm:`): Maintain readability with adjusted spacing
   - Desktop (`lg:`): Multi-column layout for performance metrics

6. **Performance Indicators**: Include visual performance level badges using the design system:
   - "Exceeds" with green styling (`bg-green-100 text-green-800`)
   - "Meets" with blue styling (`bg-blue-100 text-blue-800`) 
   - "Approaching" with amber styling (`bg-amber-100 text-amber-800`)
   - "Below" with red styling (`bg-red-100 text-red-800`)

## Non-Goals (Out of Scope)

1. **No Dynamic Data**: This update will use only hardcoded sample data, not live database connections
2. **No Interactivity**: The assignment summary will be static display only, no clickable elements or functionality
3. **No Animation**: No complex animations or transitions beyond basic hover states
4. **No Mobile App Changes**: This update only affects the web landing page
5. **No Content Changes**: Headlines, subheadlines, and CTA text remain unchanged
6. **No Performance Optimization**: Focus is visual design only, not page load improvements
7. **No A/B Testing Setup**: Implementation only, testing setup is separate

## Design Considerations

**Reference Design**: Follow the exact layout and styling from `/ui_iterations/ui_1.html`

**Color Scheme**: 
- Primary: Blue gradient background maintained
- Performance levels: Follow semantic color system (green/blue/amber/red)
- Text: Gray scale hierarchy from design system

**Typography**: 
- Assignment title: `text-lg font-semibold text-gray-900`
- Metrics: `text-sm font-medium`
- Performance numbers: `text-2xl font-bold`
- Body text: `text-sm text-gray-600`

**Layout**: 
- Maintain existing hero grid structure
- Assignment summary takes place of current mockup
- Preserve responsive breakpoints and spacing

## Technical Considerations

**Framework**: Rails ERB template with Tailwind CSS
**File Location**: `app/views/home/index.html.erb`
**Dependencies**: No new dependencies required
**Asset Requirements**: Existing GradeBot logo asset maintained
**Browser Support**: Maintain current Tailwind CSS browser support

## Success Metrics

**Primary Metric**: Landing page conversion rate improvement
- **Target**: 5-15% increase in sign-up conversion
- **Measurement**: Google Analytics conversion tracking
- **Timeline**: Measure over 30 days post-deployment

**Secondary Metrics**:
- Time on page increase (indicates engagement with realistic demo)
- Bounce rate decrease (accurate representation reduces immediate exits)
- User feedback sentiment improvement in onboarding surveys

## Open Questions

1. **Content Updates**: Should the sample assignment subject or grade level be changed to appeal to a broader audience?
2. **Performance Data**: Are the current performance distribution percentages realistic and compelling?
3. **Deployment Timeline**: What is the target deployment date for this update?
4. **Testing Strategy**: Should this be A/B tested against the current version before full deployment?

---

**Created**: July 11, 2025  
**Priority**: High  
**Estimated Effort**: 2-4 hours (junior developer)  
**Dependencies**: Access to ui_1.html reference design