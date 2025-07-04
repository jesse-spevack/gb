import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    // Step targets
    "step1Circle", "step1Number", "step1Check", "step1Text",
    "step2Circle", "step2Number", "step2Check", "step2Text", 
    "step3Circle", "step3Number", "step3Check", "step3Text",
    "step4Circle", "step4Number", "step4Check", "step4Text",
    // Line targets  
    "line1to2", "line2to3", "line3to4",
    // Status targets
    "statusText", "spinner"
  ]

  static classes = [
    "active",        // bg-blue-600 - for circles and lines when active
    "inactive",      // bg-gray-200 - for circles and lines when inactive
    "activeText",    // text-white - for numbers in active circles
    "normalText",    // text-gray-900 - for numbers and normal text
    "mutedText",     // text-gray-500 - for completed step text
    "hidden"         // hidden - for hiding elements
  ]

  connect() {
    this.ensureLinesStartInactive()
    
    // Start progression after 2 seconds (all start grey)
    setTimeout(() => {
      this.startProgression()
    }, 2000)
  }

  ensureLinesStartInactive() {
    try {
      const allLines = [
        ...(this.line1to2Targets || []),
        ...(this.line2to3Targets || []),
        ...(this.line3to4Targets || [])
      ]
      
      allLines.forEach(line => {
        this.setBackgroundState(line, 'inactive')
      })
    } catch (error) {
      console.error("Error setting lines to inactive:", error)
    }
  }

  startProgression() {
    // Step 1: Complete step 1, activate step 2 (after 2s)
    setTimeout(() => {
      this.setStepCompleted(1)
      this.setStepInProgress(2)
      this.setLineActive("line1to2")
      this.updateStatusText("GradeBot is generating a rubric...")
    }, 2000)

    // Step 2: Complete step 2, activate step 3 (after 4s total)
    setTimeout(() => {
      this.setStepCompleted(2)
      this.setStepInProgress(3)
      this.setLineActive("line2to3")
      this.updateStatusText("GradeBot is analyzing student work...")
    }, 4000)

    // Step 3: Complete step 3, activate step 4 (after 6s total)
    setTimeout(() => {
      this.setStepCompleted(3)
      this.setStepInProgress(4)
      this.setLineActive("line3to4")
      this.updateStatusText("GradeBot is summarizing analysis...")
    }, 6000)

    // Step 4: Complete step 4 (after 8s total)
    setTimeout(() => {
      this.setStepCompleted(4)
      this.updateStatusText("Assignment processing complete!")
      this.hideSpinner()
    }, 8000)
  }

  setStepCompleted(stepNumber) {
    try {
      const stepTargets = this.getStepTargets(stepNumber)
      
      // Update circles to active state
      stepTargets.circles.forEach(circle => {
        this.setBackgroundState(circle, 'active')
      })
      
      // Hide numbers, show checkmarks
      this.toggleVisibility(stepTargets.numbers, true) // hide
      this.toggleVisibility(stepTargets.checks, false) // show
      
      // Update text to muted
      stepTargets.texts.forEach(text => {
        this.setTextState(text, 'muted')
      })
    } catch (error) {
      console.error(`Error setting step ${stepNumber} to completed:`, error)
    }
  }

  setStepInProgress(stepNumber) {
    try {
      const stepTargets = this.getStepTargets(stepNumber)
      
      // Update circles to active state
      stepTargets.circles.forEach(circle => {
        this.setBackgroundState(circle, 'active')
      })
      
      // Show numbers with active text, hide checkmarks
      stepTargets.numbers.forEach(number => {
        this.setTextState(number, 'active')
      })
      this.toggleVisibility(stepTargets.numbers, false) // show
      this.toggleVisibility(stepTargets.checks, true) // hide
    } catch (error) {
      console.error(`Error setting step ${stepNumber} to in progress:`, error)
    }
  }

  setStepNotStarted(stepNumber) {
    const stepTargets = this.getStepTargets(stepNumber)
    
    // Update circles to inactive state
    stepTargets.circles.forEach(circle => {
      this.setBackgroundState(circle, 'inactive')
    })
    
    // Show numbers with normal text, hide checkmarks
    stepTargets.numbers.forEach(number => {
      this.setTextState(number, 'normal')
    })
    this.toggleVisibility(stepTargets.numbers, false) // show
    this.toggleVisibility(stepTargets.checks, true) // hide
    
    // Update text to normal
    stepTargets.texts.forEach(text => {
      this.setTextState(text, 'normal')
    })
  }

  setLineActive(lineTarget) {
    try {
      const lines = this[`${lineTarget}Targets`] || []
      
      lines.forEach(line => {
        this.setBackgroundState(line, 'active')
      })
    } catch (error) {
      console.error(`Error making ${lineTarget} active:`, error)
    }
  }

  setLineInactive(lineTarget) {
    const lines = this[`${lineTarget}Targets`] || []
    lines.forEach(line => {
      this.setBackgroundState(line, 'inactive')
    })
  }

  updateStatusText(newText) {
    if (this.hasStatusTextTarget) {
      this.statusTextTarget.textContent = newText
    }
  }

  hideSpinner() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add(...this.hiddenClasses)
    }
  }

  // Helper methods for semantic class management

  /**
   * Set background state (active/inactive) for an element
   */
  setBackgroundState(element, state) {
    // Remove all possible background classes
    element.classList.remove('bg-blue-600', 'bg-gray-200')
    
    // Add the appropriate semantic class
    if (state === 'active') {
      element.classList.add(...this.activeClasses)
    } else {
      element.classList.add(...this.inactiveClasses)
    }
  }

  /**
   * Set text state (active/normal/muted) for an element
   */
  setTextState(element, state) {
    // Remove all possible text classes
    element.classList.remove('text-white', 'text-gray-900', 'text-gray-500')
    
    // Add the appropriate semantic class
    switch (state) {
      case 'active':
        element.classList.add(...this.activeTextClasses)
        break
      case 'muted':
        element.classList.add(...this.mutedTextClasses)
        break
      default: // normal
        element.classList.add(...this.normalTextClasses)
    }
  }

  /**
   * Toggle visibility of elements
   */
  toggleVisibility(elements, hide) {
    elements.forEach(element => {
      if (hide) {
        element.classList.add(...this.hiddenClasses)
      } else {
        element.classList.remove(...this.hiddenClasses)
      }
    })
  }

  /**
   * Get all targets for a specific step
   */
  getStepTargets(stepNumber) {
    return {
      circles: this[`step${stepNumber}CircleTargets`] || [],
      numbers: this[`step${stepNumber}NumberTargets`] || [],
      checks: this[`step${stepNumber}CheckTargets`] || [],
      texts: this[`step${stepNumber}TextTargets`] || []
    }
  }
} 