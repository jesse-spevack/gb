# frozen_string_literal: true

module Pipeline::Context
  class AssignmentSummary < Base
    attr_accessor :assignment, :student_feedbacks, :saved_summary

    def student_work_count
      if student_feedbacks.present?
        student_feedbacks.size
      else
        assignment.student_works.count
      end
    end
  end
end
