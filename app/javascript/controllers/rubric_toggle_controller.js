import { Controller } from "@hotwired/stimulus"

/**
 * RubricToggleController handles the toggle switch between generating a rubric with AI
 * and manually pasting a rubric into the form.
 *
 * Connects to data-controller="rubric-toggle"
 */
export default class extends Controller {
  static targets = ["switch", "knob", "generateLabel", "pasteLabel", "textarea"]
  static classes = [
    "switchActive", "switchInactive",
    "knobActive", "knobInactive",
    "textareaDisabled", "textLight",
    "hidden"
  ]
  
  connect() {
    try {
      // Check if the textarea already has content
      // If it does and it's not disabled, initialize in "Paste" mode
      if (this.textareaTarget.value && !this.textareaTarget.disabled) {
        this.isGenerate = false
        this.updateUI()
      } else {
        // Default to "Generate" mode (switch is on)
        this.isGenerate = true
        this.updateUI()
      }
    } catch (error) {
      console.error("Error initializing rubric toggle:", error)
    }
  }

  /**
   * Toggle between generate and paste modes
   */
  toggle() {
    try {
      this.isGenerate = !this.isGenerate
      this.updateUI()
      
      // Announce change for screen readers
      const mode = this.isGenerate ? "Generate rubric" : "Paste rubric"
      this.announce(`Switched to ${mode} mode`)
    } catch (error) {
      console.error("Error toggling rubric mode:", error)
    }
  }
  
  /**
   * Update the UI based on the current state
   * This reduces code duplication by centralizing all UI updates
   */
  updateUI() {
    // Update switch appearance
    this.switchTarget.setAttribute("aria-checked", this.isGenerate.toString())
    this.switchTarget.classList.toggle(this.switchActiveClass, this.isGenerate)
    this.switchTarget.classList.toggle(this.switchInactiveClass, !this.isGenerate)
    
    // Update knob position
    this.knobTarget.classList.toggle(this.knobActiveClass, this.isGenerate)
    this.knobTarget.classList.toggle(this.knobInactiveClass, !this.isGenerate)
    
    // Update labels visibility
    this.generateLabelTarget.classList.toggle(this.hiddenClass, !this.isGenerate)
    this.pasteLabelTarget.classList.toggle(this.hiddenClass, this.isGenerate)
    
    // Update textarea state
    this.textareaTarget.disabled = this.isGenerate
    this.textareaTarget.classList.toggle(this.textareaDisabledClass, this.isGenerate)
    this.textareaTarget.classList.toggle(this.textLightClass, this.isGenerate)
    
    // Update placeholder text
    this.textareaTarget.placeholder = this.isGenerate
      ? "GradeBot will generate an AI rubric based on your assignment details."
      : "Paste your rubric text here..."
  }
  
  /**
   * Announce a message to screen readers
   * @param {string} message - The message to announce
   */
  announce(message) {
    // Create an accessible live region if it doesn't exist
    let announcer = document.getElementById("rubric-toggle-announcer")
    if (!announcer) {
      announcer = document.createElement("div")
      announcer.id = "rubric-toggle-announcer"
      announcer.setAttribute("aria-live", "polite")
      announcer.setAttribute("class", "sr-only")
      document.body.appendChild(announcer)
    }
    
    // Set the message
    announcer.textContent = message
    
    // Clear after 5 seconds
    setTimeout(() => {
      announcer.textContent = ""
    }, 5000)
  }
}
