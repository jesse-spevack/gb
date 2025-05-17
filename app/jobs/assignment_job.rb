# frozen_string_literal: true

class AssignmentJob < ApplicationJob
  queue_as :default

  def perform(assignment_id)
    assignment = Assignment.find(assignment_id)
    Rails.logger.warn("AssignmentJob: Called for Assignment #{assignment_id} (#{assignment.title}) but implementation is pending")
  end
end
