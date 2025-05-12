import { Controller } from "@hotwired/stimulus"

/**
 * Simple feedback tone slider controller
 * Maps slider position to corresponding tone value for form submission
 */
export default class extends Controller {
  static targets = ["slider", "feedbackTone"]
  static values = { tones: Array }

  connect() {
    // Initialize hidden field with first tone if empty
    if (this.hasFeedbackToneTarget && this.hasTonesValue && this.tonesValue.length > 0) {
      if (!this.feedbackToneTarget.value) {
        this.feedbackToneTarget.value = this.tonesValue[0];
      }
    }
  }

  /**
   * Updates the hidden feedback tone field when slider moves
   */
  updateTone(event) {
    if (this.hasFeedbackToneTarget && this.hasTonesValue) {
      const index = parseInt(event.target.value, 10);
      if (index >= 0 && index < this.tonesValue.length) {
        this.feedbackToneTarget.value = this.tonesValue[index];
      }
    }
  }
}
