# frozen_string_literal: true

require "ostruct"

module LLM
  module AssignmentSummary
    # Parser for LLM-generated assignment summary responses
    class ResponseParser
      class ValidationError < StandardError; end

      def self.call(context:)
        new(context).call
      end

      def initialize(context)
        @context = context
      end

      def call
        Rails.logger.info("Parsing summary response for assignment: #{@context.assignment.id}")

        parsed_json = parse_json
        validate_structure(parsed_json)

        @context.parsed_response = build_response(parsed_json)
        @context
      rescue JSON::ParserError => e
        log_error("JSON parsing failed", e, {
          assignment_id: @context.assignment.id,
          error_location: identify_json_error_location(e.message)
        })
        raise JSON::ParserError, "Failed to parse assignment summary response as valid JSON. #{e.message}"
      rescue ValidationError => e
        log_error("Assignment summary validation failed", e, {
          assignment_id: @context.assignment.id,
          validation_type: extract_validation_type(e.message),
          student_feedback_count: @context.student_feedbacks&.size
        })
        raise
      rescue StandardError => e
        log_error("Unexpected error during assignment summary parsing", e, {
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
        validate_qualitative_insights(data)
        validate_feedback_items(data)
        validate_feedback_balance(data[:feedback_items])
      end

      def validate_qualitative_insights(data)
        unless data.key?(:qualitative_insights) && !data[:qualitative_insights].nil?
          raise ValidationError, "Response must contain 'qualitative_insights'"
        end

        unless data[:qualitative_insights].is_a?(String)
          raise ValidationError, "qualitative_insights must be a string"
        end
      end

      def validate_feedback_items(data)
        unless data.key?(:feedback_items)
          raise ValidationError, "Response must contain 'feedback_items' array"
        end

        unless data[:feedback_items].is_a?(Array)
          raise ValidationError, "feedback_items must be an array"
        end

        if data[:feedback_items].size < 2
          raise ValidationError, "Assignment summary must have at least 2 feedback items"
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

      def validate_feedback_balance(feedback_items)
        strengths = feedback_items.count { |item| item[:item_type] == "strength" }
        opportunities = feedback_items.count { |item| item[:item_type] == "opportunity" }

        if strengths == 0
          raise ValidationError, "Assignment summary must have at least one strength"
        end

        if opportunities == 0
          raise ValidationError, "Assignment summary must have at least one opportunity"
        end
      end

      def validate_required_field(hash, field, location)
        if !hash.key?(field) || hash[field].nil? || (hash[field].is_a?(String) && hash[field].strip.empty?)
          raise ValidationError, "#{location} must have a '#{field}'"
        end
      end

      def build_response(data)
        OpenStruct.new(
          qualitative_insights: sanitize_string(data[:qualitative_insights]),
          feedback_items: data[:feedback_items].map { |item| build_feedback_item(item) }
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
        when /qualitative_insights/i
          "missing_qualitative_insights"
        when /feedback_items.*array/i
          "invalid_feedback_items_type"
        when /at least 2 feedback items/i
          "insufficient_feedback_items"
        when /at least one strength/i
          "missing_strength_feedback"
        when /at least one opportunity/i
          "missing_opportunity_feedback"
        when /item_type.*strength.*opportunity/i
          "invalid_item_type"
        when /must have.*title/i
          "missing_title"
        when /must have.*description/i
          "missing_description"
        when /must have.*evidence/i
          "missing_evidence"
        when /must have.*item_type/i
          "missing_item_type"
        else
          "unknown"
        end
      end
    end
  end
end
