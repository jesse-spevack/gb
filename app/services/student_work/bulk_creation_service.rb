class StudentWork::BulkCreationService
  def self.create(assignment:, selected_documents:)
    new(assignment: assignment, selected_documents: selected_documents).create
  end

  def initialize(assignment:, selected_documents:)
    @assignment = assignment
    @selected_documents = selected_documents
  end

  def create
    return [] if @selected_documents.empty?

    records_to_insert = @selected_documents.map do |document|
      {
        assignment_id: @assignment.id,
        selected_document_id: document.id
      }
    end

    StudentWork.insert_all!(records_to_insert)
  end
end
