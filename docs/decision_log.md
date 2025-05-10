# Decision Log

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