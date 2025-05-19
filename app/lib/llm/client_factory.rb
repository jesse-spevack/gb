module LLM
  class ClientFactory
    def self.for_rubric_generation
      GoogleClient
    end

    def self.for_student_work_feedback
      AnthropicClient
    end

    def self.for_assignment_summary_feedback
      AnthropicClient
    end
  end
end
