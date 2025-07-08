# frozen_string_literal: true

module RubricHelper
  # Returns the appropriate CSS classes for a performance level
  def performance_level_classes(performance_level, context = :badge)
    level = normalize_performance_level(performance_level)

    case context
    when :badge
      base_classes = "inline-flex items-center rounded-full font-semibold"
      color_classes = performance_level_color_classes(level)
      "#{base_classes} #{color_classes}"
    when :border
      performance_level_border_classes(level)
    when :text
      performance_level_text_classes(level)
    else
      performance_level_color_classes(level)
    end
  end

  # Returns the color classes for a performance level (background and text)
  def performance_level_color_classes(performance_level)
    level = normalize_performance_level(performance_level)

    case level
    when :exceeds
      "bg-green-100 text-green-800"
    when :meets
      "bg-blue-100 text-blue-800"
    when :approaching
      "bg-amber-100 text-amber-800"
    when :below
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  # Returns border classes for rubric visualization
  def performance_level_border_classes(performance_level)
    level = normalize_performance_level(performance_level)

    case level
    when :exceeds
      "border-green-500 bg-green-100"
    when :meets
      "border-blue-500 bg-blue-100"
    when :approaching
      "border-amber-500 bg-amber-100"
    when :below
      "border-red-500 bg-red-100"
    else
      "border-gray-500 bg-gray-100"
    end
  end

  # Returns just the text color classes
  def performance_level_text_classes(performance_level)
    level = normalize_performance_level(performance_level)

    case level
    when :exceeds
      "text-green-600"
    when :meets
      "text-blue-600"
    when :approaching
      "text-amber-600"
    when :below
      "text-red-600"
    else
      "text-gray-600"
    end
  end

  # Returns the icon name for a performance level
  def performance_level_icon(performance_level)
    level = normalize_performance_level(performance_level)

    case level
    when :exceeds
      "star"
    when :meets
      "checkmark"
    when :approaching
      "exclamation"
    when :below
      "x_circle"
    else
      "star"
    end
  end

  # Returns the display text for a performance level
  def performance_level_text(performance_level)
    return "Not assessed" if performance_level.blank?

    level = normalize_performance_level(performance_level)

    case level
    when :exceeds
      "Exceeds"
    when :meets
      "Meets"
    when :approaching
      "Approaching"
    when :below
      "Below"
    else
      "Not assessed"
    end
  end

  # Size classes for performance badges
  def performance_badge_size_classes(size)
    case size.to_s
    when "sm"
      { wrapper: "px-3 py-1 text-sm", icon: "w-4 h-4" }
    when "lg"
      { wrapper: "px-6 py-3 text-lg", icon: "w-6 h-6" }
    else # md
      { wrapper: "px-4 py-2", icon: "w-5 h-5" }
    end
  end

  # Returns points for a given performance level
  def points_for_performance_level(performance_level)
    case performance_level.to_sym
    when :exceeds
      4
    when :meets
      3
    when :approaching
      2
    when :below
      1
    else
      3 # default to meets
    end
  end

  private

  # Normalizes various inputs to a performance level symbol
  def normalize_performance_level(level)
    return nil if level.blank?

    # Handle Level model instances
    if level.is_a?(Level)
      return level.performance_level.to_sym
    end

    # Handle string/symbol inputs
    level_str = level.to_s.downcase

    # Check if it's already a valid performance level
    valid_levels = [ :exceeds, :meets, :approaching, :below ]
    return level_str.to_sym if valid_levels.include?(level_str.to_sym)

    # Map legacy level names
    case level_str
    when /excee|excell/
      :exceeds
    when /meet|good|proficient|satisfactory/
      :meets
    when /approach|average|needs improvement/
      :approaching
    when /below|poor/
      :below
    else
      nil
    end
  end
end
