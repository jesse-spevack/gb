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

  test "valid with all required attributes" do
    level = Level.new(criterion: criteria(:writing_quality), title: "Level 1", description: "Description", position: 1)
    assert level.valid?
  end

  test "order levels by position" do
    level1 = Level.create(criterion: criteria(:grammar_mechanics), title: "Level 1", description: "Description", position: 1)
    level2 = Level.create(criterion: criteria(:grammar_mechanics), title: "Level 2", description: "Description", position: 2)

    expected = [ level1, level2 ].map(&:id)
    actual = Level.where(criterion: criteria(:grammar_mechanics)).map(&:id)

    assert_equal expected, actual
  end
end
