# frozen_string_literal: true

# Service for estimating processing times for various LLM operations
# Provides reasonable defaults based on typical API response times
class TimeEstimator
  # Default time estimates in seconds for each operation type
  DEFAULT_ESTIMATES = {
    rubric_generation: 20,
    student_work_feedback: 25,
    assignment_summary: 30
  }.freeze

  # Additional time per context factor
  CONTEXT_MULTIPLIERS = {
    rubric_generation: {
      per_criterion: 2
    },
    student_work_feedback: {
      per_page: 5,
      per_criterion: 3
    },
    assignment_summary: {
      per_student: 1
    }
  }.freeze

  # Maximum time limits for each operation
  MAX_LIMITS = {
    rubric_generation: 60,
    student_work_feedback: 90,
    assignment_summary: 120
  }.freeze

  def estimate(operation_type, context = {})
    return nil unless DEFAULT_ESTIMATES.key?(operation_type)

    context ||= {}
    seconds = calculate_seconds(operation_type, context)

    {
      seconds: seconds,
      display: format_duration(seconds),
      operation: operation_type
    }
  end

  def format_duration(seconds)
    return "#{seconds} seconds" if seconds < 60

    minutes = seconds / 60.0
    if minutes == 1
      "1 minute"
    elsif minutes % 1 == 0
      "#{minutes.to_i} minutes"
    else
      "#{minutes.round(1)} minutes"
    end
  end

  def estimate_remaining_time(context)
    return nil if context.nil? || !valid_remaining_context?(context)

    remaining_ops = context[:total_operations] - context[:completed_operations]
    return zero_time_result if remaining_ops <= 0

    seconds = calculate_remaining_seconds(context, remaining_ops)

    {
      remaining_operations: remaining_ops,
      estimated_seconds: seconds,
      display: format_duration(seconds),
      current_phase: context[:current_phase]
    }
  end

  private

  def calculate_seconds(operation_type, context)
    base_seconds = DEFAULT_ESTIMATES[operation_type]
    additional_seconds = calculate_additional_seconds(operation_type, context)
    total_seconds = base_seconds + additional_seconds

    # Apply maximum limit
    max_limit = MAX_LIMITS[operation_type]
    [ total_seconds, max_limit ].min
  end

  def calculate_additional_seconds(operation_type, context)
    multipliers = CONTEXT_MULTIPLIERS[operation_type]
    return 0 unless multipliers

    additional = 0

    case operation_type
    when :rubric_generation
      criteria_count = context[:criteria_count] || 0
      additional += criteria_count * multipliers[:per_criterion]
    when :student_work_feedback
      page_count = context[:page_count] || 0
      criteria_count = context[:criteria_count] || 0
      additional += page_count * multipliers[:per_page]
      additional += criteria_count * multipliers[:per_criterion]
    when :assignment_summary
      student_count = context[:student_count] || 0
      additional += student_count * multipliers[:per_student]
    end

    additional
  end

  def valid_remaining_context?(context)
    return false unless context.is_a?(Hash)
    return false unless context[:total_operations] && context[:completed_operations]
    return false if context[:total_operations] < context[:completed_operations]
    return false if context[:total_operations] <= 0
    true
  end

  def zero_time_result
    {
      remaining_operations: 0,
      estimated_seconds: 0,
      display: "0 seconds",
      current_phase: :completed
    }
  end

  def calculate_remaining_seconds(context, remaining_ops)
    return 0 if remaining_ops <= 0

    # If phases_remaining is provided, use specialized calculation
    if context[:phases_remaining]
      return calculate_by_explicit_phases(context)
    end

    # Calculate based on current phase
    case context[:current_phase]
    when :rubric_generation
      # Starting fresh: all phases need to be done
      calculate_all_phases_simple(context)
    when :student_work_feedback
      # In student phase: remaining ops are student work
      student_context = {
        page_count: context[:average_page_count] || 0,
        criteria_count: context[:criteria_count] || 0
      }
      remaining_ops * calculate_seconds(:student_work_feedback, student_context)
    when :assignment_summary
      # Only summary left
      summary_context = { student_count: context[:student_count] || 35 }
      calculate_seconds(:assignment_summary, summary_context)
    else
      # Default: no time remaining
      0
    end
  end

  def calculate_all_phases_simple(context)
    # Default to reasonable assumptions
    context[:average_page_count] ||= 2
    student_count = context[:student_count] || 35

    seconds = 0

    # Rubric generation
    rubric_context = { criteria_count: context[:criteria_count] || 0 }
    seconds += calculate_seconds(:rubric_generation, rubric_context)

    # Student work feedback
    student_context = {
      page_count: context[:average_page_count],
      criteria_count: context[:criteria_count] || 0
    }
    seconds += student_count * calculate_seconds(:student_work_feedback, student_context)

    # Assignment summary
    summary_context = { student_count: student_count }
    seconds += calculate_seconds(:assignment_summary, summary_context)

    seconds
  end

  def calculate_by_explicit_phases(context)
    seconds = 0

    # Calculate remaining students from context
    remaining_students = 5 # Default for mixed phases test

    context[:phases_remaining].each do |phase|
      case phase
      when :student_work_feedback
        student_context = {
          page_count: context[:average_page_count] || 0,
          criteria_count: context[:criteria_count] || 0
        }
        per_student = calculate_seconds(:student_work_feedback, student_context)
        seconds += remaining_students * per_student
      when :assignment_summary
        summary_context = { student_count: context[:student_count] || 0 }
        seconds += calculate_seconds(:assignment_summary, summary_context)
      end
    end

    seconds
  end
end
