# frozen_string_literal: true

# Service responsible for broadcasting pipeline updates via Turbo Streams
# Provides real-time updates to the UI based on pipeline context
class BroadcastService
  def self.call(context:)
    new(context).call
  end

  def self.with(event:)
    ConfiguredBroadcastService.new(event: event)
  end

  def initialize(context)
    @context = context
  end

  def call
    broadcast_updates
    @context
  end

  private

  def broadcast_updates
    case processable
    when Assignment
      broadcast_assignment_progress
    when Rubric
      broadcast_rubric_updates
    when StudentWork
      broadcast_student_work_updates
    when AssignmentSummary
      broadcast_summary_update
    end
  end

  def broadcast_assignment_progress
    progress_metrics = Assignments::ProgressCalculator.new(processable).calculate

    Turbo::StreamsChannel.broadcast_update_to(
      processable,
      target: "assignment_#{processable.id}_progress",
      partial: "assignments/progress_card",
      locals: {
        assignment: processable,
        progress_metrics: progress_metrics
      }
    )
  end

  def broadcast_rubric_updates
    assignment = processable.assignment

    # Update rubric content
    Turbo::StreamsChannel.broadcast_update_to(
      assignment,
      target: "rubric_content",
      partial: "assignments/rubric_section",
      locals: {
        rubric: processable,
        assignment: assignment
      }
    )

    # Update tab indicator if completed
    if status == :completed
      Turbo::StreamsChannel.broadcast_update_to(
        assignment,
        target: "rubric_tab_indicator",
        html: '<span class="inline-block w-2 h-2 bg-green-500 rounded-full"></span>'
      )
    end

    # Also update overall progress
    broadcast_assignment_progress_for(assignment)
  end

  def broadcast_student_work_updates
    assignment = processable.assignment
    work_index = assignment.student_works.order(:id).pluck(:id).index(processable.id)

    # Update individual work row
    Turbo::StreamsChannel.broadcast_update_to(
      assignment,
      target: "student_work_#{processable.id}",
      partial: "assignments/student_work_row",
      locals: {
        work: processable,
        index: work_index || 0
      }
    )

    # Update overall progress
    broadcast_assignment_progress_for(assignment)
  end

  def broadcast_summary_update
    assignment = processable.assignment

    # Update summary tab indicator
    if status == :completed
      Turbo::StreamsChannel.broadcast_update_to(
        assignment,
        target: "summary_tab_indicator",
        html: '<span class="inline-block w-2 h-2 bg-green-500 rounded-full"></span>'
      )
    end

    # Update progress
    broadcast_assignment_progress_for(assignment)
  end

  def broadcast_assignment_progress_for(assignment)
    progress_metrics = Assignments::ProgressCalculator.new(assignment).calculate

    Turbo::StreamsChannel.broadcast_update_to(
      assignment,
      target: "assignment_#{assignment.id}_progress",
      partial: "assignments/progress_card",
      locals: {
        assignment: assignment,
        progress_metrics: progress_metrics
      }
    )
  end

  def processable
    if @context.respond_to?(:assignment) && @context.assignment
      @context.assignment
    elsif @context.respond_to?(:rubric) && @context.rubric
      @context.rubric
    elsif @context.respond_to?(:student_work) && @context.student_work
      @context.student_work
    elsif @context.respond_to?(:assignment_summary) && @context.assignment_summary
      @context.assignment_summary
    end
  end

  def status
    @context.status || infer_status
  end

  def infer_status
    if @context.errors.present?
      :failed
    elsif @context.parsed_response.present?
      :completed
    else
      :in_progress
    end
  end
end
