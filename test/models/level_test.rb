require "test_helper"

class LevelTest < ActiveSupport::TestCase
  test "not valid without a criterion" do
    level = Level.new(title: "Level 1", description: "Description", position: 1)
    assert_not level.valid?
  end

  test "not valid without a title" do
    level = Level.new(criterion: criteria(:writing_quality), description: "Description", position: 1)
    assert_not level.valid?
  end

  test "not valid without a description" do
    level = Level.new(criterion: criteria(:writing_quality), title: "Level 1", position: 1)
    assert_not level.valid?
  end

  test "not valid without a position" do
    level = Level.new(criterion: criteria(:writing_quality), title: "Level 1", description: "Description")
    assert_not level.valid?
  end

  test "not valid without points" do
    level = Level.new(criterion: criteria(:writing_quality), title: "Level 1", description: "Description", position: 1)
    assert_not level.valid?
  end

  test "valid with all required attributes" do
    level = Level.new(criterion: criteria(:grammar_mechanics), title: "Level 1", description: "Description", position: 1, points: 3)
    assert level.valid?
  end

  test "points must be an integer between 0 and 4" do
    level = Level.new(criterion: criteria(:grammar_mechanics), title: "Level 1", description: "Description", position: 1)

    # Test invalid values
    level.points = -1
    assert_not level.valid?
    assert_includes level.errors[:points], "must be in 0..4"

    level.points = 5
    assert_not level.valid?
    assert_includes level.errors[:points], "must be in 0..4"

    level.points = 2.5
    assert_not level.valid?
    assert_includes level.errors[:points], "must be an integer"

    # Test valid values
    (0..4).each do |valid_points|
      level.points = valid_points
      assert level.valid?, "Level should be valid with points = #{valid_points}"
    end
  end

  test "points must be unique within criterion" do
    criterion = criteria(:writing_quality)
    # Using points: 0 since fixtures use 1-4
    Level.create!(criterion: criterion, title: "Existing Level", description: "Description", position: 5, points: 0)

    duplicate_level = Level.new(criterion: criterion, title: "New Level", description: "Description", position: 6, points: 0)
    assert_not duplicate_level.valid?
    assert_includes duplicate_level.errors[:points], "must be unique within criterion"
  end

  test "points can be the same across different criteria" do
    criterion1 = criteria(:writing_quality)
    criterion2 = criteria(:grammar_mechanics)

    # Use a point value that already exists in criterion1 fixtures (points: 3)
    level2 = Level.new(criterion: criterion2, title: "Level 2", description: "Description", position: 1, points: 3)

    assert level2.valid?
  end

  test "order levels by position" do
    level1 = Level.create(criterion: criteria(:grammar_mechanics), title: "Level 1", description: "Description", position: 1, points: 4)
    level2 = Level.create(criterion: criteria(:grammar_mechanics), title: "Level 2", description: "Description", position: 2, points: 3)

    expected = [ level2, level1 ].map(&:id)
    actual = Level.where(criterion: criteria(:grammar_mechanics)).order(position: :desc).map(&:id)

    assert_equal expected, actual
  end
end
