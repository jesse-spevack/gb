require "test_helper"

module Assignments
  class ProgressCalculatorTest < ActiveSupport::TestCase
    setup do
      @assignment = assignments(:english_essay)
    end

    test "calculates zero progress for new assignment" do
      # Create a test double for the progress calculator with controlled return values
      calculator = ProgressCalculator.new(@assignment)

      # Override the methods to simulate a new assignment with no progress
      def calculator.rubric_complete?; false; end
      def calculator.completed_student_works_count; 0; end
      def calculator.total_student_works_count; 0; end
      def calculator.summary_complete?; false; end

      progress = calculator.calculate

      assert_equal 0, progress[:overall_percentage]
      assert_equal 0, progress[:completed_llm_calls]
      assert_equal 2, progress[:total_llm_calls] # 1 rubric + 0 students + 1 summary
      assert_equal false, progress[:rubric_complete]
      assert_equal 0, progress[:student_works_complete]
      assert_equal false, progress[:summary_complete]
    end

    test "calculates progress with completed rubric" do
      # Create a test double for progress calculator with completed rubric
      calculator = ProgressCalculator.new(@assignment)

      # Override methods to simulate assignment with completed rubric only
      def calculator.rubric_complete?; true; end
      def calculator.completed_student_works_count; 0; end
      def calculator.total_student_works_count; 0; end
      def calculator.summary_complete?; false; end

      progress = calculator.calculate

      assert_equal 50, progress[:overall_percentage] # 1/2 = 50%
      assert_equal 1, progress[:completed_llm_calls]
      assert_equal true, progress[:rubric_complete]
      assert_equal :completed, progress[:phases][:rubric][:status]
      assert_equal :pending, progress[:phases][:summary][:status]
    end

    test "calculates progress with some student work completed" do
      # Create a test double for progress calculator with some student works complete
      calculator = ProgressCalculator.new(@assignment)

      # Override methods to simulate assignment with rubric and some student works complete
      def calculator.rubric_complete?; true; end
      def calculator.completed_student_works_count; 2; end
      def calculator.total_student_works_count; 3; end
      def calculator.summary_complete?; false; end

      progress = calculator.calculate

      assert_equal 60, progress[:overall_percentage] # 3/5 = 60%
      assert_equal 3, progress[:completed_llm_calls] # 1 rubric + 2 student works
      assert_equal 5, progress[:total_llm_calls] # 1 rubric + 3 student works + 1 summary
      assert_equal 2, progress[:student_works_complete]
      assert_equal 3, progress[:student_works_total]
      assert_equal :in_progress, progress[:phases][:student_works][:status]
    end

    test "calculates 100% when all phases complete" do
      # Create a test double for progress calculator with all phases complete
      calculator = ProgressCalculator.new(@assignment)

      # Override methods to simulate fully completed assignment
      def calculator.rubric_complete?; true; end
      def calculator.completed_student_works_count; 2; end
      def calculator.total_student_works_count; 2; end
      def calculator.summary_complete?; true; end

      progress = calculator.calculate

      assert_equal 100, progress[:overall_percentage]
      assert_equal 4, progress[:completed_llm_calls] # 1 + 2 + 1
      assert_equal 4, progress[:total_llm_calls] # 1 + 2 + 1
      assert_equal true, progress[:rubric_complete]
      assert_equal 2, progress[:student_works_complete]
      assert_equal true, progress[:summary_complete]
      assert_equal :completed, progress[:phases][:student_works][:status]
      assert_equal :completed, progress[:phases][:summary][:status]
    end

    test "handles assignment with no student works" do
      # Create a test double for progress calculator with no student works
      calculator = ProgressCalculator.new(@assignment)

      # Override methods to simulate assignment with no student works
      def calculator.rubric_complete?; false; end
      def calculator.completed_student_works_count; 0; end
      def calculator.total_student_works_count; 0; end
      def calculator.summary_complete?; false; end

      progress = calculator.calculate

      assert_equal 0, progress[:overall_percentage]
      assert_equal 2, progress[:total_llm_calls] # Just rubric + summary
      assert_equal 0, progress[:student_works_total]
    end

    test "includes detailed phase information" do
      # Create a test double for progress calculator with pending status
      calculator = ProgressCalculator.new(@assignment)

      # Override methods to simulate new assignment with pending status
      def calculator.rubric_complete?; false; end
      def calculator.completed_student_works_count; 0; end
      def calculator.total_student_works_count; 0; end
      def calculator.summary_complete?; false; end

      # Also override the private methods that determine the status
      def calculator.rubric_status; :pending; end
      def calculator.student_works_status; :pending; end
      def calculator.summary_status; :pending; end

      progress = calculator.calculate

      assert progress.key?(:phases)
      assert_equal :pending, progress[:phases][:rubric][:status]
      assert_equal :pending, progress[:phases][:student_works][:status]
      assert_equal :pending, progress[:phases][:summary][:status]
    end
  end
end
