# frozen_string_literal: true

module Pipeline::Context
  class StudentWork < Base
    attr_accessor :assignment,
                  :rubric,
                  :selected_document,
                  :student_work,
                  :saved_feedback
  end
end
