require "test_helper"

class StudentWorkTest < ActiveSupport::TestCase
  test "is not valid without an assignment" do
    student_work = StudentWork.new(assignment: nil, selected_document: selected_documents(:one))
    assert_not student_work.valid?
  end

  test "is not valid without a selected document" do
    student_work = StudentWork.new(selected_document: nil, assignment: assignments(:english_essay))
    assert_not student_work.valid?
  end

  test "high_level_feedback_average returns actual average of performance levels" do
    student_work = student_works(:student_essay_one)

    # Clear existing student_criterion_levels to have a clean test
    student_work.student_criterion_levels.destroy_all

    # Create criterion levels to test averaging
    # Meets (3 points) x 2 = 6 points
    student_work.student_criterion_levels.create!(
      criterion: criteria(:writing_quality),
      level: levels(:writing_proficient),
      explanation: "Test explanation 1"
    )

    student_work.student_criterion_levels.create!(
      criterion: criteria(:content_depth),
      level: levels(:content_proficient),
      explanation: "Test explanation 2"
    )

    # Approaching (2 points) x 1 = 2 points
    student_work.student_criterion_levels.create!(
      criterion: criteria(:writing_quality),
      level: levels(:writing_developing),
      explanation: "Test explanation 3"
    )

    # Total: 8 points / 3 levels = 2.67, rounds to 3 = "Meets"
    result = student_work.high_level_feedback_average
    assert_equal "Meets", result
  end

  test "average_performance_points returns numeric average" do
    student_work = student_works(:student_essay_one)

    # Clear existing student_criterion_levels
    student_work.student_criterion_levels.destroy_all

    # Create levels with known point values
    # Meets (3 points) and Approaching (2 points)
    student_work.student_criterion_levels.create!(
      criterion: criteria(:writing_quality),
      level: levels(:writing_proficient),
      explanation: "Test explanation 1"
    )

    student_work.student_criterion_levels.create!(
      criterion: criteria(:content_depth),
      level: levels(:content_developing),
      explanation: "Test explanation 2"
    )

    # Should return 2.5 (3 + 2) / 2
    result = student_work.average_performance_points
    assert_equal 2.5, result
  end

  test "average_performance_points returns nil when no criterion levels exist" do
    student_work = student_works(:student_essay_one)
    student_work.student_criterion_levels.destroy_all

    result = student_work.average_performance_points
    assert_nil result
  end

  test "high_level_feedback_average returns nil when no criterion levels exist" do
    student_work = student_works(:student_essay_one)
    student_work.student_criterion_levels.destroy_all

    result = student_work.high_level_feedback_average
    assert_nil result
  end

  test "high_level_feedback_average handles edge cases for rounding" do
    student_work = student_works(:student_essay_one)
    student_work.student_criterion_levels.destroy_all

    # Create a test assignment and rubric
    assignment = Assignment.create!(
      user: users(:teacher),
      title: "Test Assignment",
      instructions: "Test",
      grade_level: "9",
      feedback_tone: "encouraging"
    )

    rubric = Rubric.create!(assignment: assignment)

    # Test exact boundary cases
    test_cases = [
      { points: [ 4 ], expected: "Exceeds" },
      { points: [ 3 ], expected: "Meets" },
      { points: [ 2 ], expected: "Approaching" },
      { points: [ 1 ], expected: "Below" },
      { points: [ 1, 2 ], expected: "Approaching" }, # 3/2 = 1.5, rounds to 2
      { points: [ 2, 3 ], expected: "Meets" },    # 5/2 = 2.5, rounds to 3
      { points: [ 3, 4 ], expected: "Exceeds" }   # 7/2 = 3.5, rounds to 4
    ]

    test_cases.each_with_index do |test_case, index|
      # Clear previous levels and create new criterion for each test
      student_work.student_criterion_levels.destroy_all

      criterion = Criterion.create!(
        rubric: rubric,
        title: "Test Criterion #{index}",
        description: "Test",
        position: index + 1
      )

      # Create levels for this test case
      test_case[:points].each_with_index do |point_value, level_index|
        performance_level = case point_value
        when 4 then :exceeds
        when 3 then :meets
        when 2 then :approaching
        when 1 then :below
        else :meets # fallback
        end

        level = Level.create!(
          criterion: criterion,
          title: "Level #{index}-#{level_index}",
          description: "Test level",
          performance_level: performance_level,
          points: point_value.to_i
        )

        student_work.student_criterion_levels.create!(
          criterion: criterion,
          level: level,
          explanation: "Test explanation #{index}-#{level_index}"
        )
      end

      result = student_work.high_level_feedback_average
      assert_equal test_case[:expected], result,
        "Expected #{test_case[:expected]} for points #{test_case[:points]}, got #{result}"
    end
  end

  test "high_level_feedback_average handles out-of-range averages gracefully" do
    student_work = student_works(:student_essay_one)

    # Mock the average_performance_points method to return values
    student_work.stubs(:average_performance_points).returns(0.5) # Rounds to 1
    assert_equal "Below", student_work.high_level_feedback_average

    student_work.stubs(:average_performance_points).returns(5.0) # Rounds to 5, default case
    assert_equal "Meets", student_work.high_level_feedback_average

    student_work.unstub(:average_performance_points)
  end

  test "high_level_feedback_average returns Meets as default for unexpected values" do
    student_work = student_works(:student_essay_one)

    # Mock to return a non-standard rounded value
    student_work.stubs(:average_performance_points).returns(2.7)
    # 2.7 rounds to 3, which should be "Meets"
    assert_equal "Meets", student_work.high_level_feedback_average

    student_work.unstub(:average_performance_points)
  end
end
