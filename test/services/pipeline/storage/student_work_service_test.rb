# frozen_string_literal: true

require "ostruct"
require "test_helper"

module Pipeline
  module Storage
    class StudentWorkServiceTest < ActiveSupport::TestCase
      setup do
        @assignment = assignments(:english_essay)
        @rubric = rubrics(:english_essay_rubric)
        @student_work = student_works(:student_essay_one)

        # Clear any existing associated data
        @student_work.feedback_items.destroy_all
        @student_work.student_work_checks.destroy_all
        @student_work.student_criterion_levels.destroy_all

        @context = Pipeline::Context::StudentWork.new
        @context.assignment = @assignment
        @context.rubric = @rubric
        @context.student_work = @student_work
        @context.parsed_response = build_parsed_response
      end

      test "updates student work with qualitative feedback" do
        StudentWorkService.call(context: @context)

        @student_work.reload
        assert_equal "This essay demonstrates a solid understanding of the historical period...",
                     @student_work.qualitative_feedback
      end

      test "creates feedback items with correct attributes" do
        assert_difference "FeedbackItem.count", 4 do
          StudentWorkService.call(context: @context)
        end

        feedback_items = @student_work.feedback_items.order(:id)

        # Check strengths
        strength1 = feedback_items.find { |f| f.item_type == "strength" && f.title == "Clear thesis statement" }
        assert_not_nil strength1
        assert_equal "The thesis is well-articulated and focused", strength1.description
        assert_equal "Opening paragraph clearly states the main argument", strength1.evidence

        strength2 = feedback_items.find { |f| f.item_type == "strength" && f.title == "Good use of evidence" }
        assert_not_nil strength2
        assert_equal "Multiple primary sources are cited effectively", strength2.description
        assert_equal "Pages 2-3 include relevant quotes from historical documents", strength2.evidence

        # Check opportunities
        opportunity1 = feedback_items.find { |f| f.item_type == "opportunity" && f.title == "Expand analysis" }
        assert_not_nil opportunity1
        assert_equal "Some arguments could be developed further", opportunity1.description
        assert_equal "The second body paragraph ends abruptly", opportunity1.evidence

        opportunity2 = feedback_items.find { |f| f.item_type == "opportunity" && f.title == "Improve transitions" }
        assert_not_nil opportunity2
        assert_equal "Transitions between paragraphs could be smoother", opportunity2.description
        assert_equal "The connection between paragraphs 3 and 4 is unclear", opportunity2.evidence
      end

      test "creates student work checks" do
        assert_difference "StudentWorkCheck.count", 2 do
          StudentWorkService.call(context: @context)
        end

        checks = @student_work.student_work_checks.order(:id)

        plagiarism_check = checks.find { |c| c.check_type == "plagiarism" }
        assert_not_nil plagiarism_check
        assert_equal 10, plagiarism_check.score
        assert_equal "Minor similarities found", plagiarism_check.explanation

        llm_check = checks.find { |c| c.check_type == "llm_generated" }
        assert_not_nil llm_check
        assert_equal 5, llm_check.score
        assert_equal "Writing appears to be original student work", llm_check.explanation
      end

      test "creates student criterion level associations" do
        assert_difference "StudentCriterionLevel.count", 2 do
          StudentWorkService.call(context: @context)
        end

        criterion_levels = @student_work.student_criterion_levels.includes(:criterion, :level)

        # Check first criterion level
        first_assessment = criterion_levels.find { |scl| scl.criterion_id == criteria(:writing_quality).id }
        assert_not_nil first_assessment
        assert_equal levels(:writing_proficient).id, first_assessment.level_id
        assert first_assessment.explanation.present?

        # Check second criterion level
        second_assessment = criterion_levels.find { |scl| scl.criterion_id == criteria(:content_depth).id }
        assert_not_nil second_assessment
        assert_equal levels(:content_developing).id, second_assessment.level_id
        assert second_assessment.explanation.present?
      end

      test "updates context with saved student work" do
        result_context = StudentWorkService.call(context: @context)

        assert_equal @student_work, result_context.student_work
        assert_equal @student_work.id, result_context.student_work.id
      end

      test "wraps all operations in a transaction" do
        # Mock a failure in feedback item creation
        FeedbackItem.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(FeedbackItem.new))

        initial_feedback = @student_work.qualitative_feedback
        initial_feedback_count = FeedbackItem.count
        initial_check_count = StudentWorkCheck.count
        initial_criterion_level_count = StudentCriterionLevel.count

        assert_raises(ActiveRecord::RecordInvalid) do
          StudentWorkService.call(context: @context)
        end

        # Verify nothing was saved due to transaction rollback
        @student_work.reload
        assert_equal initial_feedback, @student_work.qualitative_feedback
        assert_equal initial_feedback_count, FeedbackItem.count
        assert_equal initial_check_count, StudentWorkCheck.count
        assert_equal initial_criterion_level_count, StudentCriterionLevel.count
      end

      test "handles missing parsed response gracefully" do
        @context.parsed_response = nil

        assert_raises(NoMethodError) do
          StudentWorkService.call(context: @context)
        end
      end

      test "logs errors when persistence fails" do
        # Mock update failure
        StudentWork.any_instance.stubs(:update!).raises(ActiveRecord::RecordInvalid.new(@student_work))

        Rails.logger.expects(:error).with(regexp_matches(/Failed to store student work feedback/))

        assert_raises(ActiveRecord::RecordInvalid) do
          StudentWorkService.call(context: @context)
        end
      end

      private

      def build_parsed_response
        OpenStruct.new(
          qualitative_feedback: "This essay demonstrates a solid understanding of the historical period...",
          feedback_items: [
            OpenStruct.new(
              item_type: "strength",
              title: "Clear thesis statement",
              description: "The thesis is well-articulated and focused",
              evidence: "Opening paragraph clearly states the main argument"
            ),
            OpenStruct.new(
              item_type: "strength",
              title: "Good use of evidence",
              description: "Multiple primary sources are cited effectively",
              evidence: "Pages 2-3 include relevant quotes from historical documents"
            ),
            OpenStruct.new(
              item_type: "opportunity",
              title: "Expand analysis",
              description: "Some arguments could be developed further",
              evidence: "The second body paragraph ends abruptly"
            ),
            OpenStruct.new(
              item_type: "opportunity",
              title: "Improve transitions",
              description: "Transitions between paragraphs could be smoother",
              evidence: "The connection between paragraphs 3 and 4 is unclear"
            )
          ],
          checks: [
            OpenStruct.new(
              check_type: "plagiarism",
              score: 10,
              explanation: "Minor similarities found"
            ),
            OpenStruct.new(
              check_type: "llm_generated",
              score: 5,
              explanation: "Writing appears to be original student work"
            )
          ],
          criterion_levels: [
            OpenStruct.new(
              criterion_id: criteria(:writing_quality).id,
              level_id: levels(:writing_proficient).id,
              explanation: "The thesis is clear and well-supported throughout the essay"
            ),
            OpenStruct.new(
              criterion_id: criteria(:content_depth).id,
              level_id: levels(:content_developing).id,
              explanation: "Evidence is present but could be more thoroughly analyzed"
            )
          ]
        )
      end
    end
  end
end
