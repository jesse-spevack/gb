class ProcessingPipeline
  attr_reader :task

  def initialize(task)
    @task = task
  end

  def execute
    Rails.logger.info("Starting processing pipeline for #{@task.process_type} on #{@task.processable.class.name}")

    @task.mark_started
    update_status(:processing)
    broadcast_update(:processing)

    begin
      processed_data = process_steps
      finalize_success(processed_data)
      ProcessingResult.new(success: true, data: processed_data)
    rescue => e
      finalize_error(e)
      ProcessingResult.new(success: false, error_message: e.message)
    end
  end

  private

  def process_steps
    data = collect_data
    prompt = @task.prompt_template.build(@task.process_type, data)
    response = send_to_llm(prompt)
    parsed_result = @task.response_parser.parse(response.text)
    @task.storage_service.store(@task.processable, parsed_result)
    parsed_result
  end

  def collect_data
    DataCollectionService.collect(@task.processable, @task.process_type, @task.user)
  end

  def send_to_llm(prompt)
    # Mock LLM client call for now
    LLMResponse.new(
      text: "Mock LLM response for #{@task.process_type}",
      input_tokens: 100,
      output_tokens: 50,
      model: "gpt-4"
    )
  end

  def finalize_success(data)
    @task.mark_completed
    @task.record_metric(:status, "completed")
    @task.record_metric(:processing_time_ms, @task.processing_time_ms)
    update_status(:completed)
    broadcast_update(:completed, data)
  end

  def finalize_error(error)
    Rails.logger.error("Processing pipeline failed: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))

    @task.error_message = error.message
    @task.record_metric(:status, "failed")
    @task.mark_completed
    update_status(:failed)
    broadcast_update(:failed)
  end

  def update_status(status)
    @task.status_manager.update_status(@task.processable, status)
  end

  def broadcast_update(status, data = nil)
    @task.broadcaster.broadcast(@task.processable, status, data)
  end
end
