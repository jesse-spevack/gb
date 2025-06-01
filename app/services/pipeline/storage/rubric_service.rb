# frozen_string_literal: true

module Pipeline
  module Storage
    # Service for storing generated rubrics from the pipeline
    #
    # This service is called as part of the RubricPipeline after the LLM
    # has generated and parsed a rubric. It persists the rubric structure
    # to the database, creating criteria and levels with proper associations.
    #
    # Expected context structure:
    #   - context.assignment: The assignment needing a rubric
    #   - context.rubric: Existing rubric record to update
    #   - context.parsed_response: OpenStruct with criteria array, each containing:
    #     - title: String
    #     - description: String
    #     - position: Integer
    #     - levels: Array of OpenStructs with:
    #       - name: String
    #       - description: String
    #       - position: Integer (1=highest, 4=lowest)
    #
    # Updates context with:
    #   - context.rubric: The rubric with attached criteria and levels
    #
    # @example
    #   context = Pipeline::Context::Rubric.new
    #   context.rubric = existing_rubric
    #   context.parsed_response = parsed_llm_response
    #   result = Pipeline::Storage::RubricService.call(context: context)
    #
    class RubricService
      def self.call(context:)
        Rails.logger.info("Storing rubric for assignment: #{context.assignment.id}")

        context.rubric = attach_criteria_and_levels(context)
        context
      end

      private

      def self.attach_criteria_and_levels(context)
        rubric = nil

        ActiveRecord::Base.transaction do
          rubric = get_rubric(context)
          create_criteria_with_levels(rubric, context.parsed_response)
        end

        rubric
      rescue => e
        Rails.logger.error("Failed to create rubric: #{e.message}")
        raise
      end

      def self.get_rubric(context)
        # The existing rubric from context should always be available
        context.rubric
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
