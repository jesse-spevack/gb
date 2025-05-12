class SelectedDocument::BulkCreationService
  def self.create(assignment:, document_data:)
    new(assignment: assignment, document_data: document_data).create
  end

  def initialize(assignment:, document_data:)
    @assignment = assignment
    @document_data = document_data
  end

  def create
    return [] if @document_data.empty?

    SelectedDocument.insert_all!(raw_records)

    SelectedDocument.where(assignment: @assignment)
  end

  def raw_records
    @document_data.map do |datum|
      {
        assignment_id: @assignment.id,
        google_doc_id: datum.google_doc_id,
        title: datum.title,
        url: datum.url
      }
    end
  end
end
