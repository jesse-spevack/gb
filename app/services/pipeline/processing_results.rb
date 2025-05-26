module Pipeline
  class ProcessingResults
    include Enumerable

    attr_reader :results

    def initialize(results = [])
      @results = results.freeze
    end

    def each(&block)
      @results.each(&block)
    end

    def successful?
      @results.all?(&:successful?)
    end

    def failed?
      !successful?
    end

    def failed_results
      @results.select(&:failed?)
    end

    def successful_results
      @results.select(&:successful?)
    end

    def error_messages
      @results.flat_map(&:errors).uniq
    end

    def total_timing_ms
      @results.sum(&:timing_ms)
    end

    def total_llm_timing_ms
      @results.sum(&:llm_timing_ms)
    end
  end
end
