# frozen_string_literal: true

require "ostruct"

module LLM
  module Rubric
    # Parser for LLM-generated rubric responses
    class ResponseParser
      class ValidationError < StandardError; end

      def self.call(context:)
        new(context).call
      end

      def initialize(context)
        @context = context
      end

      def call
        Rails.logger.info("Parsing rubric response for assignment: #{@context.assignment.id}")

        parsed_json = parse_json
        validate_structure(parsed_json)

        @context.parsed_response = build_response(parsed_json)
        @context
      rescue JSON::ParserError => e
        log_error("JSON parsing failed", e, {
          assignment_id: @context.assignment.id,
          error_location: identify_json_error_location(e.message)
        })
        raise JSON::ParserError, "Failed to parse rubric response as valid JSON. #{e.message}"
      rescue ValidationError => e
        log_error("Rubric validation failed", e, {
          assignment_id: @context.assignment.id,
          validation_type: extract_validation_type(e.message)
        })
        raise
      rescue StandardError => e
        log_error("Unexpected error during rubric parsing", e, {
          assignment_id: @context.assignment.id
        })
        raise
      end

      private

      def parse_json
        clean_text = strip_markdown_formatting(@context.llm_response.text)
        JSON.parse(clean_text, symbolize_names: true)
      end

      def strip_markdown_formatting(text)
        # Remove markdown code block formatting if present
        text = text.strip
        if text.start_with?("```json")
          text = text.sub(/\A```json\n?/, "").sub(/\n?```\z/, "")
        elsif text.start_with?("```")
          text = text.sub(/\A```\n?/, "").sub(/\n?```\z/, "")
        end
        text.strip
      end

      def validate_structure(data)
        # Handle both direct criteria and rubric.criteria structures
        criteria_data = extract_criteria(data)
        raise ValidationError, "Response must contain 'criteria' key" unless criteria_data
        raise ValidationError, "Criteria cannot be empty" if criteria_data.empty?

        criteria_data.each_with_index do |criterion, index|
          validate_criterion(criterion, index)
        end
      end

      def extract_criteria(data)
        if data.key?(:criteria)
          data[:criteria]
        elsif data.key?(:rubric) && data[:rubric].is_a?(Hash) && data[:rubric].key?(:criteria)
          data[:rubric][:criteria]
        else
          nil
        end
      end

      def validate_criterion(criterion, index)
        # Handle different field names for criterion title
        title_field = if criterion.key?(:title)
          :title
        elsif criterion.key?(:criterion)
          :criterion
        elsif criterion.key?(:name)
          :name
        else
          raise ValidationError, "Criterion #{index + 1} must have a 'title', 'criterion', or 'name' field"
        end

        validate_required_field(criterion, title_field, "Criterion #{index + 1}")

        # Description is optional for some formats
        if criterion.key?(:description)
          validate_required_field(criterion, :description, "Criterion #{index + 1}")
        end

        # Position might not always be present
        if criterion.key?(:position)
          unless criterion[:position].is_a?(Integer)
            raise ValidationError, "Criterion #{index + 1} position must be an integer"
          end
        end

        validate_levels(criterion, index)
      end

      def validate_levels(criterion, criterion_index)
        # Handle both 'levels' and 'descriptors' field names
        levels_field = criterion.key?(:levels) ? :levels : :descriptors

        unless criterion.key?(levels_field)
          raise ValidationError, "Criterion #{criterion_index + 1} must have '#{levels_field}' array"
        end

        unless criterion[levels_field].is_a?(Array)
          raise ValidationError, "Criterion #{criterion_index + 1} #{levels_field} must be an array"
        end

        criterion[levels_field].each_with_index do |level, level_index|
          validate_level(level, criterion_index, level_index)
        end
      end

      def validate_level(level, criterion_index, level_index)
        location = "Criterion #{criterion_index + 1}, Level #{level_index + 1}"

        # Handle different field names for level name
        name_field = if level.key?(:name)
          :name
        elsif level.key?(:level)
          :level
        elsif level.key?(:grade)
          :grade
        elsif level.key?(:score)
          :score
        else
          raise ValidationError, "#{location} must have a 'name', 'level', 'grade', or 'score' field"
        end

        validate_required_field(level, name_field, location)
        validate_required_field(level, :description, location)

        # Position might not always be present or might be named differently
        if level.key?(:position)
          unless level[:position].is_a?(Integer)
            raise ValidationError, "#{location} position must be an integer"
          end
          unless (1..4).include?(level[:position])
            raise ValidationError, "#{location} position must be between 1 and 4"
          end
        elsif level.key?(:points)
          # Some formats use points instead of position - allow string or integer
          # Don't validate the value since it might be a range like "22-25"
        end
      end

      def validate_required_field(hash, field, location)
        if !hash.key?(field) || hash[field].nil? || (hash[field].is_a?(String) && hash[field].strip.empty?)
          raise ValidationError, "#{location} must have a '#{field}'"
        end
      end

      def build_response(data)
        criteria_data = extract_criteria(data)
        parsed_criteria = criteria_data.map { |criterion| build_criterion(criterion) }

        # Log the parsed structure for debugging
        Rails.logger.info("Parsed rubric structure for assignment #{@context.assignment.id}:")
        parsed_criteria.each_with_index do |criterion, idx|
          Rails.logger.info("  Criterion #{idx + 1}: #{criterion.title}")
          criterion.levels.each do |level|
            Rails.logger.info("    Level: #{level.name} (position: #{level.position})")
          end
        end

        OpenStruct.new(
          criteria: parsed_criteria
        )
      end

      def build_criterion(criterion)
        # Handle different field names for criterion title
        title_field = if criterion.key?(:title)
          :title
        elsif criterion.key?(:criterion)
          :criterion
        elsif criterion.key?(:name)
          :name
        else
          :title # default fallback
        end

        levels_field = criterion.key?(:levels) ? :levels : :descriptors
        levels_array = criterion[levels_field]

        # Build levels with proper position assignments
        levels = levels_array.map.with_index do |level, index|
          build_level(level, index, levels_array.length)
        end

        OpenStruct.new(
          title: sanitize_string(criterion[title_field]),
          description: sanitize_string(criterion[:description] || ""),
          position: criterion[:position] || 1,
          levels: levels
        )
      end

      def build_level(level, index = 0, total_levels = 4)
        # Handle different field names for level name
        name_field = if level.key?(:name)
          :name
        elsif level.key?(:level)
          :level
        elsif level.key?(:grade)
          :grade
        elsif level.key?(:score)
          :score
        else
          :name # default fallback
        end

        # For position, try different fields or assign based on array order
        position = if level.key?(:position) && level[:position].is_a?(Integer) && (1..4).include?(level[:position])
          level[:position]
        else
          # Assign positions based on array order
          # First item gets highest position (4), last gets lowest (1)
          # This assumes levels are ordered from best to worst in the LLM response
          total_levels - index
        end

        # Ensure position is in valid range (1-4)
        position = [ [ position, 1 ].max, 4 ].min

        OpenStruct.new(
          name: sanitize_string(level[name_field]),
          description: sanitize_string(level[:description]),
          position: position
        )
      end

      def sanitize_string(str)
        return str unless str.is_a?(String)
        str.strip
      end

      def log_error(message, exception, context_data = {})
        Rails.logger.error({
          message: message,
          error_class: exception.class.name,
          error_message: exception.message,
          assignment_id: @context.assignment&.id,
          response_preview: @context.llm_response&.text&.first(200),
          **context_data
        }.to_json)

        Rails.logger.error("Original response: #{@context.llm_response.text}") if @context.llm_response&.text
      end

      def identify_json_error_location(error_message)
        # Extract line/column info from JSON parse errors if available
        if error_message =~ /line (\d+) column (\d+)/
          { line: $1, column: $2 }
        else
          { details: error_message }
        end
      end

      def extract_validation_type(error_message)
        case error_message
        when /criteria.*empty/i
          "empty_criteria"
        when /must have.*title/i
          "missing_title"
        when /must have.*description/i
          "missing_description"
        when /must have.*position/i
          "missing_position"
        when /position.*integer/i
          "invalid_position_type"
        when /position.*between/i
          "position_out_of_range"
        when /levels.*array/i
          "invalid_levels_type"
        when /must have.*levels/i
          "missing_levels"
        else
          "unknown"
        end
      end
    end
  end
end
