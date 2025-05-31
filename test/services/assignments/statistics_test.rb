# frozen_string_literal: true

require "test_helper"

module Assignments
  class StatisticsTest < ActiveSupport::TestCase
    setup do
      @assignment = assignments(:english_essay)
      @statistics = Statistics.new(@assignment)
    end

    test "criterion_performance returns empty hash when no rubric exists" do
      assignment_without_rubric = Assignment.create!(
        user: users(:teacher),
        title: "No Rubric",
        instructions: "Test",
        grade_level: "9",
        feedback_tone: "encouraging"
      )

      statistics = Statistics.new(assignment_without_rubric)
      assert_equal({}, statistics.criterion_performance)
    end

    test "criterion_performance returns stats for all criteria" do
      rubric = Rubric.create!(assignment: @assignment)

      criterion1 = Criterion.create!(
        rubric: rubric,
        title: "Criterion 1",
        description: "Description 1",
        position: 1
      )

      criterion2 = Criterion.create!(
        rubric: rubric,
        title: "Criterion 2",
        description: "Description 2",
        position: 2
      )

      result = @statistics.criterion_performance

      assert_kind_of Hash, result
      assert_equal 2, result.keys.count
      assert_includes result.keys, criterion1
      assert_includes result.keys, criterion2

      # Each value should be a stats hash
      result.values.each do |stats|
        assert_kind_of Hash, stats
        assert stats.key?(:average)
        assert stats.key?(:evaluated_count)
        assert stats.key?(:total_count)
      end
    end

    test "calculates correct average for evaluated student works" do
      assignment = Assignment.create!(
        user: users(:teacher),
        title: "Test Assignment",
        instructions: "Test",
        grade_level: "9",
        feedback_tone: "encouraging"
      )

      rubric = Rubric.create!(assignment: assignment)
      criterion = Criterion.create!(
        rubric: rubric,
        title: "Test Criterion",
        description: "Test",
        position: 1
      )

      # Create levels with different points
      level_high = Level.create!(
        criterion: criterion,
        title: "High",
        description: "High performance",
        position: 1,
        points: 4
      )

      level_low = Level.create!(
        criterion: criterion,
        title: "Low",
        description: "Low performance",
        position: 2,
        points: 2
      )

      # Create student works
      doc1 = SelectedDocument.create!(
        assignment: assignment,
        google_doc_id: "doc1",
        title: "Doc 1",
        url: "https://docs.google.com/doc1"
      )

      doc2 = SelectedDocument.create!(
        assignment: assignment,
        google_doc_id: "doc2",
        title: "Doc 2",
        url: "https://docs.google.com/doc2"
      )

      work1 = StudentWork.create!(
        assignment: assignment,
        selected_document: doc1
      )

      work2 = StudentWork.create!(
        assignment: assignment,
        selected_document: doc2
      )

      # Create evaluations
      StudentCriterionLevel.create!(
        student_work: work1,
        criterion: criterion,
        level: level_high,
        explanation: "Good"
      )

      StudentCriterionLevel.create!(
        student_work: work2,
        criterion: criterion,
        level: level_low,
        explanation: "Needs work"
      )

      statistics = Statistics.new(assignment)
      result = statistics.criterion_performance

      assert_equal 3.0, result[criterion][:average] # (4 + 2) / 2
      assert_equal 2, result[criterion][:evaluated_count]
      assert_equal 2, result[criterion][:total_count]
    end

    test "returns nil average when no evaluations exist" do
      assignment = Assignment.create!(
        user: users(:teacher),
        title: "Test Assignment",
        instructions: "Test",
        grade_level: "9",
        feedback_tone: "encouraging"
      )

      rubric = Rubric.create!(assignment: assignment)
      criterion = Criterion.create!(
        rubric: rubric,
        title: "Test Criterion",
        description: "Test",
        position: 1
      )

      # Create a student work but no evaluations
      doc = SelectedDocument.create!(
        assignment: assignment,
        google_doc_id: "doc1",
        title: "Doc 1",
        url: "https://docs.google.com/doc1"
      )

      StudentWork.create!(
        assignment: assignment,
        selected_document: doc
      )

      statistics = Statistics.new(assignment)
      result = statistics.criterion_performance

      assert_nil result[criterion][:average]
      assert_equal 0, result[criterion][:evaluated_count]
      assert_equal 1, result[criterion][:total_count]
    end

    test "handles partially evaluated assignments correctly" do
      assignment = Assignment.create!(
        user: users(:teacher),
        title: "Test Assignment",
        instructions: "Test",
        grade_level: "9",
        feedback_tone: "encouraging"
      )

      rubric = Rubric.create!(assignment: assignment)
      criterion = Criterion.create!(
        rubric: rubric,
        title: "Test Criterion",
        description: "Test",
        position: 1
      )

      level = Level.create!(
        criterion: criterion,
        title: "Good",
        description: "Good",
        position: 1,
        points: 3
      )

      # Create two student works
      doc1 = SelectedDocument.create!(
        assignment: assignment,
        google_doc_id: "doc1",
        title: "Doc 1",
        url: "https://docs.google.com/doc1"
      )

      doc2 = SelectedDocument.create!(
        assignment: assignment,
        google_doc_id: "doc2",
        title: "Doc 2",
        url: "https://docs.google.com/doc2"
      )

      work1 = StudentWork.create!(
        assignment: assignment,
        selected_document: doc1
      )

      work2 = StudentWork.create!(
        assignment: assignment,
        selected_document: doc2
      )

      # Only evaluate one
      StudentCriterionLevel.create!(
        student_work: work1,
        criterion: criterion,
        level: level,
        explanation: "Good"
      )

      statistics = Statistics.new(assignment)
      result = statistics.criterion_performance

      assert_equal 3.0, result[criterion][:average]
      assert_equal 1, result[criterion][:evaluated_count]
      assert_equal 2, result[criterion][:total_count]
    end
  end
end
