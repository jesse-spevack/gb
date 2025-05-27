# frozen_string_literal: true

# Service for preconfigured broadcasting based on pipeline events
# Converts events to statuses and delegates to BroadcastService
class ConfiguredBroadcastService
  def initialize(event:)
    @event = event
  end

  def call(context:)
    context.status = map_event_to_status(@event)
    BroadcastService.call(context: context)
  end

  private

  def map_event_to_status(event)
    case event
    when :rubric_started, :student_work_started, :summary_started
      :in_progress
    when :rubric_completed, :student_work_completed, :summary_completed
      :completed
    when :rubric_failed, :student_work_failed, :summary_failed
      :failed
    else
      :pending
    end
  end
end
