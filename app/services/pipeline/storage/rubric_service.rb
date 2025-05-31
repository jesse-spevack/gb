# frozen_string_literal: true

module Pipeline
  module Storage
    # Service for storing generated rubrics from the pipeline
    class RubricService
      def self.call(context:)
        Rails.logger.info("Storing rubric for assignment: #{context.assignment.id}")

        context.rubric = create_rubric_with_criteria_and_levels(context)
        context
      end

      private

      def self.create_rubric_with_criteria_and_levels(context)
        rubric = nil
        
        ActiveRecord::Base.transaction do
          rubric = create_rubric(context)
          create_criteria_with_levels(rubric, context.parsed_response)
        end
        
        rubric
      rescue => e
        Rails.logger.error("Failed to create rubric: #{e.message}")
        raise
      end

      def self.create_rubric(context)
        Rubric.create!(assignment: context.assignment)
      end

      def self.create_criteria_with_levels(rubric, parsed_response)
        parsed_response.criteria.each do |criterion_data|
          criterion = create_criterion(rubric, criterion_data)
          create_levels_for_criterion(criterion, criterion_data.levels)
        end
      end

      def self.create_criterion(rubric, criterion_data)
        Criterion.create!(
          rubric: rubric,
          title: criterion_data.title,
          description: criterion_data.description,
          position: criterion_data.position
        )
      end

      def self.create_levels_for_criterion(criterion, levels_data)
        levels_data.each do |level_data|
          points = calculate_points_from_position(level_data.position)
          
          Level.create!(
            criterion: criterion,
            title: level_data.name,
            description: level_data.description,
            position: level_data.position,
            points: points
          )
        end
      end

      def self.calculate_points_from_position(position)
        # Map position to points inversely:
        # Position 1 (highest achievement) = 4 points
        # Position 2 = 3 points
        # Position 3 = 2 points
        # Position 4 (lowest achievement) = 1 point
        5 - position
      end
    end
  end
end
