# frozen_string_literal: true

class Rubric::CreationService
  Result = Struct.new(:success, :rubric, :error_message, keyword_init: true) do
    def success?
      success
    end
  end

  def self.create(assignment:)
    new(assignment).create
  end

  def initialize(assignment)
    @assignment = assignment
  end

  def create
    rubric = Rubric.create!(assignment: @assignment)
    Result.new(success: true, rubric: rubric, error_message: nil)
  end
end
