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
    "circleNotStarted",
    "circleInProgress", 
    "circleCompleted",
    "numberNotStarted",
    "numberInProgress",
    "textNormal",
    "textMuted",
    "lineInactive",
    "lineActive",
    "hidden",
    "spinnerHidden"
  ]

  connect() {
    // Ensure all lines start inactive
    this.ensureLinesStartInactive()
    
    // Start progression after 2 seconds (all start grey)
    setTimeout(() => {
      this.startProgression()
    }, 2000)
  }

  ensureLinesStartInactive() {
    try {
      // Get all line targets (may have multiple for responsive design)
      const allLines = [
        ...(this.line1to2Targets || []),
        ...(this.line2to3Targets || []),
        ...(this.line3to4Targets || [])
      ]
      
      allLines.forEach(line => {
        line.className = line.className.replace(/bg-\w+-\d+/g, '').trim()
        line.classList.add(...this.lineInactiveClasses)
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
      const circles = this[`step${stepNumber}CircleTargets`] || []
      const numbers = this[`step${stepNumber}NumberTargets`] || []
      const checks = this[`step${stepNumber}CheckTargets`] || []
      const texts = this[`step${stepNumber}TextTargets`] || []

      // Update all circles (mobile + desktop)
      circles.forEach(circle => {
        circle.className = circle.className.replace(/bg-\w+-\d+/g, '').trim()
        circle.classList.add(...this.circleCompletedClasses)
      })
      
      // Update all numbers (hide them)
      numbers.forEach(number => {
        number.classList.add(...this.hiddenClasses)
      })
      
      // Update all checkmarks (show them)
      checks.forEach(check => {
        check.classList.remove(...this.hiddenClasses)
      })
      
      // Update all text (muted for completed steps)
      texts.forEach(text => {
        text.className = text.className.replace(/text-\w+-\d+/g, '').trim()
        text.classList.add(...this.textMutedClasses)
      })
    } catch (error) {
      console.error(`Error setting step ${stepNumber} to completed:`, error)
    }
  }

  setStepInProgress(stepNumber) {
    try {
      const circles = this[`step${stepNumber}CircleTargets`] || []
      const numbers = this[`step${stepNumber}NumberTargets`] || []
      const checks = this[`step${stepNumber}CheckTargets`] || []

      // Update all circles (mobile + desktop)
      circles.forEach(circle => {
        circle.className = circle.className.replace(/bg-\w+-\d+/g, '').trim()
        circle.classList.add(...this.circleInProgressClasses)
      })
      
      // Update all numbers (show with white text)
      numbers.forEach(number => {
        number.className = number.className.replace(/text-\w+-\d+/g, '').trim()
        number.classList.add(...this.numberInProgressClasses)
        number.classList.remove(...this.hiddenClasses)
      })
      
      // Update all checkmarks (hide them)
      checks.forEach(check => {
        check.classList.add(...this.hiddenClasses)
      })
    } catch (error) {
      console.error(`Error setting step ${stepNumber} to in progress:`, error)
    }
  }

  setStepNotStarted(stepNumber) {
    const circles = this[`step${stepNumber}CircleTargets`] || []
    const numbers = this[`step${stepNumber}NumberTargets`] || []
    const checks = this[`step${stepNumber}CheckTargets`] || []
    const texts = this[`step${stepNumber}TextTargets`] || []

    // Update all circles (gray background)
    circles.forEach(circle => {
      circle.className = circle.className.replace(/bg-\w+-\d+/g, '').trim()
      circle.classList.add(...this.circleNotStartedClasses)
    })
    
    // Update all numbers (show with black text)
    numbers.forEach(number => {
      number.className = number.className.replace(/text-\w+-\d+/g, '').trim()
      number.classList.add(...this.numberNotStartedClasses)
      number.classList.remove(...this.hiddenClasses)
    })
    
    // Update all checkmarks (hide them)
    checks.forEach(check => {
      check.classList.add(...this.hiddenClasses)
    })
    
    // Update all text (normal color for future steps)
    texts.forEach(text => {
      text.className = text.className.replace(/text-\w+-\d+/g, '').trim()
      text.classList.add(...this.textNormalClasses)
    })
  }

  setLineActive(lineTarget) {
    try {
      const lines = this[`${lineTarget}Targets`] || []
      
      lines.forEach(line => {
        line.className = line.className.replace(/bg-\w+-\d+/g, '').trim()
        line.classList.add(...this.lineActiveClasses)
      })
    } catch (error) {
      console.error(`Error making ${lineTarget} active:`, error)
    }
  }

  setLineInactive(lineTarget) {
    const lines = this[`${lineTarget}Targets`] || []
    lines.forEach(line => {
      line.className = line.className.replace(/bg-\w+-\d+/g, '').trim()
      line.classList.add(...this.lineInactiveClasses)
    })
  }

  updateStatusText(newText) {
    if (this.hasStatusTextTarget) {
      this.statusTextTarget.textContent = newText
    }
  }

  hideSpinner() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add(...this.spinnerHiddenClasses)
    }
  }
} 