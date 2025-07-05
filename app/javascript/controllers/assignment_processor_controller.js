import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    steps: Array
  }

  connect() {
    console.log("Assignment processor connected", this.stepsValue)
  }

  stepsValueChanged() {
    console.log("Steps updated via Turbo Stream", this.stepsValue)
    // The DOM is already updated by Turbo Stream
    // This is just for debugging/future enhancements
  }
}