require "test_helper"

class PromptBuilderTest < ActiveSupport::TestCase
  test "build_for - rubric generation" do
    task = mock("task")
    input = mock("input")
    assignment = assignments(:english_essay)
    task.stubs(:process_type).returns(:generate_rubric)
    task.stubs(:processable).returns(assignment)

    PromptInput::Rubric.expects(:from).with(assignment: assignment).returns(input)
    PromptTemplate.expects(:build).with(template: "rubric_generation.txt.erb", input: input)

    PromptBuilder.build_for(task)
  end

  test "build_for - student work" do
    task = mock("task")
    input = mock("input")
    student_work = student_works(:student_essay_one)
    task.stubs(:process_type).returns(:generate_student_work_feedback)
    task.stubs(:processable).returns(student_work)

    PromptInput::StudentWorkFeedback.expects(:from).with(student_work: student_work).returns(input)
    PromptTemplate.expects(:build).with(template: "student_feedback.txt.erb", input: input)

    PromptBuilder.build_for(task)
  end

  test "build_for - assignment summary feedback" do
    task = mock("task")
    input = mock("input")
    assignment = assignments(:english_essay)
    task.stubs(:process_type).returns(:generate_assignment_summary_feedback)
    task.stubs(:processable).returns(assignment)

    PromptInput::AssignmentSummary.expects(:from).with(assignment: assignment).returns(input)
    PromptTemplate.expects(:build).with(template: "assignment_summary.txt.erb", input: input)

    PromptBuilder.build_for(task)
  end
end
