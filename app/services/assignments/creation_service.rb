class Assignments::CreationService
  Result = Struct.new(:success, :assignment, :error_message, keyword_init: true) do
    def success?
      success
    end
  end

  def self.create(assignment_input)
    new(assignment_input).create
  end

  def initialize(assignment_input)
    @assignment_input = assignment_input
  end

  def create
    assignment = nil

    begin
      ActiveRecord::Base.transaction do
        assignment = Assignment.create!(@assignment_input.params)

        selected_documents = SelectedDocument::BulkCreationService.create(
          assignment: assignment,
          document_data: @assignment_input.document_data
        )

        StudentWork::BulkCreationService.create(
          assignment: assignment,
          selected_documents: selected_documents
        )

        Rubric::CreationService.create(assignment: assignment)
      end

      AssignmentJob.perform_later(assignment.id)

      Result.new(success: true, assignment: assignment, error_message: nil)
    rescue StandardError => e
      Result.new(success: false, assignment: nil, error_message: e.message)
    end
  end
end
