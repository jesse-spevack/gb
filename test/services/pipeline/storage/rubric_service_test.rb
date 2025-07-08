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
        levels = criterion.levels.order(:performance_level)

        assert_equal 4, levels.count

        # Ordered by performance_level: exceeds(0), meets(1), approaching(2), below(3)
        assert_equal "Exceeds", levels[0].title
        assert_equal "exceeds", levels[0].performance_level
        assert_equal 4, levels[0].points

        assert_equal "Meets", levels[1].title
        assert_equal "meets", levels[1].performance_level
        assert_equal 3, levels[1].points

        assert_equal "Approaching", levels[2].title
        assert_equal "approaching", levels[2].performance_level
        assert_equal 2, levels[2].points

        assert_equal "Below", levels[3].title
        assert_equal "below", levels[3].performance_level
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

      test "calculates points correctly from performance level" do
        # Test the performance level to points mapping
        RubricService.call(context: @context)

        # Check all levels have the expected point mapping
        Level.all.each do |level|
          expected_points = case level.performance_level
          when "exceeds" then 4
          when "meets" then 3
          when "approaching" then 2
          when "below" then 1
          end
          assert_equal expected_points, level.points,
                       "Level with performance_level #{level.performance_level} should have #{expected_points} points"
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
                OpenStruct.new(name: "Exceeds", description: "Outstanding writing", performance_level: "exceeds"),
                OpenStruct.new(name: "Meets", description: "Good writing", performance_level: "meets"),
                OpenStruct.new(name: "Approaching", description: "Adequate writing", performance_level: "approaching"),
                OpenStruct.new(name: "Below", description: "Needs improvement", performance_level: "below")
              ]
            ),
            OpenStruct.new(
              title: "Research Depth",
              description: "Thorough research and analysis",
              position: 2,
              levels: [
                OpenStruct.new(name: "Exceeds", description: "Exceptional research", performance_level: "exceeds"),
                OpenStruct.new(name: "Meets", description: "Good research", performance_level: "meets"),
                OpenStruct.new(name: "Approaching", description: "Basic research", performance_level: "approaching"),
                OpenStruct.new(name: "Below", description: "Minimal research", performance_level: "below")
              ]
            )
          ]
        )
      end
    end
  end
end
