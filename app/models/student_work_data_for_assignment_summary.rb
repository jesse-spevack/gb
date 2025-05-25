class StudentWorkDataForAssignmentSummary
  def initialize(student_work)
    @student_work = student_work
  end

  def qualitative_feedback
    @student_work.qualitative_feedback
  end

  def has_feedback?
    qualitative_feedback.present?
  end

  def criterion_levels
    @criterion_levels ||= build_criterion_levels
  end

  def has_criterion_levels?
    criterion_levels.any?
  end

  private

  def build_criterion_levels
    return [] unless @student_work.student_criterion_levels.respond_to?(:includes)

    @student_work.student_criterion_levels
      .includes(:criterion, :level)
      .map { |scl| CriterionLevelData.new(scl) }
      .sort_by(&:criterion_title)
  end
end
