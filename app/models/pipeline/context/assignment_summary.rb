# frozen_string_literal: true

module Pipeline::Context
  class AssignmentSummary < Base
    attr_accessor :assignment, :student_feedbacks, :saved_summary
  end
end
