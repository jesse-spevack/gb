# frozen_string_literal: true

require "test_helper"
require "ostruct"

module Pipeline
  module Storage
    class RubricServiceTest < ActiveSupport::TestCase
      setup do
        @assignment = assignments(:history_essay)
        @rubric = Rubric.create!(assignment: @assignment)
        @context = Pipeline::Context::Rubric.new
        @context.assignment = @assignment
        @context.rubric = @rubric
        @context.parsed_response = build_parsed_response
      end

      test "attaches criteria and levels to existing rubric" do
        assert_no_difference "Rubric.count" do
          assert_difference -> { Criterion.count } => 2,
                           -> { Level.count } => 8 do
            RubricService.call(context: @context)
          end
        end
      end


      test "assigns rubric to context" do
        result_context = RubricService.call(context: @context)

        assert_instance_of Rubric, result_context.rubric
        assert_equal @assignment, result_context.rubric.assignment
      end

      test "creates criteria with correct attributes" do
        RubricService.call(context: @context)

        rubric = Rubric.last
        criteria = rubric.criteria.order(:position)

        assert_equal 2, criteria.count

        first_criterion = criteria.first
        assert_equal "Writing Quality", first_criterion.title
        assert_equal "Clear and coherent writing", first_criterion.description
        assert_equal 1, first_criterion.position

        second_criterion = criteria.second
        assert_equal "Research Depth", second_criterion.title
        assert_equal "Thorough research and analysis", second_criterion.description
        assert_equal 2, second_criterion.position
      end

      test "creates levels with correct point assignments" do
        RubricService.call(context: @context)

        criterion = Criterion.find_by(title: "Writing Quality")
        levels = criterion.levels.order(:position)

        assert_equal 4, levels.count

        # Position 1 should get 4 points
        assert_equal "Exemplary", levels[0].title
        assert_equal 1, levels[0].position
        assert_equal 4, levels[0].points

        # Position 2 should get 3 points
        assert_equal "Proficient", levels[1].title
        assert_equal 2, levels[1].position
        assert_equal 3, levels[1].points

        # Position 3 should get 2 points
        assert_equal "Developing", levels[2].title
        assert_equal 3, levels[2].position
        assert_equal 2, levels[2].points

        # Position 4 should get 1 point
        assert_equal "Beginning", levels[3].title
        assert_equal 4, levels[3].position
        assert_equal 1, levels[3].points
      end

      test "ensures points are unique within criterion" do
        RubricService.call(context: @context)

        Criterion.all.each do |criterion|
          points_values = criterion.levels.pluck(:points)
          assert_equal points_values.uniq.count, points_values.count,
                       "Criterion #{criterion.title} has duplicate point values"
        end
      end

      test "wraps creation in transaction" do
        initial_rubric_count = Rubric.count
        initial_criterion_count = Criterion.count
        initial_level_count = Level.count

        # Mock a failure in level creation
        Level.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(Level.new))

        assert_raises(ActiveRecord::RecordInvalid) do
          RubricService.call(context: @context)
        end

        # Verify nothing was created due to transaction rollback
        assert_equal initial_rubric_count, Rubric.count
        assert_equal initial_criterion_count, Criterion.count
        assert_equal initial_level_count, Level.count
      end

      test "calculates points correctly from position" do
        # Test the private method indirectly through its usage
        RubricService.call(context: @context)

        # Check all levels have the expected point mapping
        Level.all.each do |level|
          expected_points = 5 - level.position
          assert_equal expected_points, level.points,
                       "Level with position #{level.position} should have #{expected_points} points"
        end
      end

      private

      def build_parsed_response
        OpenStruct.new(
          criteria: [
            OpenStruct.new(
              title: "Writing Quality",
              description: "Clear and coherent writing",
              position: 1,
              levels: [
                OpenStruct.new(name: "Exemplary", description: "Outstanding writing", position: 1),
                OpenStruct.new(name: "Proficient", description: "Good writing", position: 2),
                OpenStruct.new(name: "Developing", description: "Adequate writing", position: 3),
                OpenStruct.new(name: "Beginning", description: "Needs improvement", position: 4)
              ]
            ),
            OpenStruct.new(
              title: "Research Depth",
              description: "Thorough research and analysis",
              position: 2,
              levels: [
                OpenStruct.new(name: "Exemplary", description: "Exceptional research", position: 1),
                OpenStruct.new(name: "Proficient", description: "Good research", position: 2),
                OpenStruct.new(name: "Developing", description: "Basic research", position: 3),
                OpenStruct.new(name: "Beginning", description: "Minimal research", position: 4)
              ]
            )
          ]
        )
      end
    end
  end
end
