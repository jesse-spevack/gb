# frozen_string_literal: true

module AssignmentSummariesHelper
  def performance_level_color(level)
    case level
    when "exceeds"
      "text-green-600"
    when "meets"
      "text-blue-600"
    when "approaching"
      "text-amber-600"
    when "below"
      "text-red-600"
    else
      "text-gray-600"
    end
  end

  def performance_bar_color(level)
    case level
    when "exceeds"
      "bg-green-500"
    when "meets"
      "bg-blue-500"
    when "approaching"
      "bg-amber-500"
    when "below"
      "bg-red-500"
    else
      "bg-gray-500"
    end
  end

  def safe_percentage(value)
    return 0 if value.nil? || value.nan? || value.infinite?
    [ value, 0 ].max
  end

  def format_average_score(score)
    return "0" if score.nil? || score.zero?
    score.to_s
  end
end
