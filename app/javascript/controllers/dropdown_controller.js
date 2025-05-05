import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]
  
  connect() {
    // Close dropdown when clicking outside
    this.outsideClickHandler = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.outsideClickHandler)
  }
  
  disconnect() {
    document.removeEventListener("click", this.outsideClickHandler)
  }
  
  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }
  
  handleOutsideClick(event) {
    // Close the dropdown if user clicks outside
    if (!this.element.contains(event.target) && !this.menuTarget.classList.contains("hidden")) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
