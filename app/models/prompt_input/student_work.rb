# frozen_string_literal: true

module PromptInput
  # Creates prompt input for student work feedback generation
  class StudentWork
    def self.call(context:)
      build_and_attach_to_context(context)
    end

    def self.build_and_attach_to_context(context)
      Rails.logger.info("Building prompt input for student work: #{context.student_work.id}")
      context.prompt = "Analyze the student work and provide feedback"
      context
    end
  end
end
