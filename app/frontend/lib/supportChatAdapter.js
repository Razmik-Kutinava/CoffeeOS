/**
 * #41 / #81 — SupportChatAdapter: открытие чата поддержки.
 * Без явного URL — default `SUPPORT_TELEGRAM_URL` (#70 / #81).
 * #94: same-tab fallback when window.open blocked (PWA / WebView).
 */

import { SUPPORT_TELEGRAM_URL } from "./supportConfig.js"

/**
 * @param {string|number} orderId
 * @param {string} [chatUrl]
 * @param {{
 *   openWindow?: (url: string, target: string) => unknown,
 *   assignLocation?: (url: string) => void,
 *   log?: (msg: string) => void,
 *   defaultUrl?: string
 * }} [deps]
 * @returns {{ opened: boolean, pending: boolean, fallback?: boolean }}
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
  const assignLocation =
    deps.assignLocation ||
    ((url) => {
      if (typeof globalThis.location !== "undefined") {
        globalThis.location.assign(url)
      }
    })
  const log =
    deps.log ||
    ((msg) => {
      if (typeof console !== "undefined" && typeof console.info === "function") {
        console.info(msg)
      }
    })

  const fallback =
    Object.prototype.hasOwnProperty.call(deps, "defaultUrl")
      ? deps.defaultUrl
      : SUPPORT_TELEGRAM_URL

  let url = typeof chatUrl === "string" ? chatUrl.trim() : ""
  if (!url) {
    url = typeof fallback === "string" ? fallback.trim() : ""
  }

  if (!url) {
    log(`[Chat Integration Pending] Order: ${orderId}`)
    return { opened: false, pending: true }
  }

  const win = openWindow(url, "_blank")
  if (win) {
    return { opened: true, pending: false }
  }

  assignLocation(url)
  return { opened: true, pending: false, fallback: true }
}
