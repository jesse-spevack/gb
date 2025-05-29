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
        JSON.parse(@context.llm_response.text, symbolize_names: true)
      end

      def validate_structure(data)
        raise ValidationError, "Response must contain 'criteria' key" unless data.key?(:criteria)
        raise ValidationError, "Criteria cannot be empty" if data[:criteria].empty?

        data[:criteria].each_with_index do |criterion, index|
          validate_criterion(criterion, index)
        end
      end

      def validate_criterion(criterion, index)
        validate_required_field(criterion, :title, "Criterion #{index + 1}")
        validate_required_field(criterion, :description, "Criterion #{index + 1}")
        validate_required_field(criterion, :position, "Criterion #{index + 1}")

        unless criterion[:position].is_a?(Integer)
          raise ValidationError, "Criterion #{index + 1} position must be an integer"
        end

        validate_levels(criterion, index)
      end

      def validate_levels(criterion, criterion_index)
        unless criterion.key?(:levels)
          raise ValidationError, "Criterion #{criterion_index + 1} must have 'levels' array"
        end

        unless criterion[:levels].is_a?(Array)
          raise ValidationError, "Criterion #{criterion_index + 1} levels must be an array"
        end

        criterion[:levels].each_with_index do |level, level_index|
          validate_level(level, criterion_index, level_index)
        end
      end

      def validate_level(level, criterion_index, level_index)
        location = "Criterion #{criterion_index + 1}, Level #{level_index + 1}"

        validate_required_field(level, :name, location)
        validate_required_field(level, :description, location)
        validate_required_field(level, :position, location)

        unless level[:position].is_a?(Integer)
          raise ValidationError, "#{location} position must be an integer"
        end

        unless (1..4).include?(level[:position])
          raise ValidationError, "#{location} position must be between 1 and 4"
        end
      end

      def validate_required_field(hash, field, location)
        if !hash.key?(field) || hash[field].nil? || (hash[field].is_a?(String) && hash[field].strip.empty?)
          raise ValidationError, "#{location} must have a '#{field}'"
        end
      end

      def build_response(data)
        OpenStruct.new(
          criteria: data[:criteria].map { |criterion| build_criterion(criterion) }
        )
      end

      def build_criterion(criterion)
        OpenStruct.new(
          title: sanitize_string(criterion[:title]),
          description: sanitize_string(criterion[:description]),
          position: criterion[:position],
          levels: criterion[:levels].map { |level| build_level(level) }
        )
      end

      def build_level(level)
        OpenStruct.new(
          name: sanitize_string(level[:name]),
          description: sanitize_string(level[:description]),
          position: level[:position]
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
