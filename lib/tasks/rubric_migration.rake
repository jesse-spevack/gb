# frozen_string_literal: true

namespace :rubrics do
  desc "Migrate existing rubrics to use standardized performance levels"
  task migrate_to_performance_levels: :environment do
    puts "Starting rubric migration to standardized performance levels..."

    migrated_count = 0
    error_count = 0

    Level.unscoped.find_each do |level|
      begin
        # Map existing level names to performance levels
        performance_level = map_title_to_performance_level(level.title)

        # Calculate points based on position (inverse relationship)
        # Position 1 = 4 points (Exceeds), Position 4 = 1 point (Below)
        points = 5 - level.position

        # Update the level
        level.update!(
          performance_level: performance_level,
          points: points,
          title: standardized_title(performance_level)
        )

        migrated_count += 1
        print "."
      rescue => e
        error_count += 1
        puts "\nError migrating level #{level.id} (#{level.title}): #{e.message}"
      end
    end

    puts "\n\nMigration complete!"
    puts "Migrated: #{migrated_count} levels"
    puts "Errors: #{error_count} levels"
  end

  private

  def map_title_to_performance_level(title)
    case title.downcase
    when /excee|excell|outstand|master|superior/
      :exceeds
    when /meet|good|proficient|satisfactory|competent/
      :meets
    when /approach|average|develop|progress|improve/
      :approaching
    when /below|poor|inadequate|unsatisfactory|needs improvement/
      :below
    else
      # Default mapping based on common patterns
      puts "\nWarning: Unmapped title '#{title}', defaulting to :meets"
      :meets
    end
  end

  def standardized_title(performance_level)
    case performance_level
    when :exceeds
      "Exceeds"
    when :meets
      "Meets"
    when :approaching
      "Approaching"
    when :below
      "Below"
    end
  end
end
