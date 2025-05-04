require "test_helper"

class CriterionTest < ActiveSupport::TestCase
  test "is not valid without rubric" do
    criterion = Criterion.new(title: "test_title", description: "test_description", position: 1)
    assert_not criterion.valid?
  end

  test "is not valid without title" do
    criterion = Criterion.new(rubric: rubrics(:english_essay_rubric), description: "test_description", position: 1)
    assert_not criterion.valid?
  end

  test "is not valid without description" do
    criterion = Criterion.new(rubric: rubrics(:english_essay_rubric), title: "test_title", position: 1)
    assert_not criterion.valid?
  end

  test "is not valid without position" do
    criterion = Criterion.new(rubric: rubrics(:english_essay_rubric), title: "test_title", description: "test_description")
    assert_not criterion.valid?
  end

  test "is valid with all required attributes" do
    criterion = Criterion.new(rubric: rubrics(:english_essay_rubric), title: "test_title", description: "test_description", position: 1)
    assert criterion.valid?
  end

  test "order criteria by position" do
    expected = [ criteria(:historical_accuracy), criteria(:source_quality), criteria(:argument_development), criteria(:contextualization) ].map(&:id)
    actual = Criterion.where(rubric: rubrics(:history_essay_rubric)).map(&:id)

    assert_equal expected, actual
  end
end
