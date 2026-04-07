import { Controller } from "@hotwired/stimulus"

// Долгое нажатие на строку в футере → открыть модалку входа для редакторов.
export default class extends Controller {
  static targets = ["dialog"]
  static values = { ms: { type: Number, default: 750 } }

  connect() {
    this._timer = null
  }

  startHold(event) {
    if (event.button !== undefined && event.button !== 0) return
    this.cancelHold()
    this._timer = window.setTimeout(() => this.openDialog(), this.msValue)
  }

  cancelHold() {
    if (this._timer) {
      window.clearTimeout(this._timer)
      this._timer = null
    }
  }

  openDialog() {
    this.cancelHold()
    if (this.hasDialogTarget && typeof this.dialogTarget.showModal === "function") {
      this.dialogTarget.showModal()
    }
  }

  closeDialog() {
    if (this.hasDialogTarget && typeof this.dialogTarget.close === "function") {
      this.dialogTarget.close()
    }
  }

  backdropClose(event) {
    if (this.hasDialogTarget && event.target === this.dialogTarget) {
      this.closeDialog()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
