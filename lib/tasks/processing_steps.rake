namespace :processing_steps do
  desc "Add processing steps to existing assignments that don't have them"
  task backfill: :environment do
    assignments_without_steps = Assignment.left_joins(:processing_steps)
                                         .where(processing_steps: { id: nil })
                                         .distinct

    total = assignments_without_steps.count

    if total == 0
      puts "All assignments already have processing steps!"
      next
    end

    puts "Found #{total} assignments without processing steps"

    assignments_without_steps.find_each.with_index do |assignment, index|
      ProcessingStep::CreationService.create(assignment: assignment)

      # Mark all steps as completed for existing assignments
      assignment.processing_steps.update_all(
        status: "completed",
        started_at: assignment.created_at,
        completed_at: assignment.updated_at
      )

      print "\rProcessed #{index + 1}/#{total} assignments"
    end

    puts "\nCompleted! All assignments now have processing steps."
  end
end
