import { Controller } from "@hotwired/stimulus"
import { installSlowRequestTracker, onSlowRequestChange } from "shared/slow_request_tracker"

export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    installSlowRequestTracker()
    this.unsubscribe = onSlowRequestChange((visible) => {
      this.toggleOverlay(visible)
    })
  }

  disconnect() {
    this.unsubscribe?.()
  }

  toggleOverlay(visible) {
    if (!this.hasOverlayTarget) return

    this.overlayTarget.classList.toggle("slow-request-overlay--visible", visible)
    this.overlayTarget.setAttribute("aria-hidden", visible ? "false" : "true")
    document.body.classList.toggle("slow-request-active", visible)
  }
}
