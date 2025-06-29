# frozen_string_literal: true

require "ostruct"

module LLM
  module StudentWork
    # Parser for LLM-generated student work feedback responses
    class ResponseParser
      class ValidationError < StandardError; end

      def self.call(context:)
        new(context).call
      end

      def initialize(context)
        @context = context
      end

      def call
        Rails.logger.info("Parsing feedback response for student work: #{@context.student_work.id}")

        parsed_json = parse_json
        validate_structure(parsed_json)

        @context.parsed_response = build_response(parsed_json)
        @context
      rescue JSON::ParserError => e
        log_error("JSON parsing failed", e, {
          student_work_id: @context.student_work.id,
          error_location: identify_json_error_location(e.message)
        })
        raise JSON::ParserError, "Failed to parse student work feedback response as valid JSON. #{e.message}"
      rescue ValidationError => e
        log_error("Student work validation failed", e, {
          student_work_id: @context.student_work.id,
          validation_type: extract_validation_type(e.message)
        })
        raise
      rescue StandardError => e
        log_error("Unexpected error during student work parsing", e, {
          student_work_id: @context.student_work.id
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
        validate_qualitative_feedback(data)
        validate_feedback_items(data)
        validate_criterion_levels(data)
        validate_checks(data)
      end

      def validate_qualitative_feedback(data)
        unless data.key?(:qualitative_feedback) && !data[:qualitative_feedback].nil?
          raise ValidationError, "Response must contain 'qualitative_feedback'"
        end

        unless data[:qualitative_feedback].is_a?(String)
          raise ValidationError, "qualitative_feedback must be a string"
        end
      end

      def validate_feedback_items(data)
        unless data.key?(:feedback_items)
          raise ValidationError, "Response must contain 'feedback_items' array"
        end

        unless data[:feedback_items].is_a?(Array)
          raise ValidationError, "feedback_items must be an array"
        end

        data[:feedback_items].each_with_index do |item, index|
          validate_feedback_item(item, index)
        end
      end

      def validate_feedback_item(item, index)
        location = "Feedback item #{index + 1}"

        validate_required_field(item, :item_type, location)
        validate_required_field(item, :title, location)
        validate_required_field(item, :description, location)
        validate_required_field(item, :evidence, location)

        unless %w[strength opportunity].include?(item[:item_type])
          raise ValidationError, "#{location} item_type must be either 'strength' or 'opportunity'"
        end
      end

      def validate_criterion_levels(data)
        unless data.key?(:criterion_levels)
          raise ValidationError, "Response must contain 'criterion_levels' array"
        end

        unless data[:criterion_levels].is_a?(Array)
          raise ValidationError, "criterion_levels must be an array"
        end

        data[:criterion_levels].each_with_index do |level, index|
          validate_criterion_level(level, index)
        end
      end

      def validate_criterion_level(level, index)
        location = "Criterion level #{index + 1}"

        validate_required_field(level, :criterion_id, location)
        validate_required_field(level, :level_id, location)
        validate_required_field(level, :explanation, location)

        unless level[:criterion_id].is_a?(Integer)
          raise ValidationError, "#{location} criterion_id must be an integer"
        end

        unless level[:level_id].is_a?(Integer)
          raise ValidationError, "#{location} level_id must be an integer"
        end
      end

      def validate_checks(data)
        unless data.key?(:checks)
          raise ValidationError, "Response must contain 'checks' array"
        end

        unless data[:checks].is_a?(Array)
          raise ValidationError, "checks must be an array"
        end

        data[:checks].each_with_index do |check, index|
          validate_check(check, index)
        end
      end

      def validate_check(check, index)
        location = "Check #{index + 1}"

        validate_required_field(check, :check_type, location)
        validate_required_field(check, :score, location)
        validate_required_field(check, :explanation, location)

        unless %w[plagiarism llm_generated].include?(check[:check_type])
          raise ValidationError, "#{location} check_type must be either 'plagiarism' or 'llm_generated'"
        end

        unless check[:score].is_a?(Numeric)
          raise ValidationError, "#{location} score must be a number"
        end

        unless (0..100).include?(check[:score])
          raise ValidationError, "#{location} score must be between 0 and 100"
        end
      end

      def validate_required_field(hash, field, location)
        if !hash.key?(field) || hash[field].nil? || (hash[field].is_a?(String) && hash[field].strip.empty?)
          raise ValidationError, "#{location} must have a '#{field}'"
        end
      end

      def build_response(data)
        OpenStruct.new(
          qualitative_feedback: sanitize_string(data[:qualitative_feedback]),
          feedback_items: data[:feedback_items].map { |item| build_feedback_item(item) },
          criterion_levels: data[:criterion_levels].map { |level| build_criterion_level(level) },
          checks: data[:checks].map { |check| build_check(check) }
        )
      end

      def build_feedback_item(item)
        OpenStruct.new(
          item_type: item[:item_type],
          title: sanitize_string(item[:title]),
          description: sanitize_string(item[:description]),
          evidence: sanitize_string(item[:evidence])
        )
      end

      def build_criterion_level(level)
        OpenStruct.new(
          criterion_id: level[:criterion_id],
          level_id: level[:level_id],
          explanation: sanitize_string(level[:explanation])
        )
      end

      def build_check(check)
        OpenStruct.new(
          check_type: check[:check_type],
          score: check[:score],
          explanation: sanitize_string(check[:explanation])
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
          student_work_id: @context.student_work&.id,
          assignment_id: @context.student_work&.assignment_id,
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
        when /qualitative_feedback/i
          "missing_qualitative_feedback"
        when /feedback_items.*array/i
          "invalid_feedback_items_type"
        when /item_type.*strength.*opportunity/i
          "invalid_item_type"
        when /criterion_levels.*array/i
          "invalid_criterion_levels_type"
        when /criterion_id.*integer/i
          "invalid_criterion_id_type"
        when /level_id.*integer/i
          "invalid_level_id_type"
        when /checks.*array/i
          "invalid_checks_type"
        when /check_type.*plagiarism.*llm_generated/i
          "invalid_check_type"
        when /score.*number/i
          "invalid_score_type"
        when /score.*between.*0.*100/i
          "score_out_of_range"
        when /must have.*title/i
          "missing_title"
        when /must have.*description/i
          "missing_description"
        when /must have.*evidence/i
          "missing_evidence"
        when /must have.*explanation/i
          "missing_explanation"
        when /must have.*item_type/i
          "missing_item_type"
        when /must have.*check_type/i
          "missing_check_type"
        when /must have.*score/i
          "missing_score"
        else
          "unknown"
        end
      end
    end
  end
end
