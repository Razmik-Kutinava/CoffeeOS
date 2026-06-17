const STORAGE_KEY = "barista_sound_unlocked"
export const BANNER_TEXT = "Звук заблокирован. Кликните по экрану для включения"

export class OrderBoardSound {
  constructor({ audioUrl, onBlockedChange } = {}) {
    this.audioUrl = audioUrl
    this.onBlockedChange = onBlockedChange
    this.audio = null
    this.unlocked = false
    this.blocked = false
    this.playCount = 0
    this.lastPlayAt = null
    this.lastPlayLatencyMs = null
    this.lastStreamAt = null
    this.knownOrderIds = new Set()
    this.initialized = false
    this._observer = null
  }

  async preload() {
    if (this.audio) return this.audio
    this.audio = new Audio(this.audioUrl)
    this.audio.preload = "auto"
    await new Promise((resolve) => {
      const done = () => resolve()
      this.audio.addEventListener("canplaythrough", done, { once: true })
      this.audio.addEventListener("error", done, { once: true })
      this.audio.load()
    })
    return this.audio
  }

  restoreUnlockFromSession() {
    if (sessionStorage.getItem(STORAGE_KEY) === "1") {
      this.unlocked = true
      this.preload().catch(() => {})
    }
  }

  async unlock() {
    await this.preload()
    if (!this.audio) return false

    try {
      const prevVolume = this.audio.volume
      this.audio.volume = 0.01
      this.audio.currentTime = 0
      await this.audio.play()
      this.audio.pause()
      this.audio.currentTime = 0
      this.audio.volume = prevVolume
      this.unlocked = true
      this.setBlocked(false)
      sessionStorage.setItem(STORAGE_KEY, "1")
      console.info("[barista-sound] audio unlocked")
      return true
    } catch (error) {
      console.error("[barista-sound] unlock failed:", error.name, error.message)
      this.handlePlaybackError(error)
      return false
    }
  }

  async playNewOrder() {
    if (!this.unlocked) {
      this.handlePlaybackError(new DOMException("play() without unlock", "NotAllowedError"))
      return false
    }

    await this.preload()
    const started = performance.now()

    try {
      this.audio.currentTime = 0
      await this.audio.play()
      this.playCount += 1
      this.lastPlayAt = new Date().toISOString()
      this.lastPlayLatencyMs = Math.round(performance.now() - started)
      console.info("[barista-sound] played new order", { latencyMs: this.lastPlayLatencyMs })
      return true
    } catch (error) {
      console.error("[barista-sound] play failed:", error.name, error.message)
      this.handlePlaybackError(error)
      return false
    }
  }

  handlePlaybackError(error) {
    if (error?.name === "NotAllowedError" || error?.name === "AbortError") {
      this.unlocked = false
      sessionStorage.removeItem(STORAGE_KEY)
      this.setBlocked(true)
    }
  }

  setBlocked(value) {
    this.blocked = value
    if (this.onBlockedChange) this.onBlockedChange(value)
  }

  snapshotOrderIds() {
    const ids = new Set()
    document.querySelectorAll("#barista-board-slots .board-slot-card[id^='order_']").forEach((el) => {
      const id = el.id.replace(/^order_/, "")
      if (id) ids.add(id)
    })
    return ids
  }

  onBoardMutation() {
    const current = this.snapshotOrderIds()
    if (!this.initialized) {
      this.knownOrderIds = current
      this.initialized = true
      return
    }
    this.detectNewAcceptedOrders(this.knownOrderIds)
    this.knownOrderIds = current
  }

  detectNewAcceptedOrders(previousIds) {
    const prev = previousIds instanceof Set ? previousIds : this.knownOrderIds
    const current = this.snapshotOrderIds()

    for (const id of current) {
      if (prev.has(id)) continue
      const el = document.getElementById(`order_${id}`)
      if (el?.classList.contains("board-slot-card--accepted")) {
        this.lastStreamAt = new Date().toISOString()
        this.playNewOrder()
      }
    }

    this.knownOrderIds = current
    if (!this.initialized) {
      this.initialized = true
    }
  }

  observeBoard() {
    const board = document.getElementById("barista-board-slots")
    if (!board) return

    if (this._observer) {
      this._observer.disconnect()
      this._observer = null
    }

    this.onBoardMutation()
    this._observer = new MutationObserver(() => this.onBoardMutation())
    this._observer.observe(board, { childList: true, subtree: true })
  }

  disconnect() {
    if (this._observer) {
      this._observer.disconnect()
      this._observer = null
    }
  }

  debugState() {
    return {
      unlocked: this.unlocked,
      blocked: this.blocked,
      playCount: this.playCount,
      lastPlayAt: this.lastPlayAt,
      lastPlayLatencyMs: this.lastPlayLatencyMs,
      lastStreamAt: this.lastStreamAt,
      audioUrl: this.audioUrl,
      knownOrders: [...this.knownOrderIds]
    }
  }
}
