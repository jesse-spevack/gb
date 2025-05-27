# frozen_string_literal: true

module Assignments
  # Calculates completion progress for an assignment based on LLM processing stages
  # Tracks progress for three phases: rubric generation, student work feedback, and summary generation
  class ProgressCalculator
    def initialize(assignment)
      @assignment = assignment
    end

    # Returns a hash with progress data for the assignment pipeline
    # @return [Hash] Progress data including percentages, counts, and phase information
    def calculate
      {
        overall_percentage: overall_percentage,
        completed_llm_calls: completed_llm_calls,
        total_llm_calls: total_llm_calls,
        rubric_complete: rubric_complete?,
        student_works_complete: completed_student_works_count,
        student_works_total: total_student_works_count,
        summary_complete: summary_complete?,
        phases: phase_details
      }
    end

    private

    # Memoized helper to avoid duplicate calculations
    def rubric_complete?
      @rubric_complete ||= @assignment.rubric&.persisted? && @assignment.rubric.criteria.any?
    end

    # Memoized helper to avoid duplicate database queries
    def completed_student_works_count
      @completed_student_works_count ||= @assignment.student_works.where.not(qualitative_feedback: nil).count
    end

    # Memoized helper to avoid duplicate database queries
    def total_student_works_count
      @total_student_works_count ||= @assignment.student_works.count
    end

    # Memoized helper to check if summary is complete
    def summary_complete?
      @summary_complete ||= @assignment.assignment_summary&.persisted?
    end

    # Calculate overall percentage based on completed LLM calls
    def overall_percentage
      return 0 if total_llm_calls.zero?
      ((completed_llm_calls.to_f / total_llm_calls) * 100).round
    end

    # Calculate total expected LLM calls for the assignment
    # 1 for rubric + N for student works + 1 for summary
    def total_llm_calls
      1 + total_student_works_count + 1
    end

    # Count all completed LLM calls across all phases
    def completed_llm_calls
      count = 0
      count += 1 if rubric_complete?
      count += completed_student_works_count
      count += 1 if summary_complete?
      count
    end

    # Generate detailed information about each processing phase
    def phase_details
      {
        rubric: {
          status: rubric_status,
          complete: rubric_complete?
        },
        student_works: {
          status: student_works_status,
          completed: completed_student_works_count,
          total: total_student_works_count,
          percentage: student_works_percentage
        },
        summary: {
          status: summary_status,
          complete: summary_complete?
        }
      }
    end

    # Determine status of rubric generation phase
    def rubric_status
      return :completed if rubric_complete?
      return :in_progress if @assignment.rubric&.persisted?
      :pending
    end

    # Determine status of student work feedback phase
    def student_works_status
      return :pending unless rubric_complete?
      return :completed if completed_student_works_count == total_student_works_count && total_student_works_count > 0
      return :in_progress if completed_student_works_count > 0
      :pending
    end

    # Determine status of summary generation phase
    def summary_status
      return :completed if summary_complete?
      return :in_progress if completed_student_works_count == total_student_works_count && total_student_works_count > 0
      :pending
    end

    # Calculate percentage of completed student works
    def student_works_percentage
      return 0 if total_student_works_count.zero?
      ((completed_student_works_count.to_f / total_student_works_count) * 100).round
    end
  end
end
