# frozen_string_literal: true

class ProcessingStep::CreationService
  Result = Struct.new(:success, :processing_steps, :error_message, keyword_init: true) do
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
    ProcessingStep::STEP_KEYS.each do |step_key|
      @assignment.processing_steps.create!(step_key: step_key, status: :pending)
    end

    Result.new(success: true, processing_steps: @assignment.processing_steps, error_message: nil)
  end
end
