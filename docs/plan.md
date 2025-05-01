#  GradeB🤖t 

## About

### Problem & Purpose

GradeBot is an AI-feedback assistant designed for educators who want to provide better feedback in less time. Grading student work is time-consuming work often done outside of regular school hours. GradeBot helps teachers focus on planning and insights and transform hours of grading into minutes of strategic review.

### Target User

The target user is a teacher who has students complete written assignments using Google Docs. This user may already use LLMs to generate assignments, rubrics, and provide feedback, but the process is time-consuming and manual.

### How It Works

1. **Assignment Creation**: Teachers create a new assignment by entering title, subject, grade level, and instructions.

2. **Rubric Generation**: Teachers can either have GradeBot generate a rubric using AI or paste an existing rubric. 

3. **Student Work Selection**: Teachers click on a Google-branded "Select student work" button that opens a Google Picker. They can select up to 35 pieces of student work.

4. **Feedback Style**: Teachers can customize grading settings by selecting a feedback tone: encouraging, neutral/objective, or critical.

5. **Automated Processing**: After submission, GradeBot:
   - Generates a structured rubric with criteria and levels
   - Processes each student work against the rubric
   - Creates detailed feedback for each student
   - Generates an assignment summary with class-wide insights

6. **Teacher Review**: Teachers can review, edit, and append any feedback to the original Google Doc.

### Subscription Model

- **Free Tier**: 1 assignment per month
- **Paid Tier**: Up to 300 assignments per month for $X.99
- Stripe integration for billing
- Redirects when limits are reached

## Engineering Specification

### Tech Stack

- Rails 8+ with Stimulus for JavaScript
- Tailwind 4+ for styling
- SQLite database
- Solid cache, queue, and cable
- Kamal deployment to Google Cloud Platform
- Kamal Secrets with 1Password adapter for secrets management
- Minitest for testing with fixtures
- Google Docs integration using `drive.file` scope

### Authentication Feature

GradeBot implements a secure, session-based authentication system using Google OAuth2.

#### Database Models

**User Model**
- Has many assignments
- Stores basic user information (name, email, Google UID)

**Session Model**
- Belongs to a user
- Stores metadata (user agent, IP address)
- Provides access to Google access token

**UserToken Model**
- Stores OAuth tokens (access token, refresh token) and expiration data
- Includes methods to check token expiration status
- Maintains token history with latest_first scope

#### Components

1. **OmniAuth Integration** (`config/initializers/omniauth.rb`):
   - Configures Google OAuth2 provider with scopes: email, profile, and drive.file
   - Sets access_type to "offline" for refresh tokens
   - Uses "consent" prompt for explicit user approval

2. **Authentication Concern** (`app/controllers/concerns/authentication.rb`):
   - Implements controller-agnostic authentication logic
   - Provides helper methods like `authenticated?`, `require_authentication`
   - Manages session lifecycle
   - Includes `allow_unauthenticated_access` class method for exceptions

3. **Sessions Controller** (`app/controllers/sessions_controller.rb`):
   - Handles OAuth callback
   - Creates/updates user records
   - Establishes user sessions
   - Manages logout

#### Authentication Flow

1. User clicks "Sign in with Google"
2. User approves permissions
3. Google redirects back with auth code
4. OmniAuth processes callback and creates auth hash
5. SessionsController creates/updates user record
6. New session is created and stored as HTTP-only, same-site cookie
7. User is redirected to application
8. Subsequent requests use session cookie for authentication

#### Security Features

- HTTP-only cookies prevent JavaScript access
- Same-site Lax cookies mitigate CSRF attacks
- IP address and user agent tracking
- Access tokens stored in database, not cookies
- Explicit OAuth consent

### Assignment Creation Feature

Allows teachers to create new assignments with student work and optionally custom rubrics.

#### Database Models

**Assignment**
- Belongs to a user
- Has one rubric
- Has many student works
- Has many document selections
- Has one assignment summary
- Raw rubric text
- Integer - total processing milliseconds

**SelectedDocument**
- Belongs to an assignment
- google_doc_id (string)
- title (string)
- url (string)

#### Components

1. **Assignment Form**
   - Form with fields for title, subject, grade level, instructions
   - Toggle for AI-generated vs custom rubric
   - Google Picker integration for student work selection
   - Feedback tone selection slider

2. **Document Selection Services**
   - DocumentSelection::BulkCreationService for creating document selections
   - Validation to ensure document length < 2000 words

3. **Assignment Initialization**
   - Assignment::InitializerService to create assignments and related records
   - Enqueues AssignmentProcessingJob for background processing

### Rubric Generation Feature

Generates structured rubrics either from scratch or based on teacher-provided guidelines.

#### Database Models

**Rubric**
- Has many criteria
- Belongs to an assignment

**Criterion**
- Has many levels
- Title
- Description
- Position

**Level**
- Title
- Description
- Position

#### Components

1. **Rubric Generation Pipeline**
   - ProcessingTask configuration for rubric generation
   - Custom prompt template for rubric creation
   - Response parser to convert LLM output to structured data
   - Rubric::CreationService for database record creation

2. **Rubric Representation**
   - Rubric#to_prompt method for inclusion in subsequent prompts
   - UI components for displaying rubric criteria and levels

### Student Feedback Feature

Analyzes student work against assignment requirements and rubric to generate detailed feedback.

#### Database Models

**Student Work**
- Belongs to an assignment
- Belongs to a selected document
- Has many student work criterion levels
- Has many feedback items
- Qualitative feedback as text
- Has many checks

**Student Work Criterion Level**
- Join between student work, criteria and level
- Has explanation as text

**Feedback Item**
- Type - strength or opportunity
- Title
- Description
- Evidence
- Belongs to Feedbackable (student work or assignment)

**Student Work Check**
- Type
- Score (0-100)
- Explanation
- Belongs to student work

#### Components

1. **Student Work Processing Pipeline**
   - Document content retrieval from Google Docs
   - Prompt construction combining student work, assignment, and rubric
   - Response parsing to extract structured feedback
   - Progress tracking and real-time UI updates

2. **Feedback Interaction**
   - UI for reviewing and editing feedback
   - Functionality to append feedback to Google Docs
   - Retry mechanism for failed processing

### Assignment Summary Feature

Aggregates insights across all student works to provide class-wide feedback.

#### Database Models

**Assignment Summary**
- Belongs to assignment
- Student work count
- Qualitative insights as text
- Has many feedback items

#### Components

1. **Summary Generation Pipeline**
   - Gathers data from all processed student works
   - Specialized prompt for class-wide insights
   - Parser for summary feedback items
   - UI components for displaying trends and recommendations

### Analytics and Gamification Feature

Tracks teacher usage and provides motivational elements.

#### Components

1. **Streak Tracking**
   - Daily activity measurement
   - Visual indicators in UI

2. **Contribution Visualization**
   - GitHub-style activity graph
   - Statistics on workload distribution

3. **Usage Limits**
   - Monthly assignment counting
   - Tier limit enforcement

### LLM Integration System

The core engine powering GradeBot's AI capabilities.

#### Database Models

**LLMRequest**
- Polymorphic association via trackable
- Stores prompt, model, request type, response
- Tracks performance metrics and costs
- Records request lifecycle status

**ProcessingMetric**
- Records detailed metrics for each processing task
- Enables cost tracking and performance analysis

#### Components

1. **Client Architecture**
   - `LLM::Client`: Entry point that validates inputs and delegates to implementations
   - Provider-specific clients (Anthropic, Google)
   - `LLM::ClientFactory`: Creates appropriate client instances

2. **Resilience Mechanisms**
   - `LLM::RetryHandler`: Manages retry strategies with exponential backoff
   - `LLM::CircuitBreaker`: Prevents cascading failures

3. **Cost Management**
   - `LLM::CostCalculator`: Calculates costs based on token usage
   - `LLM::CostTracker`: Records cost data to database

### Processing Abstraction System

Standardizes the workflow of collecting data, sending prompts, and processing responses.

#### Components

1. **ProcessingTask**
   - Encapsulates configuration for specific LLM task
   - Defines components for each processing step
   - Tracks metrics and processing time

```ruby
# app/services/processing_task.rb
class ProcessingTask
  attr_reader :processable, :process_type, :user, :configuration, :context
  attr_accessor :started_at, :completed_at, :error_message, :metrics

  VALID_PROCESS_TYPES = [
    "generate_rubric",
    "grade_student_work",
    "generate_summary_feedback"
  ].freeze
  
  def initialize(processable:, process_type:, user: nil, configuration:, context: {})
    @processable = processable
    @process_type = process_type
    @user = user
    @configuration = configuration.with_indifferent_access
    @context = context.with_indifferent_access
    @metrics = {}.with_indifferent_access
    validate!
  end
  
  # Configuration accessors
  def prompt_template
    configuration.prompt_template
  end
  
  def response_parser
    configuration.response_parser
  end
  
  def storage_service
    configuration.storage_service
  end
  
  def broadcaster
    configuration.broadcaster
  end
  
  def status_manager
    configuration.status_manager
  end
  
  # Timing methods
  def mark_started
    @started_at = Time.current
  end
  
  def mark_completed
    @completed_at = Time.current
  end
  
  def processing_time_ms
    return 0 unless started_at && completed_at
    ((completed_at - started_at) * 1000).to_i
  end
  
  def record_metric(key, value)
    @metrics[key] = value
  end

  private
  
  def validate!
    raise ArgumentError, "Processable is required" unless processable
    raise ArgumentError, "Process type is required" unless process_type
  end
end
```

2. **ProcessingPipeline**
   - Orchestrates entire processing workflow
   - Implements the 5-step pattern (collect, build, send, parse, store)
   - Handles errors and metrics collection

```ruby
# app/services/processing_pipeline.rb
class ProcessingPipeline
  def initialize(task)
    @task = task
    @logger = Rails.logger
  end
  
  def execute
    @logger.info("Starting processing pipeline for #{@task.process_type} on #{@task.processable.class.name}")
    
    @task.mark_started
    update_status(:processing)
    
    begin
      # Step 1: Collect data
      data = collect_data
      
      # Step 2: Build prompt
      prompt = build_prompt(data)
      
      # Step 3: Send to LLM
      response = send_to_llm(prompt)
      
      # Step 4: Parse response
      parsed_result = parse_response(response)
      
      # Step 5: Store result
      store_result(parsed_result)
      
      # Finalize
      @task.mark_completed
      @task.record_metric(:status, 'completed')
      @task.record_metric(:processing_time_ms, @task.processing_time_ms)
      
      # Record metrics to database
      save_processing_metrics(parsed_result)
      
      update_status(:completed)
      broadcast_update(:completed, parsed_result)
      
      ProcessingResult.new(success: true, data: parsed_result)
    rescue => e
      handle_error(e)
    end
  end
  
  private
  
  # Implementation of each processing step...
  # (methods omitted for brevity)
end
```

3. **Factory Services**
   - `ResponseParserFactory`: Creates appropriate parser instances
   - `StorageServiceFactory`: Creates storage service instances
   - `BroadcasterFactory`: Creates broadcaster instances
   - `StatusManagerFactory`: Creates status manager instances

4. **Support Services**
   - `DataCollectionService`: Gathers data for processing
   - `PromptBuilder`: Constructs prompts from templates
   - `PromptTemplate`: Renders templates with variables

### Prompt Management System

Manages templates and construction of prompts for different LLM tasks.

#### Components

1. **PromptTemplate**
   - Core class handling template loading and rendering
   - Uses ERB templating for variable interpolation
   - Looks for templates in `app/views/prompts/` directory

2. **PromptBuilder**
   - Provides simple interface for building prompts
   - Takes a template type and parameters, then delegates to PromptTemplate
   - Handles errors and logs issues during prompt generation

3. **Template Organization**
   - Templates stored in `app/views/prompts/` with naming conventions:
     - `rubric_generation.txt.erb`: For generating structured rubrics
     - `student_feedback.txt.erb`: For analyzing student work
     - `assignment_summary.txt.erb`: For generating assignment-level insights

### Processing Time Estimation System

Provides teachers with realistic completion time expectations.

#### Components

1. **Base Time Calculation**
   - Rubric Generation: 30 seconds
   - Student Work Feedback: 60 seconds per work
   - Assignment Summary: 45 seconds

2. **Dynamic Adjustment**
   - Progress tracking and completion updates
   - Real-time estimate revisions
   - Error handling and retry scenarios

3. **User Interface Elements**
   - Progress indicators
   - Time remaining displays
   - Completion notifications

### Cost Tracking System

Monitors and records the cost of each LLM request.

#### Components

1. **Event-Based Architecture**
   - Captures metrics for every LLM request
   - Calculates costs based on token usage
   - Persists data for reporting

2. **Cost Tracking Flow**
   - Event publishing upon request completion
   - Cost calculation based on token counts
   - Database recording of cost metrics
   - Fallback mechanisms for event failure

### Metrics and Business Goals

#### Business Metrics
- **User Acquisition**: 100 paying customers by end of 2026 school year
- **Retention**: 80% monthly retention rate for paying users
- **Engagement**: 1+ assignment created daily by October 2025
- **Conversion**: 10% conversion rate from free tier to paid subscription

#### Product Usage Metrics
- **Assignment Volume**: Track total assignments processed weekly/monthly
- **Student Work Volume**: Average number of student works per assignment
- **Feature Adoption**: Percentage using each feature (AI rubrics, feedback customization, etc.)

#### Performance Metrics
- **Processing Time**: Average time to complete each stage
- **Error Rates**: Percentage of failed LLM requests requiring retry
- **System Uptime**: Maintain 99.9% availability during school hours

#### Quality Metrics
- **Feedback Quality**: Measured via teacher edit frequency, satisfaction surveys
- **Cost Efficiency**: Token usage and cost trends

#### Financial Metrics
- **ARPU**: Monthly tracked against subscription price
- **CAC**: Marketing spend per converted paying user
- **LLM Cost Ratio**: LLM costs as percentage of revenue (target: <30%)
- **Contribution Margin**: Net revenue after direct costs
- **Lifetime Value**: Projected based on retention and usage

## Implementation Milestones

1. **Authentication & Assignments Index**
   - Google OAuth integration
   - Basic assignments index page

2. **Assignment Creation Form**
   - Form with title, subject, grade level, instructions
   - AI rubric generation toggle
   - Google Picker integration for student work
   - Feedback tone selection

3. **Assignment Processing Initialization**
   - Creation of Assignment record with related models
   - Background job initialization
   - Redirect to assignment show page with status indicators

4. **Processing Pipeline Execution**
   - Rubric Generation Pipeline
     - Prompt building and LLM request
     - Parsing response into rubric structure
     - Real-time UI updates via Broadcast Service
   - Student Work Feedback Pipelines
     - Google Docs content retrieval
     - Feedback generation, parsing, and storage
     - Progress tracking and estimation updates
   - Assignment Summary Pipeline
     - Class-wide insights generation
     - Completion status updates

5. **Teacher Interaction with Results**
   - Student work feedback review and editing
   - Google Docs feedback integration
   - Assignment insights dashboard

6. **Analytics & Gamification**
   - Streak counting and usage statistics
   - Contribution visualization
   - Monthly limit tracking

7. **Subscription & Billing**
   - Stripe integration
   - Tier enforcement and upgrade flows

## Decision Log

### Assignment Form UX & Architecture Decisions (2025-04-21)

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