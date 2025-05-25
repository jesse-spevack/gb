class CriterionLevelData
  def initialize(student_criterion_level)
    @student_criterion_level = student_criterion_level
  end

  def criterion_title
    @student_criterion_level.criterion.title
  end

  def level_title
    @student_criterion_level.level.title
  end

  def explanation
    @student_criterion_level.explanation
  end
end
