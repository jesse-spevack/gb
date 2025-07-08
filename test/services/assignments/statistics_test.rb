# frozen_string_literal: true

require "test_helper"

module Assignments
  class StatisticsTest < ActiveSupport::TestCase
    setup do
      @assignment = assignments(:english_essay)
      @statistics = Statistics.new(@assignment)
    end

    test "get_criterion_performance returns stats collection" do
      result = Statistics.get_criterion_performance(@assignment)
      assert_instance_of Statistics::StatsCollection, result
    end

    test "criterion_performance returns empty stats collection when no rubric exists" do
      assignment_without_rubric = Assignment.create!(
        user: users(:teacher),
        title: "No Rubric",
        instructions: "Test",
        grade_level: "9",
        feedback_tone: "encouraging"
      )

      statistics = Statistics.new(assignment_without_rubric)
      result = statistics.criterion_performance
      assert_instance_of Statistics::StatsCollection, result
      assert result.empty?
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

      assert_instance_of Statistics::StatsCollection, result

      # Check we can get stats for each criterion
      stats1 = result.for(criterion1)
      stats2 = result.for(criterion2)

      assert_not_nil stats1
      assert_not_nil stats2

      # Each stats should be a CriterionStats struct
      [ stats1, stats2 ].each do |stats|
        assert_instance_of Statistics::CriterionStats, stats
        assert_respond_to stats, :average
        assert_respond_to stats, :evaluated_count
        assert_respond_to stats, :total_count
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
        title: "Exceeds",
        description: "High performance",
        performance_level: :exceeds,
        points: 4
      )

      level_low = Level.create!(
        criterion: criterion,
        title: "Approaching",
        description: "Low performance",
        performance_level: :approaching,
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
      stats = result.for(criterion)

      assert_equal 3.0, stats.average # (4 + 2) / 2
      assert_equal 2, stats.evaluated_count
      assert_equal 2, stats.total_count
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
      stats = result.for(criterion)

      assert_nil stats.average
      assert_equal 0, stats.evaluated_count
      assert_equal 1, stats.total_count
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
        title: "Meets",
        description: "Good",
        performance_level: :meets,
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
      stats = result.for(criterion)

      assert_equal 3.0, stats.average
      assert_equal 1, stats.evaluated_count
      assert_equal 2, stats.total_count
    end
  end
end
