require "test_helper"

class LevelTest < ActiveSupport::TestCase
  test "not valid without a criterion" do
    level = Level.new(title: "Level 1", description: "Description", performance_level: :meets, points: 3)
    assert_not level.valid?
  end

  test "not valid without a title" do
    level = Level.new(criterion: criteria(:writing_quality), description: "Description", performance_level: :meets, points: 3)
    assert_not level.valid?
  end

  test "not valid without a description" do
    level = Level.new(criterion: criteria(:writing_quality), title: "Level 1", performance_level: :meets, points: 3)
    assert_not level.valid?
  end

  test "not valid without a performance_level" do
    level = Level.new(criterion: criteria(:writing_quality), title: "Level 1", description: "Description", points: 3)
    assert_not level.valid?
  end

  test "not valid without points" do
    level = Level.new(criterion: criteria(:writing_quality), title: "Level 1", description: "Description", performance_level: :meets)
    assert_not level.valid?
  end

  test "valid with all required attributes" do
    level = Level.new(criterion: criteria(:grammar_mechanics), title: "Level 1", description: "Description", performance_level: :meets, points: 3)
    assert level.valid?
  end

  test "points must be an integer between 1 and 4" do
    level = Level.new(criterion: criteria(:grammar_mechanics), title: "Level 1", description: "Description", performance_level: :meets)

    # Test invalid values
    level.points = -1
    assert_not level.valid?
    assert_includes level.errors[:points], "must be in 1..4"

    level.points = 5
    assert_not level.valid?
    assert_includes level.errors[:points], "must be in 1..4"

    level.points = 2.5
    assert_not level.valid?
    assert_includes level.errors[:points], "must be an integer"

    # Test valid values with matching performance levels
    test_cases = [
      { points: 4, performance_level: :exceeds },
      { points: 3, performance_level: :meets },
      { points: 2, performance_level: :approaching },
      { points: 1, performance_level: :below }
    ]

    test_cases.each do |test_case|
      level.points = test_case[:points]
      level.performance_level = test_case[:performance_level]
      assert level.valid?, "Level should be valid with points = #{test_case[:points]} and performance_level = #{test_case[:performance_level]}"
    end
  end

  test "points must be unique within criterion" do
    criterion = criteria(:writing_quality)
    # Create a level with a point value that already exists in the criterion
    existing_level = levels(:writing_exemplary) # This should have points: 4

    duplicate_level = Level.new(criterion: criterion, title: "New Level", description: "Description", performance_level: :exceeds, points: existing_level.points)
    assert_not duplicate_level.valid?
    assert_includes duplicate_level.errors[:points], "must be unique within criterion"
  end

  test "points can be the same across different criteria" do
    criterion1 = criteria(:writing_quality)
    criterion2 = criteria(:grammar_mechanics)

    # Use a point value that already exists in criterion1 fixtures (points: 3)
    level2 = Level.new(criterion: criterion2, title: "Level 2", description: "Description", performance_level: :meets, points: 3)

    assert level2.valid?
  end

  test "order levels by performance_level" do
    # Create levels with different performance levels
    criterion = Criterion.create!(rubric: rubrics(:english_essay_rubric), title: "Test", description: "Test", position: 1)
    level1 = Level.create!(criterion: criterion, title: "Exceeds", description: "Description", performance_level: :exceeds, points: 4)
    level2 = Level.create!(criterion: criterion, title: "Meets", description: "Description", performance_level: :meets, points: 3)
    level3 = Level.create!(criterion: criterion, title: "Below", description: "Description", performance_level: :below, points: 1)

    expected = [ level1, level2, level3 ].map(&:id)
    actual = Level.where(criterion: criterion).map(&:id)

    assert_equal expected, actual
  end

  test "points must match performance level" do
    level = Level.new(criterion: criteria(:grammar_mechanics), title: "Test", description: "Description", performance_level: :exceeds)

    # Wrong points for exceeds (should be 4)
    level.points = 2
    assert_not level.valid?
    assert_includes level.errors[:points], "must be 4 for exceeds performance level"

    # Correct points
    level.points = 4
    assert level.valid?
  end
end
