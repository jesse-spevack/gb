class ProcessingTaskConfiguration
  attr_reader :response_parser, :storage_service, :broadcaster, :status_manager

  def initialize(response_parser:, storage_service:, broadcaster:, status_manager:)
    @response_parser = response_parser
    @storage_service = storage_service
    @broadcaster = broadcaster
    @status_manager = status_manager

    validate!
  end

  private

  def validate!
    # TODO we need to validate that these are all valid classes as we implement them.
    raise ArgumentError, "Response parser is required" if response_parser.nil?
    raise ArgumentError, "Storage service is required" if storage_service.nil?
    raise ArgumentError, "Broadcaster is required" if broadcaster.nil?
    raise ArgumentError, "Status manager is required" if status_manager.nil?
  end
end
