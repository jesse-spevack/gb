module Pipeline
  class ProcessingResult
    attr_reader :success, :data, :errors, :metrics

    def initialize(success:, data: nil, errors: [], metrics: {})
      @success = success
      @data = data
      @errors = errors
      @metrics = metrics.freeze
    end

    def successful?
      @success
    end

    def failed?
      !successful?
    end

    def timing_ms
      metrics["total_duration_ms"].to_i
    end

    def llm_timing_ms
      metrics["llm_request_ms"].to_i
    end
  end
end
