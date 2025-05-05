import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="layout"
export default class extends Controller {
  connect() {
    // Initialize any necessary state
  }
  
  toggleMobileSidebar() {
    const sidebar = document.getElementById('mobile-sidebar')
    if (sidebar.style.display === 'none') {
      sidebar.style.display = 'block'
      // Prevent body scrolling when sidebar is open
      document.body.classList.add('overflow-hidden')
    } else {
      sidebar.style.display = 'none'
      // Restore body scrolling
      document.body.classList.remove('overflow-hidden')
    }
  }
}
