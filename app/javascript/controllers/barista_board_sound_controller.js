import { Controller } from "@hotwired/stimulus"
import { OrderBoardSound, BANNER_TEXT } from "barista/order_board_sound"

// B2-S1 — звук нового заказа на табло бариста
export default class extends Controller {
  static values = {
    audioUrl: { type: String, default: "/audio/barista_new_order.wav" }
  }

  static targets = ["banner"]

  connect() {
    this.sound = new OrderBoardSound({
      audioUrl: this.audioUrlValue,
      onBlockedChange: (blocked) => this.toggleBanner(blocked)
    })
    this.sound.restoreUnlockFromSession()
    window.BaristaOrderSound = this.sound

    this.boundUnlock = () => this.unlockFromGesture()
    this.element.addEventListener("click", this.boundUnlock, { capture: true, once: false })

    document.addEventListener("turbo:load", this.onTurboLoad)
    document.addEventListener("turbo:render", this.onTurboRender)
    document.addEventListener("turbo:before-stream-render", this.wrapBoardStreamRender)
    this.onTurboLoad()
  }

  disconnect() {
    this.element.removeEventListener("click", this.boundUnlock, { capture: true })
    document.removeEventListener("turbo:load", this.onTurboLoad)
    document.removeEventListener("turbo:render", this.onTurboRender)
    document.removeEventListener("turbo:before-stream-render", this.wrapBoardStreamRender)
    this.sound?.disconnect()
    if (window.BaristaOrderSound === this.sound) delete window.BaristaOrderSound
  }

  onTurboLoad = () => {
    this.sound.observeBoard()
    this.sound.preload().catch(() => {})
  }

  onTurboRender = () => {
    this.sound.observeBoard()
  }

  wrapBoardStreamRender = (event) => {
    const stream = event.target
    if (!stream?.getAttribute || stream.getAttribute("target") !== "barista-board-slots") return

    const render = event.detail.render
    event.detail.render = async (streamElement) => {
      const prevIds = this.sound.snapshotOrderIds()
      await render(streamElement)
      this.sound.observeBoard()
      this.sound.detectNewAcceptedOrders(prevIds)
    }
  }

  unlockFromGesture() {
    if (this.sound.unlocked) return
    if (this._unlockInFlight) return
    this._unlockInFlight = true
    this.sound.unlock().finally(() => {
      this._unlockInFlight = false
    })
  }

  async unlockFromShift(event) {
    event.preventDefault()
    const form = event.currentTarget
    await this.sound.unlock()
    form.submit()
  }

  dismissBanner(event) {
    event.preventDefault()
    this.unlockFromGesture()
  }

  toggleBanner(show) {
    if (!this.hasBannerTarget) return
    this.bannerTarget.hidden = !show
    this.bannerTarget.setAttribute("aria-hidden", show ? "false" : "true")
  }
}

export { BANNER_TEXT }
