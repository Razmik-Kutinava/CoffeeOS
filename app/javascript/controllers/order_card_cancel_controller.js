import { Controller } from "@hotwired/stimulus"

// B2.1 этап 4 — overlay отмены на карточке табло
export default class extends Controller {
  static targets = ["overlay"]

  open(event) {
    event.preventDefault()
    event.stopPropagation()
    this.overlayTarget.hidden = false
    this.overlayTarget.classList.add("is-visible")
  }

  close(event) {
    event?.preventDefault()
    event?.stopPropagation()
    this.overlayTarget.classList.remove("is-visible")
    this.overlayTarget.hidden = true
  }
}
