require "test_helper"

class Pipeline::Context::StudentWorkTest < ActiveSupport::TestCase
  test "it has the expected attributes" do
    student_work = Pipeline::Context::StudentWork.new
    assert_equal({}, student_work.metrics)
    assert_nil student_work.llm_response
    assert_nil student_work.prompt
    assert_nil student_work.rubric
    assert_nil student_work.selected_document
    assert_nil student_work.student_work
  end

  test "it can add metrics" do
    student_work = Pipeline::Context::StudentWork.new
    student_work.add_metric("test", 1)
    assert_equal({ "test" => 1 }, student_work.metrics)
  end

  test "it can set values" do
    student_work = Pipeline::Context::StudentWork.new
    student_work.llm_response = "test"
    assert_equal("test", student_work.llm_response)
    student_work.prompt = "test"
    assert_equal("test", student_work.prompt)
    student_work.rubric = "test"
    assert_equal("test", student_work.rubric)
    student_work.selected_document = "test"
    assert_equal("test", student_work.selected_document)
    student_work.student_work = "test"
    assert_equal("test", student_work.student_work)
  end
end
