# frozen_string_literal: true

require "ostruct"
require "test_helper"

module Pipeline
  module Storage
    class IntegrationTest < ActiveSupport::TestCase
      setup do
        @assignment = assignments(:history_essay)
        @rubric = nil  # Will be created by RubricService
        @student_work = student_works(:student_essay_one)

        # Clear any existing data to ensure clean test
        @assignment.rubric&.destroy
        @assignment.assignment_summary&.destroy
        @student_work.feedback_items.destroy_all
        @student_work.student_work_checks.destroy_all
        @student_work.student_criterion_levels.destroy_all
      end

      test "full pipeline storage workflow creates all expected records" do
        # Step 1: Create and store rubric
        rubric_context = create_rubric_context
        rubric_result = RubricService.call(context: rubric_context)

        assert_not_nil rubric_result.rubric
        assert_equal 2, rubric_result.rubric.criteria.count
        assert_equal 8, Level.where(criterion: rubric_result.rubric.criteria).count

        # Step 2: Store student work feedback
        student_context = create_student_work_context(rubric_result.rubric)
        student_result = StudentWorkService.call(context: student_context)

        assert_not_nil student_result.student_work
        assert_equal "This essay demonstrates excellent understanding...",
                     student_result.student_work.qualitative_feedback
        assert_equal 4, student_result.student_work.feedback_items.count
        assert_equal 2, student_result.student_work.student_work_checks.count
        assert_equal 2, student_result.student_work.student_criterion_levels.count

        # Step 3: Create assignment summary
        summary_context = create_assignment_summary_context([ student_result.student_work ])
        summary_result = AssignmentSummaryService.call(context: summary_context)

        assert_not_nil summary_result.saved_summary
        assert_equal "The class overall showed strong comprehension...",
                     summary_result.saved_summary.qualitative_insights
        assert_equal 1, summary_result.saved_summary.student_work_count
        assert_equal 4, summary_result.saved_summary.feedback_items.count
      end

      test "contexts are properly passed between services" do
        # Create rubric
        rubric_context = create_rubric_context
        rubric_context = RubricService.call(context: rubric_context)

        # Pass rubric to student work service
        student_context = create_student_work_context(rubric_context.rubric)
        student_context = StudentWorkService.call(context: student_context)

        # Collect multiple student feedbacks for summary
        student_feedbacks = [ student_context.student_work ]

        # Create additional student work for more realistic summary
        student_work2 = student_works(:student_essay_with_rubric)
        student_context2 = create_student_work_context(rubric_context.rubric, student_work2)
        student_context2 = StudentWorkService.call(context: student_context2)
        student_feedbacks << student_context2.student_work

        # Pass student feedbacks to summary service
        summary_context = create_assignment_summary_context(student_feedbacks)
        summary_context = AssignmentSummaryService.call(context: summary_context)

        # Verify summary has correct student count
        assert_equal 2, summary_context.saved_summary.student_work_count
      end

      test "transaction rollback prevents partial data creation" do
        # Test rubric service rollback
        rubric_context = create_rubric_context
        Level.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(Level.new))

        assert_no_difference [ "Rubric.count", "Criterion.count", "Level.count" ] do
          assert_raises(ActiveRecord::RecordInvalid) do
            RubricService.call(context: rubric_context)
          end
        end

        Level.unstub(:create!)

        # Create rubric successfully for next tests
        rubric_context = create_rubric_context
        rubric_result = RubricService.call(context: rubric_context)

        # Test student work service rollback
        student_context = create_student_work_context(rubric_result.rubric)
        FeedbackItem.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(FeedbackItem.new))

        initial_feedback = @student_work.qualitative_feedback

        assert_no_difference [ "FeedbackItem.count", "StudentWorkCheck.count", "StudentCriterionLevel.count" ] do
          assert_raises(ActiveRecord::RecordInvalid) do
            StudentWorkService.call(context: student_context)
          end
        end

        @student_work.reload
        assert_equal initial_feedback, @student_work.qualitative_feedback

        FeedbackItem.unstub(:create!)

        # Test summary service rollback
        summary_context = create_assignment_summary_context([])
        FeedbackItem.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(FeedbackItem.new))

        assert_no_difference [ "AssignmentSummary.count", "FeedbackItem.count" ] do
          assert_raises(ActiveRecord::RecordInvalid) do
            AssignmentSummaryService.call(context: summary_context)
          end
        end
      end

      test "services handle complex rubric with multiple criteria and levels" do
        # Create rubric with 4 criteria, each with 4 levels
        rubric_context = create_complex_rubric_context
        rubric_result = RubricService.call(context: rubric_context)

        assert_equal 4, rubric_result.rubric.criteria.count
        assert_equal 16, Level.where(criterion: rubric_result.rubric.criteria).count

        # Verify points are correctly assigned
        rubric_result.rubric.criteria.each do |criterion|
          levels = criterion.levels.order(:position)
          assert_equal [ 4, 3, 2, 1 ], levels.pluck(:position)
        end
      end

      private

      def create_rubric_context
        context = Pipeline::Context::Rubric.new
        context.assignment = @assignment
        context.rubric = Rubric.create!(assignment: @assignment)
        context.parsed_response = OpenStruct.new(
          criteria: [
            OpenStruct.new(
              title: "Thesis Statement",
              description: "Clear and focused argument",
              position: 1,
              levels: [
                OpenStruct.new(name: "Exemplary", description: "Exceptional thesis", position: 1),
                OpenStruct.new(name: "Proficient", description: "Strong thesis", position: 2),
                OpenStruct.new(name: "Developing", description: "Basic thesis", position: 3),
                OpenStruct.new(name: "Beginning", description: "Weak thesis", position: 4)
              ]
            ),
            OpenStruct.new(
              title: "Evidence",
              description: "Use of supporting evidence",
              position: 2,
              levels: [
                OpenStruct.new(name: "Exemplary", description: "Outstanding evidence", position: 1),
                OpenStruct.new(name: "Proficient", description: "Good evidence", position: 2),
                OpenStruct.new(name: "Developing", description: "Some evidence", position: 3),
                OpenStruct.new(name: "Beginning", description: "Limited evidence", position: 4)
              ]
            )
          ]
        )
        context
      end

      def create_complex_rubric_context
        context = Pipeline::Context::Rubric.new
        context.assignment = @assignment
        context.rubric = Rubric.create!(assignment: @assignment)

        criteria_data = []
        [ "Thesis", "Evidence", "Analysis", "Writing" ].each_with_index do |criterion_name, idx|
          criteria_data << OpenStruct.new(
            title: criterion_name,
            description: "#{criterion_name} assessment",
            position: idx + 1,
            levels: [
              OpenStruct.new(name: "Exemplary", description: "Outstanding #{criterion_name.downcase}", position: 1),
              OpenStruct.new(name: "Proficient", description: "Good #{criterion_name.downcase}", position: 2),
              OpenStruct.new(name: "Developing", description: "Basic #{criterion_name.downcase}", position: 3),
              OpenStruct.new(name: "Beginning", description: "Needs work on #{criterion_name.downcase}", position: 4)
            ]
          )
        end

        context.parsed_response = OpenStruct.new(criteria: criteria_data)
        context
      end

      def create_student_work_context(rubric, student_work = @student_work)
        context = Pipeline::Context::StudentWork.new
        context.assignment = @assignment
        context.rubric = rubric
        context.student_work = student_work

        # Get actual criterion and level IDs from the created rubric
        criteria = rubric.criteria.order(:position)
        thesis_criterion = criteria[0]
        evidence_criterion = criteria[1]

        context.parsed_response = OpenStruct.new(
          qualitative_feedback: "This essay demonstrates excellent understanding...",
          feedback_items: [
            OpenStruct.new(
              item_type: "strength",
              title: "Strong thesis",
              description: "Well-articulated main argument",
              evidence: "Introduction paragraph"
            ),
            OpenStruct.new(
              item_type: "strength",
              title: "Good sources",
              description: "Excellent use of primary sources",
              evidence: "Throughout the essay"
            ),
            OpenStruct.new(
              item_type: "opportunity",
              title: "Deeper analysis",
              description: "Could explore implications further",
              evidence: "Conclusion section"
            ),
            OpenStruct.new(
              item_type: "opportunity",
              title: "Transitions",
              description: "Improve paragraph connections",
              evidence: "Between main sections"
            )
          ],
          checks: [
            OpenStruct.new(check_type: "plagiarism", score: 10, explanation: "Minor similarities found"),
            OpenStruct.new(check_type: "llm_generated", score: 5, explanation: "Appears to be original work")
          ],
          criterion_levels: [
            OpenStruct.new(
              criterion_id: thesis_criterion.id,
              level_id: thesis_criterion.levels.find_by(position: 2).id,  # Proficient
              explanation: "Clear thesis with good support"
            ),
            OpenStruct.new(
              criterion_id: evidence_criterion.id,
              level_id: evidence_criterion.levels.find_by(position: 1).id,  # Exemplary
              explanation: "Excellent use of primary sources"
            )
          ]
        )
        context
      end

      def create_assignment_summary_context(student_feedbacks)
        context = Pipeline::Context::AssignmentSummary.new
        context.assignment = @assignment
        context.student_feedbacks = student_feedbacks
        context.parsed_response = OpenStruct.new(
          qualitative_insights: "The class overall showed strong comprehension...",
          feedback_items: [
            OpenStruct.new(
              item_type: "strength",
              title: "Class engagement",
              description: "Students showed deep interest in the topic",
              evidence: "Quality of arguments presented"
            ),
            OpenStruct.new(
              item_type: "strength",
              title: "Research skills",
              description: "Good use of historical sources",
              evidence: "Average of 6 sources per essay"
            ),
            OpenStruct.new(
              item_type: "opportunity",
              title: "Critical thinking",
              description: "More analysis of cause and effect needed",
              evidence: "Surface-level conclusions in 40% of essays"
            ),
            OpenStruct.new(
              item_type: "opportunity",
              title: "Writing mechanics",
              description: "Grammar and punctuation need attention",
              evidence: "Common errors found across submissions"
            )
          ]
        )
        context
      end
    end
  end
end
