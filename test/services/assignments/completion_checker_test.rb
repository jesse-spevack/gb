# frozen_string_literal: true

require "test_helper"

module Assignments
  class CompletionCheckerTest < ActiveSupport::TestCase
    test "returns false when assignment has no rubric" do
      assignment = Assignment.create!(
        user: users(:teacher),
        title: "Test Assignment",
        instructions: "Test",
        grade_level: "9",
        feedback_tone: "encouraging"
      )

      refute CompletionChecker.call(assignment)
    end

    test "returns false when assignment has no student works" do
      assignment = Assignment.create!(
        user: users(:teacher),
        title: "Test Assignment",
        instructions: "Test",
        grade_level: "9",
        feedback_tone: "encouraging"
      )

      # Create rubric but no student works
      Rubric.create!(assignment: assignment)

      refute CompletionChecker.call(assignment)
    end

    test "returns false when any student work is incomplete" do
      assignment = assignments(:english_essay)

      # Create two student works, one with feedback and one without
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

      StudentWork.create!(
        assignment: assignment,
        selected_document: doc1,
        qualitative_feedback: "Good work"
      )

      StudentWork.create!(
        assignment: assignment,
        selected_document: doc2,
        qualitative_feedback: nil
      )

      refute CompletionChecker.call(assignment)
    end

    test "returns true when all student works are complete" do
      assignment = assignments(:english_essay)

      # Create student works with feedback
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

      StudentWork.create!(
        assignment: assignment,
        selected_document: doc1,
        qualitative_feedback: "Good work"
      )

      StudentWork.create!(
        assignment: assignment,
        selected_document: doc2,
        qualitative_feedback: "Excellent work"
      )

      assert CompletionChecker.call(assignment)
    end
  end
end
