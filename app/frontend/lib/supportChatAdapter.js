/**
 * #41 — SupportChatAdapter: открытие чата поддержки или pending-лог.
 *
 * @param {string|number} orderId
 * @param {string} [chatUrl]
 * @param {{
 *   openWindow?: (url: string, target: string) => unknown,
 *   log?: (msg: string) => void
 * }} [deps]
 * @returns {{ opened: boolean, pending: boolean }}
 */
export function openSupportChat(orderId, chatUrl, deps = {}) {
  const openWindow =
    deps.openWindow ||
    ((url, target) => {
      if (typeof globalThis.open === "function") {
        return globalThis.open(url, target)
      }
      return null
    })
  const log =
    deps.log ||
    ((msg) => {
      if (typeof console !== "undefined" && typeof console.info === "function") {
        console.info(msg)
      }
    })

  const url = typeof chatUrl === "string" ? chatUrl.trim() : ""
  if (!url) {
    log(`[Chat Integration Pending] Order: ${orderId}`)
    return { opened: false, pending: true }
  }

  openWindow(url, "_blank")
  return { opened: true, pending: false }
}
