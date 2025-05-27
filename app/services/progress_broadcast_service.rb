# frozen_string_literal: true

# Service responsible for broadcasting progress updates for assignments
# Uses Turbo Streams to provide real-time UI updates without page reloads
class ProgressBroadcastService
  attr_reader :assignment

  # Initialize with an assignment
  # @param assignment [Assignment] The assignment to broadcast progress for
  def initialize(assignment)
    @assignment = assignment
  end

  # Broadcast the current progress of an assignment
  # @param target [Symbol, String] Optional specific target to update (e.g., :rubric, :student_work)
  # @return [Boolean] Whether the broadcast was successful
  def broadcast_progress(target: nil)
    calculator = Assignments::ProgressCalculator.new(assignment)
    progress_metrics = calculator.calculate

    # Broadcast the progress card update
    broadcast_to_progress_card(progress_metrics)

    # Broadcast specific targets if requested
    case target
    when :rubric
      broadcast_to_rubric_section(progress_metrics)
    when :student_work
      broadcast_to_student_works(progress_metrics)
    when :summary
      broadcast_to_summary_section(progress_metrics)
    else
      # Broadcast all sections if no specific target
      broadcast_to_rubric_section(progress_metrics)
      broadcast_to_student_works(progress_metrics)
      broadcast_to_summary_section(progress_metrics)
    end

    true
  rescue => e
    Rails.logger.error("Error broadcasting progress: #{e.message}")
    false
  end

  private

  # Broadcast updates to the progress card
  # @param progress_metrics [Hash] The progress metrics from the calculator
  def broadcast_to_progress_card(progress_metrics)
    Turbo::StreamsChannel.broadcast_replace_to(
      "assignment_#{assignment.id}",
      target: "assignment_#{assignment.id}_progress",
      partial: "assignments/progress_card",
      locals: { assignment: assignment, progress_metrics: progress_metrics }
    )
  end

  # Broadcast updates to the rubric section
  # @param progress_metrics [Hash] The progress metrics from the calculator
  def broadcast_to_rubric_section(progress_metrics)
    # Only broadcast rubric updates if the rubric exists or is in progress
    if assignment.rubric.present? || progress_metrics[:phases][:rubric][:status] == :in_progress
      Turbo::StreamsChannel.broadcast_replace_to(
        "assignment_#{assignment.id}",
        target: "rubric_content",
        partial: "assignments/rubric_section",
        locals: { rubric: assignment.rubric, assignment: assignment }
      )

      # Update the tab indicator
      if assignment.rubric&.persisted?
        Turbo::StreamsChannel.broadcast_replace_to(
          "assignment_#{assignment.id}",
          target: "rubric_tab_indicator",
          partial: "assignments/tab_indicator",
          locals: { completed: true }
        )
      end
    end
  end

  # Broadcast updates to all student works
  # @param progress_metrics [Hash] The progress metrics from the calculator
  def broadcast_to_student_works(progress_metrics)
    assignment.student_works.each_with_index do |work, index|
      Turbo::StreamsChannel.broadcast_replace_to(
        "assignment_#{assignment.id}",
        target: "student_work_#{work.id}",
        partial: "assignments/student_work_row",
        locals: { work: work, index: index }
      )
    end
  end

  # Broadcast updates to the summary section
  # @param progress_metrics [Hash] The progress metrics from the calculator
  def broadcast_to_summary_section(progress_metrics)
    if assignment.assignment_summary.present? || progress_metrics[:phases][:summary][:status] == :in_progress
      Turbo::StreamsChannel.broadcast_replace_to(
        "assignment_#{assignment.id}",
        target: "assignment_summary_content",
        partial: "assignments/assignment_summary",
        locals: { assignment: assignment, summary: assignment.assignment_summary }
      )
    end
  end
end
