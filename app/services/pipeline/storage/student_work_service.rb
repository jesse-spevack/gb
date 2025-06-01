# frozen_string_literal: true

module Pipeline
  module Storage
    # Service for storing generated student work feedback from the pipeline
    #
    # This service is called as part of the StudentWorkFeedbackPipeline after
    # the LLM has generated and parsed feedback for a student's work. It persists
    # all feedback data including qualitative feedback, specific feedback items,
    # verification checks, and criterion-level assessments.
    #
    # Expected context structure:
    #   - context.student_work: The StudentWork record to update
    #   - context.parsed_response: OpenStruct containing:
    #     - qualitative_feedback: String (overall feedback text)
    #     - feedback_items: Array of OpenStructs with:
    #       - item_type: String ('strength' or 'opportunity')
    #       - title: String
    #       - description: String
    #       - evidence: String
    #     - checks: Array of OpenStructs with:
    #       - check_type: String ('plagiarism' or 'llm_generated')
    #       - score: Integer (0-100)
    #       - explanation: String
    #     - criterion_levels: Array of OpenStructs with:
    #       - criterion_id: Integer
    #       - level_id: Integer
    #       - explanation: String
    #
    # Updates context with:
    #   - context.saved_feedback: The updated StudentWork with all associations
    #
    # @example
    #   context = Pipeline::Context::StudentWork.new
    #   context.student_work = student_work_record
    #   context.parsed_response = parsed_llm_response
    #   result = Pipeline::Storage::StudentWorkService.call(context: context)
    #
    class StudentWorkService
      def self.call(context:)
        Rails.logger.info("Storing feedback for student work: #{context.student_work.id}")

        ActiveRecord::Base.transaction do
          persist_feedback(context)
        end

        context
      rescue => e
        Rails.logger.error("Failed to store student work feedback: #{e.message}")
        raise
      end

      private

      def self.persist_feedback(context)
        student_work = context.student_work
        parsed_response = context.parsed_response

        # Update student work with qualitative feedback
        student_work.update!(
          qualitative_feedback: parsed_response.qualitative_feedback
        )

        # Create feedback items (strengths and opportunities)
        create_feedback_items(student_work, parsed_response.feedback_items)

        # Create student work checks
        create_checks(student_work, parsed_response.checks)

        # Create student criterion level associations
        create_criterion_levels(student_work, parsed_response.criterion_levels)

        # Update context with saved feedback
        context.saved_feedback = student_work.reload
      end

      def self.create_feedback_items(student_work, feedback_items_data)
        feedback_items_data.each do |item_data|
          FeedbackItem.create!(
            feedbackable: student_work,
            item_type: item_data.item_type,
            title: item_data.title,
            description: item_data.description,
            evidence: item_data.evidence
          )
        end
      end

      def self.create_checks(student_work, checks_data)
        checks_data.each do |check_data|
          StudentWorkCheck.create!(
            student_work: student_work,
            check_type: check_data.check_type,
            score: check_data.score,
            explanation: check_data.explanation
          )
        end
      end

      def self.create_criterion_levels(student_work, criterion_levels_data)
        criterion_levels_data.each do |level_data|
          StudentCriterionLevel.create!(
            student_work: student_work,
            criterion_id: level_data.criterion_id,
            level_id: level_data.level_id,
            explanation: level_data.explanation
          )
        end
      end
    end
  end
end
