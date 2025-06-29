import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="assignment-progress"
export default class extends Controller {
  static targets = ["progressBar", "progressText", "phaseIndicator"]
  static values = { 
    percentage: Number,
    animate: Boolean,
    assignmentId: Number
  }

  connect() {
    this.setupInitialState()
    this.setupConnectionMonitoring()
  }

  percentageValueChanged() {
    this.updateProgressBar()
    // Mark that we received an update (for connection health monitoring)
    this.lastUpdateTime = Date.now()
  }

  setupInitialState() {
    if (this.hasProgressBarTarget) {
      // Set initial width to 0 for smooth animation
      this.progressBarTarget.style.width = "0%"
      
      // Trigger initial animation after a brief delay
      setTimeout(() => {
        this.updateProgressBar()
      }, 100)
    }
  }

  updateProgressBar() {
    if (!this.hasProgressBarTarget) return

    const percentage = this.percentageValue || 0
    
    // Smooth transition to new percentage
    this.progressBarTarget.style.transition = "width 0.5s ease-out"
    this.progressBarTarget.style.width = `${percentage}%`
    
    // Update any progress text targets
    this.progressTextTargets.forEach(target => {
      target.textContent = `${percentage}%`
    })
  }

  // Called when a phase completes - adds fade-in animation
  phaseCompleted(event) {
    const phaseElement = event.currentTarget
    
    // Add completion animation
    phaseElement.classList.add("animate-pulse")
    
    // Remove animation after completion
    setTimeout(() => {
      phaseElement.classList.remove("animate-pulse")
      phaseElement.classList.add("opacity-100")
    }, 1000)
  }

  // Smooth fade-in for new content
  fadeInContent(element) {
    element.style.opacity = "0"
    element.style.transition = "opacity 0.3s ease-in"
    
    setTimeout(() => {
      element.style.opacity = "1"
    }, 50)
  }

  // Handle TurboStream updates with smooth animations
  turboStreamConnected() {
    // Listen for turbo:before-stream-render to add smooth transitions
    document.addEventListener("turbo:before-stream-render", this.handleStreamRender.bind(this))
  }

  handleStreamRender(event) {
    const action = event.detail.action
    const target = event.detail.target
    
    // Mark that we received a TurboStream update
    this.lastUpdateTime = Date.now()
    
    // Restore connection health if it was lost
    if (!this.connectionHealthy) {
      this.handleConnectionRestore()
    }
    
    // Add smooth transitions for updates
    if (action === "replace" || action === "update") {
      this.fadeInContent(target)
    }
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.handleStreamRender.bind(this))
    this.stopConnectionMonitoring()
  }

  // Connection monitoring and fallback polling
  setupConnectionMonitoring() {
    this.connectionHealthy = true
    this.lastUpdateTime = Date.now()
    this.pollingInterval = null
    this.connectionCheckInterval = null
    
    // Monitor TurboStream connection health
    this.startConnectionHealthCheck()
    
    // Listen for connection issues
    document.addEventListener("turbo:connect", this.handleConnectionRestore.bind(this))
    document.addEventListener("turbo:disconnect", this.handleConnectionLoss.bind(this))
  }

  startConnectionHealthCheck() {
    // Check every 30 seconds if we haven't received updates
    this.connectionCheckInterval = setInterval(() => {
      const timeSinceLastUpdate = Date.now() - this.lastUpdateTime
      
      // If no updates for 45 seconds and progress < 100%, assume connection issue
      if (timeSinceLastUpdate > 45000 && this.percentageValue < 100) {
        if (this.connectionHealthy) {
          console.warn("TurboStream connection appears unhealthy, starting fallback polling")
          this.handleConnectionLoss()
        }
      }
    }, 30000)
  }

  handleConnectionLoss() {
    this.connectionHealthy = false
    this.showConnectionStatus("Connection lost - using fallback updates")
    this.startFallbackPolling()
  }

  handleConnectionRestore() {
    if (!this.connectionHealthy) {
      console.log("TurboStream connection restored")
      this.connectionHealthy = true
      this.hideConnectionStatus()
      this.stopFallbackPolling()
      this.lastUpdateTime = Date.now()
    }
  }

  startFallbackPolling() {
    if (this.pollingInterval) return // Already polling
    
    // Poll every 10 seconds as fallback
    this.pollingInterval = setInterval(() => {
      this.fetchProgressUpdate()
    }, 10000)
  }

  stopFallbackPolling() {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval)
      this.pollingInterval = null
    }
  }

  stopConnectionMonitoring() {
    this.stopFallbackPolling()
    
    if (this.connectionCheckInterval) {
      clearInterval(this.connectionCheckInterval)
      this.connectionCheckInterval = null
    }
  }

  async fetchProgressUpdate() {
    if (!this.assignmentIdValue) return
    
    try {
      const response = await fetch(`/assignments/${this.assignmentIdValue}?format=json`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.updateFromPolledData(data)
        this.lastUpdateTime = Date.now()
      }
    } catch (error) {
      console.error("Failed to fetch progress update:", error)
    }
  }

  updateFromPolledData(data) {
    // Update progress if we have progress metrics
    if (data.progress_metrics) {
      const newPercentage = data.progress_metrics.overall_percentage
      if (newPercentage !== this.percentageValue) {
        this.percentageValue = newPercentage
        this.updateProgressBar()
      }
    }
  }

  showConnectionStatus(message) {
    // Create or update connection status indicator
    let statusEl = document.getElementById('turbo-connection-status')
    
    if (!statusEl) {
      statusEl = document.createElement('div')
      statusEl.id = 'turbo-connection-status'
      statusEl.className = 'fixed top-4 right-4 bg-yellow-100 border border-yellow-400 text-yellow-800 px-4 py-2 rounded-md text-sm shadow-lg z-50'
      document.body.appendChild(statusEl)
    }
    
    statusEl.textContent = message
    statusEl.style.display = 'block'
  }

  hideConnectionStatus() {
    const statusEl = document.getElementById('turbo-connection-status')
    if (statusEl) {
      statusEl.style.display = 'none'
    }
  }
}