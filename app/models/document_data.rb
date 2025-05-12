class DocumentData
  def self.from_json(document_data)
    new(document_data).data
  end

  Datum = Struct.new(:google_doc_id, :title, :url)

  attr_reader :data

  def initialize(document_data)
    @document_data = document_data
    @data = to_data
  end

  def empty?
    data.empty?
  end

  private

  def parsed_document_data
    begin
      JSON.parse(@document_data)
    rescue JSON::ParserError => error
      Rails.logger.error("Failed to parse document data: #{error}")
      []
    end
  end

  def to_data
    parsed_document_data.map do |datum|
      Datum.new(datum["googleDocId"], datum["title"], datum["url"])
    end
  end
end
