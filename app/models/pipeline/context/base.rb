# frozen_string_literal: true

module Pipeline::Context
  class Base
    attr_reader :metrics
    attr_accessor :llm_response,
                  :parsed_response,
                  :prompt,
                  :user

    def initialize
      @metrics = {}
      @started_at = Time.current
    end

    def record_timing(operation)
      start = Time.current
      result = yield
      duration_ms = ((Time.current - start) * 1000).to_i
      add_metric("#{operation}_ms", duration_ms)
      result
    end

    def total_duration_ms
      ((Time.current - @started_at) * 1000).to_i
    end

    def add_metric(key, value)
      metrics[key] = value
    end
  end
end
