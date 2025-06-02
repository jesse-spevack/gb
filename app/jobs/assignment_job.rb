# frozen_string_literal: true

class AssignmentJob < ApplicationJob
  queue_as :default

  def perform(assignment_id)
    start_time = Time.current

    begin
      # Create and execute AssignmentProcessor
      processor = AssignmentProcessor.new(assignment_id)
      result = processor.process

      # Log completion with timing information
      end_time = Time.current
      duration_ms = ((end_time - start_time) * 1000).round

      if result.successful?
        Rails.logger.info("AssignmentJob completed for assignment #{assignment_id} in #{duration_ms}ms")
      else
        Rails.logger.error("AssignmentJob failed for assignment #{assignment_id}: #{result.errors.join(', ')}")
      end

    rescue => e
      # Log the exception and re-raise to allow job retry/failure handling
      Rails.logger.error("AssignmentJob exception for assignment #{assignment_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      raise e
    end
  end
end
