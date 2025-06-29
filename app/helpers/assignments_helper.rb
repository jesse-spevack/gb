# frozen_string_literal: true

module AssignmentsHelper
  def options_for_grade_level_select
    Assignment::GRADE_LEVELS.map { |level| [ display_grade(level), level ] }.freeze
  end

  # Returns a displayable grade level
  def display_grade(level)
    if level == "university"
      "University"
    else
      "#{level}th grade"
    end
  end

  # Renders a status badge for processing states
  # @param status [Symbol, String] The status value (:completed, :processing, :pending)
  # @param custom_text [String] Optional custom text to display inside the badge
  # @param custom_class [String] Optional additional CSS classes
  # @return [String] HTML for the status badge
  def status_badge(status, custom_text: nil, custom_class: nil)
    status = status.to_sym if status.is_a?(String)

    badge_configs = {
      completed: {
        bg_class: "bg-green-100",
        text_class: "text-green-800",
        label: "Complete"
      },
      in_progress: {
        bg_class: "bg-blue-100",
        text_class: "text-blue-800",
        label: "Processing"
      },
      pending: {
        bg_class: "bg-gray-100",
        text_class: "text-gray-800",
        label: "Pending"
      },
      processing: {
        bg_class: "bg-blue-100",
        text_class: "text-blue-800",
        label: "Processing"
      },
      failed: {
        bg_class: "bg-red-100",
        text_class: "text-red-800",
        label: "Failed"
      }
    }

    config = badge_configs[status] || badge_configs[:pending]
    text = custom_text || config[:label]

    content_tag :span, text, class: "status-badge #{status} inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{config[:bg_class]} #{config[:text_class]} #{custom_class}"
  end

  # Renders a processing status badge based on student work completion
  # @param work [StudentWork] The student work object
  # @return [String] HTML for the status badge
  def student_work_status_badge(work)
    if work.processing_metric&.failed?
      status_badge(:failed)
    elsif work.qualitative_feedback.present?
      status_badge(:completed)
    else
      status_badge(:pending)
    end
  end
end
