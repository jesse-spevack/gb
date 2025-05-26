```ruby
# From AssignmentJob
class AssignmentJob < ApplicationJob
  def perform(assignment_id)
    assignment = Assignment.find(assignment_id)
    
    # Single entry point, clean API
    results = AssignmentProcessor.new(assignment).process
    
    # Results structure:
    # {
    #   rubric: <Rubric>,
    #   student_feedbacks: [<StudentWork>, ...],
    #   summary: <AssignmentSummary>,
    #   metrics: { total_time_ms: 45000, ... }
    # }
  end
end

# Main processor with clean, readable flow
class AssignmentProcessor
  def initialize(assignment)
    @assignment = assignment
  end
  
  def process
    # Each pipeline returns a Result object
    rubric_result = RubricPipeline.call(
      assignment: @assignment,
      user: @assignment.user
    )
    
    # Batch processing with clean iteration
    feedback_results = @assignment.student_works.map do |student_work|
      StudentWorkFeedbackPipeline.call(
        student_work: student_work,
        rubric: rubric_result.data,
        user: @assignment.user
      )
    end
    
    summary_result = AssignmentSummaryPipeline.call(
      assignment: @assignment,
      student_feedbacks: feedback_results.map(&:data),
      user: @assignment.user
    )
    
    # Clean result aggregation
    ProcessingResults.new(
      rubric: rubric_result.data,
      student_feedbacks: feedback_results.map(&:data),
      summary: summary_result.data,
      metrics: aggregate_metrics(rubric_result, feedback_results, summary_result)
    )
  end
end

# Pipeline implementations - explicit step composition
class RubricPipeline
  def self.call(assignment:, user:)
    # Initialize context object
    context = Pipeline::Context::Rubric.new(
      assignment: assignment,
      user: user
    )
    
    # Execute steps in sequence
    context = PromptInput::Rubric.from(context: context)
    context = Broadcast.call(context: context, event: :rubric_started)
    context = LLM::Rubric::Generator.call(context: context)
    context = LLM::Rubric::ResponseParser.call(context: context)
    context = Pipeline::Storage::RubricService.call(context: context)
    context = Broadcast.call(context: context, event: :rubric_completed)
    context = RecordMetrics.call(context: context)
    
    # Return result
    ProcessingResult.new(
      success: true,
      data: context.saved_rubric,
      errors: [],
      metrics: context.metrics
    )
  rescue => e
    ProcessingResult.new(
      success: false,
      data: nil,
      errors: [e.message],
      metrics: context&.metrics || {}
    )
  end
end

class StudentWorkFeedbackPipeline
  def self.call(student_work:, rubric:, user:)
    context = Pipeline::Context::StudentWork.new(
      student_work: student_work,
      rubric: rubric,
      user: user
    )
    
    context = PromptInput::StudentWorkFeedback.from(context: context)
    context = Broadcast.call(context: context, event: :feedback_started)
    context = LLM::StudentWorkFeedback::Generator.call(context: context)
    context = LLM::StudentWorkFeedback::ResponseParser.call(context: context)
    context = Pipeline::Storage::StudentFeedbackService.call(context: context)
    context = Broadcast.call(context: context, event: :feedback_completed)
    context = RecordMetrics.call(context: context)
    
    ProcessingResult.new(
      success: true,
      data: context.saved_feedback,
      errors: [],
      metrics: context.metrics
    )
  end
end

class AssignmentSummaryPipeline
  def self.call(assignment:, student_feedbacks:, user:)
    context = Pipeline::Context::AssignmentSummary.new(
      assignment: assignment,
      student_feedbacks: student_feedbacks,
      user: user
    )
    
    context = PromptInput::AssignmentSummary.from(context: context)
    context = Broadcast.call(context: context, event: :summary_started)
    context = LLM::AssignmentFeedback::Generator.call(context: context)
    context = LLM::AssignmentFeedback::ResponseParser.call(context: context)
    context = Pipeline::Storage::AssignmentSummaryService.call(context: context)
    context = Broadcast.call(context: context, event: :summary_completed)
    context = RecordMetrics.call(context: context)
    
    ProcessingResult.new(
      success: true,
      data: context.saved_summary,
      errors: [],
      metrics: context.metrics
    )
  end
end

# Context objects under models/pipeline/context/
module Pipeline
  module Context
    class Rubric
      attr_accessor :assignment, :user, :prompt_input, :prompt,
                    :llm_response, :parsed_response, :saved_rubric, :metrics
      
      def initialize(assignment:, user:)
        @assignment = assignment
        @user = user
        @metrics = {}
      end
    end
    
    class StudentWork
      attr_accessor :student_work, :rubric, :user, :prompt_input, :prompt,
                    :llm_response, :parsed_response, :saved_feedback, :metrics
      
      def initialize(student_work:, rubric:, user:)
        @student_work = student_work
        @rubric = rubric
        @user = user
        @metrics = {}
      end
    end
    
    class AssignmentSummary
      attr_accessor :assignment, :student_feedbacks, :user, :prompt_input, :prompt,
                    :llm_response, :parsed_response, :saved_summary, :metrics
      
      def initialize(assignment:, student_feedbacks:, user:)
        @assignment = assignment
        @student_feedbacks = student_feedbacks
        @user = user
        @metrics = {}
      end
    end
  end
end

# PromptInput services
module PromptInput
  class Rubric
    def self.from(context:)
      # Collect data and build prompt
      prompt_input = new(
        assignment: context.assignment,
        user: context.user
      )
      
      context.prompt_input = prompt_input
      context.prompt = prompt_input.to_prompt
      context
    end
    
    def to_prompt
      # Render prompt template with collected data
      PromptTemplate.render(
        template: "rubric_generation",
        data: {
          title: @assignment.title,
          instructions: @assignment.instructions,
          grade_level: @assignment.grade_level,
          rubric_text: @assignment.rubric_text
        }
      )
    end
  end
  
  class StudentWorkFeedback
    def self.from(context:)
      prompt_input = new(
        student_work: context.student_work,
        rubric: context.rubric,
        user: context.user
      )
      
      context.prompt_input = prompt_input
      context.prompt = prompt_input.to_prompt
      context
    end
    
    def to_prompt
      # Fetch document content and build prompt
      document_content = Google::DriveService.call(
        user: @user,
        doc_id: @student_work.selected_document.google_doc_id
      )
      
      PromptTemplate.render(
        template: "student_feedback",
        data: {
          student_work: @student_work,
          rubric: @rubric,
          document_content: document_content
        }
      )
    end
  end
  
  class AssignmentSummary
    def self.from(context:)
      prompt_input = new(
        assignment: context.assignment,
        student_feedbacks: context.student_feedbacks,
        user: context.user
      )
      
      context.prompt_input = prompt_input
      context.prompt = prompt_input.to_prompt
      context
    end
    
    def to_prompt
      PromptTemplate.render(
        template: "assignment_summary",
        data: {
          assignment: @assignment,
          student_feedbacks: @student_feedbacks
        }
      )
    end
  end
end

# LLM Generator services (handle API calls and cost tracking)
module LLM
  module Rubric
    class Generator
      def self.call(context:)
        client = LLM::ClientFactory.for_rubric_generation
        
        start_time = Time.current
        response = client.generate(prompt: context.prompt)
        
        # Track cost
        LLMUsageRecord.create!(
          trackable: context.assignment,
          user: context.user,
          llm_provider: :anthropic,
          llm_model: response.model,
          request_type: :generate_rubric,
          token_count: response.total_tokens,
          micro_usd: calculate_cost(response)
        )
        
        # Update context
        context.llm_response = response
        context.metrics[:llm_time_ms] = ((Time.current - start_time) * 1000).to_i
        context.metrics[:tokens_used] = response.total_tokens
        
        context
      end
    end
  end
  
  module StudentWorkFeedback
    class Generator
      def self.call(context:)
        client = LLM::ClientFactory.for_student_work_feedback
        
        start_time = Time.current
        response = client.generate(prompt: context.prompt)
        
        # Track cost
        LLMUsageRecord.create!(
          trackable: context.student_work,
          user: context.user,
          llm_provider: :anthropic,
          llm_model: response.model,
          request_type: :grade_student_work,
          token_count: response.total_tokens,
          micro_usd: calculate_cost(response)
        )
        
        context.llm_response = response
        context.metrics[:llm_time_ms] = ((Time.current - start_time) * 1000).to_i
        context.metrics[:tokens_used] = response.total_tokens
        
        context
      end
    end
  end
  
  module AssignmentFeedback
    class Generator
      def self.call(context:)
        client = LLM::ClientFactory.for_assignment_summary_feedback
        
        start_time = Time.current
        response = client.generate(prompt: context.prompt)
        
        # Track cost
        LLMUsageRecord.create!(
          trackable: context.assignment,
          user: context.user,
          llm_provider: :anthropic,
          llm_model: response.model,
          request_type: :generate_summary_feedback,
          token_count: response.total_tokens,
          micro_usd: calculate_cost(response)
        )
        
        context.llm_response = response
        context.metrics[:llm_time_ms] = ((Time.current - start_time) * 1000).to_i
        context.metrics[:tokens_used] = response.total_tokens
        
        context
      end
    end
  end
end

# Response Parser services
module LLM
  module Rubric
    class ResponseParser
      def self.call(context:)
        parser = new
        context.parsed_response = parser.parse(
          response: context.llm_response.text
        )
        context
      end
      
      def parse(response:)
        # Returns structured data like:
        # ParsedRubric.new(
        #   criteria: [
        #     ParsedCriterion.new(
        #       title: "...",
        #       description: "...",
        #       levels: [...]
        #     )
        #   ]
        # )
      end
    end
  end
  
  module StudentWorkFeedback
    class ResponseParser
      def self.call(context:)
        parser = new
        context.parsed_response = parser.parse(
          response: context.llm_response.text
        )
        context
      end
      
      def parse(response:)
        # Returns structured feedback data
      end
    end
  end
  
  module AssignmentFeedback
    class ResponseParser
      def self.call(context:)
        parser = new
        context.parsed_response = parser.parse(
          response: context.llm_response.text
        )
        context
      end
      
      def parse(response:)
        # Returns structured summary data
      end
    end
  end
end

# Storage services
module Pipeline
  module Storage
    class RubricService
      def self.call(context:)
        ActiveRecord::Base.transaction do
          rubric = Rubric.create!(
            assignment: context.assignment
          )
          
          context.parsed_response.criteria.each_with_index do |criterion_data, index|
            criterion = rubric.criteria.create!(
              title: criterion_data.title,
              description: criterion_data.description,
              position: index + 1
            )
            
            criterion_data.levels.each_with_index do |level_data, level_index|
              criterion.levels.create!(
                title: level_data.title,
                description: level_data.description,
                position: level_index + 1
              )
            end
          end
          
          context.saved_rubric = rubric
        end
        
        context
      end
    end
    
    class StudentFeedbackService
      def self.call(context:)
        ActiveRecord::Base.transaction do
          # Update student work with feedback
          context.student_work.update!(
            qualitative_feedback: context.parsed_response.qualitative_feedback
          )
          
          # Create feedback items
          context.parsed_response.feedback_items.each do |item|
            context.student_work.feedback_items.create!(
              item_type: item.type,
              title: item.title,
              description: item.description,
              evidence: item.evidence
            )
          end
          
          # Create criterion levels
          context.parsed_response.criterion_scores.each do |score|
            context.student_work.student_criterion_levels.create!(
              criterion: score.criterion,
              level: score.level,
              explanation: score.explanation
            )
          end
          
          context.saved_feedback = context.student_work
        end
        
        context
      end
    end
    
    class AssignmentSummaryService
      def self.call(context:)
        ActiveRecord::Base.transaction do
          summary = AssignmentSummary.create!(
            assignment: context.assignment,
            student_work_count: context.student_feedbacks.count,
            qualitative_insights: context.parsed_response.insights
          )
          
          context.parsed_response.summary_items.each do |item|
            summary.feedback_items.create!(
              item_type: item.type,
              title: item.title,
              description: item.description,
              evidence: item.evidence
            )
          end
          
          context.saved_summary = summary
        end
        
        context
      end
    end
  end
end

# Shared services remain the same
class Broadcast
  def self.call(context:, event:)
    channel = determine_channel(context)
    data = build_broadcast_data(context, event)
    
    ActionCable.server.broadcast(channel, data)
    
    context
  end
  
  def self.determine_channel(context)
    case context
    when Pipeline::Context::Rubric
      "assignment_#{context.assignment.id}"
    when Pipeline::Context::StudentWork
      "assignment_#{context.student_work.assignment_id}"
    when Pipeline::Context::AssignmentSummary
      "assignment_#{context.assignment.id}"
    end
  end
  
  def self.build_broadcast_data(context, event)
    {
      event: event,
      timestamp: Time.current,
      data: extract_relevant_data(context, event)
    }
  end
end

class RecordMetrics
  def self.call(context:)
    ProcessingMetric.create!(
      processable: determine_processable(context),
      duration_ms: context.metrics[:llm_time_ms],
      status: :completed
    )
    
    context
  end
  
  def self.determine_processable(context)
    case context
    when Pipeline::Context::Rubric
      context.assignment
    when Pipeline::Context::StudentWork
      context.student_work
    when Pipeline::Context::AssignmentSummary
      context.assignment
    end
  end
end

# Clean result objects
class ProcessingResult
  attr_reader :success, :data, :errors, :metrics
  
  def initialize(success:, data:, errors:, metrics:)
    @success = success
    @data = data
    @errors = errors
    @metrics = metrics
  end
  
  def success?
    success
  end
  
  def failure?
    !success
  end
end
