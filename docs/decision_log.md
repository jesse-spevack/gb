# Decision Log

## 2025-08-03

### Rubric Toggle Feature Temporary Disabling

- **Context:**
  - The assignment creation form included a toggle switch allowing users to choose between AI-generated rubrics and manually pasted rubrics
  - Manual rubric processing is not fully implemented and can cause confusion for initial test users
  - Need to simplify the user experience for demo purposes and early user testing

- **Decision:**
  - Temporarily disable the manual rubric paste functionality
  - Keep only AI-generated rubrics as the option
  - Preserve all underlying infrastructure for future re-enablement

- **Implementation Details:**
  - Removed Stimulus controller data attributes from the form HTML
  - Disabled the toggle switch (always in "on" state with visual indicators)
  - Hidden the textarea input while preserving the form field for backend compatibility
  - Updated UI text to clearly indicate "GradeBot will generate an AI rubric based on your assignment details"
  - Added comprehensive documentation in `docs/rubric_toggle.md` for re-enablement

- **Rationale:**
  - Eliminates user confusion during initial testing phases
  - Makes the application more demoable with a clear, single workflow
  - Reduces support burden by removing a partially-implemented feature
  - Maintains professional appearance by showing deliberate product decisions

- **Infrastructure Preserved:**
  - Database field `rubric_text` remains intact
  - Stimulus controller `rubric_toggle_controller.js` preserved with detailed re-enablement instructions
  - All CSS classes and styling remain available
  - Form submission logic continues to work correctly

- **Trade-offs Accepted:**
  - Loss of user choice in rubric input method (temporary)
  - Slightly more complex re-enablement process when feature is ready
  - Users cannot provide their existing rubrics during this phase

- **Future Re-enablement Triggers:**
  - Manual rubric processing is fully implemented and tested
  - Initial user testing phase is complete
  - Product team decides to offer both AI and manual rubric options

- **Documentation:**
  - Complete re-enablement guide available at `docs/rubric_toggle.md`
  - Includes all necessary data attributes, testing checklist, and step-by-step instructions

## 2025-06-01

### Pipeline Storage Services - Performance and Security Optimizations Deferred

- **Context:**
  - Implemented three pipeline storage services (RubricService, StudentWorkService, AssignmentSummaryService)
  - Services persist LLM-generated content to database with full transaction support
  - Code review identified performance and security optimization opportunities
  - Current constraint: Maximum 35 student assignments per teacher

- **Identified Optimization Opportunities:**
  1. **Bulk Inserts Implementation**
     - Current: Individual `create!` calls in loops (potentially 1000+ INSERTs for large assignments)
     - Proposed: Use Rails `insert_all` for bulk operations
     - Impact: Could reduce database operations by 50-100x for large assignments
     - Example: 100 students × 10 operations = 1000 INSERTs → ~20 bulk operations

  2. **Authorization Checks in Storage Layer**
     - Current: Authorization handled at controller level only
     - Proposed: Add authorization verification within storage services for defense in depth
     - Impact: Prevents unauthorized data access if services called from other contexts (jobs, APIs)
     - Implementation: Add `authorize_user!(context.user, context.assignment)` checks

- **Decision:**
  - Defer both optimizations to focus on MVP completion
  - Rationale:
    - Current 35-student limit makes performance acceptable (~350 database operations)
    - Authorization is properly handled at controller level for current use cases
    - Time better spent completing full user flow and launching MVP
    - Can revisit when scaling beyond initial user base

- **Trade-offs Accepted:**
  - Slower processing for maximum-size assignments (35 students)
  - Single layer of authorization vs defense in depth
  - Accepting technical debt for faster time to market

- **Future Triggers for Revisiting:**
  - User feedback about slow grading times
  - Need to support larger class sizes (>35 students)
  - Introduction of new entry points to storage services (APIs, webhooks)
  - Performance monitoring showing database bottlenecks

- **Monitoring Plan:**
  - Track assignment processing times in production
  - Monitor database query performance
  - Set alerts for processing timeouts
  - Collect user feedback on grading speed

## 2025-05-27

### LLM Response Parser Implementation and Duplication Analysis

- **Context:**
  - Implemented three LLM response parsers (Rubric, StudentWork, AssignmentSummary)
  - Each parser transforms JSON responses from LLM generators into structured data
  - All parsers follow the same pattern: parse JSON, validate structure, build response objects

- **Duplication Analysis Results:**
  - Found ~150-200 lines of duplicated code (26-35% of total parser code)
  - 5 completely identical methods across all parsers
  - 3 nearly identical methods with minor variations
  - Shared validation patterns, especially for feedback items

- **Refactoring Options Considered:**
  1. **Base Class Extraction** - Would eliminate most duplication
  2. **Shared Modules** - Target specific shared functionality
  3. **Hybrid Approach** - Base class + targeted modules (recommended if refactoring)

- **Decision:**
  - Keep current implementation without refactoring
  - Rationale:
    - All parsers work correctly with comprehensive test coverage
    - Code is explicit and easy to understand
    - Duplication follows consistent patterns
    - Team can easily modify individual parsers without affecting others
    - Refactoring would add abstraction without immediate benefit

- **Trade-offs Accepted:**
  - Accepting code duplication in favor of explicitness
  - Each parser is self-contained and independently testable
  - Future changes to one parser won't accidentally affect others
  - New developers can understand each parser without learning inheritance hierarchy

- **Future Considerations:**
  - Revisit if adding more parser types (current: 3)
  - Reconsider if parser logic becomes more complex
  - Monitor for bugs that need fixing in multiple places

## 2025-05-25

### Processing Pipeline Architecture Redesign

- **Identified Issues:**
  - Current `ProcessingTask` architecture lacks explicit data flow between steps
  - Error handling is complex and inconsistent across processing types
  - State management during processing is difficult to track and debug
  - Testing individual components requires extensive mocking
  - Real-time progress updates are difficult to implement consistently

- **Solution Approach:**
  - Redesign as pipeline architecture with explicit step composition
  - Use context objects to maintain state throughout processing
  - Standardize interfaces for all pipeline components
  - Create dedicated pipelines for each major processing type (Rubric, StudentWork, AssignmentSummary)
  - Implement consistent event broadcasting for real-time updates

- **Key Benefits:**
  - Clearer data flow with explicit handoffs between steps
  - Improved testability with isolated components
  - Better error handling with standardized result objects
  - More maintainable code with single-responsibility classes
  - Consistent logging and metrics collection across all pipelines

- **Implementation Plan:**
  - Create core pipeline components first (context objects, result objects)
  - Implement pipelines one at a time, starting with rubric generation
  - Update background jobs to use new architecture
  - Add comprehensive tests for all components

- **Migration Strategy:**
  - Implement new architecture alongside existing code
  - Transition one processing type at a time to minimize disruption
  - Maintain backward compatibility for in-progress assignments

## 2025-05-10

### Google Picker Authentication Recovery

- **Identified Risk:**
  - Google OAuth tokens typically expire after 1 hour
  - When tokens expire during form completion, users currently must sign out/in and lose form data
  - This could lead to poor user experience for teachers completing detailed assignment forms
  
- **Potential Solution:**
  - Implement a session refresh mechanism that would allow in-place credential renewal
  - This would prevent data loss and provide a seamless recovery experience
  - Would require both client-side UI improvements and a server-side token refresh endpoint

- **Decision:**
  - Not implementing proactive token refresh at this time
  - Will wait to observe frequency and impact in production environment
  - Prioritizing initial launch feature completeness over edge-case handling
  - Will revisit if user feedback or support requests indicate this is a significant pain point
  
- **Monitoring Plan:**
  - Track authentication errors in application logs
  - Set up monitoring for Google API-related errors 
  - Collect user feedback specific to document selection experience

## 2025-04-21

### Assignment Form UX & Architecture Decisions

- **Field Structure:**
  - Using flat attributes (title, description, subject, grade level, instructions) matching the Assignment model
  - No nested attributes or form object at this stage due to simple flow

- **Rubric Selection:**
  - Toggle switch for "Generate with AI" (default) vs. "I have a rubric"
  - Textarea appears only when manual rubric is selected
  - Placeholder text: "Paste your rubric here, don't worry about formatting"

- **Google Picker:**
  - Integrated for selecting up to 35 student documents
  - Selected document data submitted as hidden field and handled in controller
  - Dedicated section for displaying selected documents

- **Feedback Tone:**
  - Slider bar instead of dropdown for selecting among three options:
    - Encouraging
    - Objective/Neutral
    - Critical
  - More engaging and intuitive UX than dropdown

- **Icon Usage:**
  - All icons rendered as Rails partials from `/icons` directory
  - Ensures maintainability and reusability

- **Form Model Rationale:**
  - Form object not used at this stage
  - Flat model approach sufficient for current requirements
  - Can introduce form/service object if complexity increases

- **Validation:**
  - Errors displayed at top of form
  - Following Tailwind and application style conventions

- **Submission:**
  - Form submits via POST
  - Stimulus controllers used for interactive elements