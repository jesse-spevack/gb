require "test_helper"

class Pipeline::Context::RubricTest < ActiveSupport::TestCase
  test "it has the expected attributes" do
    rubric = Pipeline::Context::Rubric.new
    assert_equal({}, rubric.metrics)
    assert_nil rubric.llm_response
    assert_nil rubric.prompt
    assert_nil rubric.rubric
    assert_nil rubric.user
  end

  test "it can add metrics" do
    rubric = Pipeline::Context::Rubric.new
    rubric.add_metric("test", 1)
    assert_equal({ "test" => 1 }, rubric.metrics)
  end

  test "it can set values" do
    rubric = Pipeline::Context::Rubric.new
    rubric.llm_response = "test"
    assert_equal("test", rubric.llm_response)
    rubric.prompt = "test"
    assert_equal("test", rubric.prompt)
    rubric.rubric = "test"
    assert_equal("test", rubric.rubric)
    rubric.user = "test"
    assert_equal("test", rubric.user)
  end
end
