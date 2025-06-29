# frozen_string_literal: true

module PromptInput
  # Creates prompt input for student work feedback generation
  class StudentWork
    def self.call(context:)
      build_and_attach_to_context(context)
    end

    def self.build_and_attach_to_context(context)
      Rails.logger.info("Building prompt input for student work: #{context.student_work.id}")
      input = PromptInput::StudentWorkFeedback.from(student_work: context.student_work)
      context.prompt = PromptTemplate.build("student_feedback.txt.erb", input)
      context
    end
  end
end
