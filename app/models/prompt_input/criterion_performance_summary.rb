# frozen_string_literal: true

module PromptInput
  class CriterionPerformanceSummary
    attr_reader :criterion_title, :average_level, :min_level, :max_level, :count

    def initialize(criterion_title:, average_level:, min_level:, max_level:, count:)
      @criterion_title = criterion_title
      @average_level = average_level
      @min_level = min_level
      @max_level = max_level
      @count = count
    end
  end
end
