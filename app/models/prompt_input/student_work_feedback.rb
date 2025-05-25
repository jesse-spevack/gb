# frozen_string_literal: true

module PromptInput
  class StudentWorkFeedback
    def self.from(student_work:)
      new(student_work)
    end

    def initialize(student_work)
      @student_work = student_work
      @assignment = student_work.assignment
      @rubric = @assignment.rubric
      @drive_service = Google::DriveService.new(@assignment.user)
      @selected_document = @student_work.selected_document
    end

    def assignment_title
      @assignment.title
    end

    def assignment_subject
      @assignment.subject
    end

    def assignment_grade_level
      @assignment.grade_level
    end

    def assignment_instructions
      @assignment.instructions
    end

    def assignment_feedback_tone
      @assignment.feedback_tone
    end

    def assignment_feedback_tone_detail
      case @assignment.feedback_tone
      when "Encouraging"
        encouraging_detail
      when "Neutral/Objective"
        neutral_objective_detail
      when "Critical"
        critical_detail
      end
    end

    def selected_document_title
      @selected_document.title
    end

    def student_work_id
      @student_work.id
    end

    def content
      @content ||= @drive_service.fetch_document_content(@selected_document.google_doc_id)
    end

    def criteria
      @rubric.criteria
    end

    private

    def critical_detail
      <<~TEXT
        - You are a driven teacher constantly raising the bar for student achievement.
        - Provide direct, detailed analysis with high expectations for improvement.
        - Nothing is ever good enough. Always raise the bar for quality.
      TEXT
    end

    def neutral_objective_detail
      <<~TEXT
        - You are a referee with no inherent interest in the student's success or failure.
        - Focus on clear, concise, factual assessment with balanced feedback.
        - Ensure the feedback is rooted in the assignment requirements and rubric.
      TEXT
    end

    def encouraging_detail
      <<~TEXT
        - You are like a proud coach, praising the student's strengths and encouraging them to continue growing.
        - Emphasize growth, potential, and positive reinforcement, while also maintaining high expectations and standards.
        - Ensure the student feels supported and encouraged to continue learning and growing.
      TEXT
    end
  end
end
