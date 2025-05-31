# frozen_string_literal: true

module Assignments
  # Service to check if an assignment's student works are all complete
  class CompletionChecker
    def self.call(assignment)
      return false unless assignment.rubric.present?
      return false if assignment.student_works.empty?

      assignment.student_works.all? { |work| work.qualitative_feedback.present? }
    end
  end
end