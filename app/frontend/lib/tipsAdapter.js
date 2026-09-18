/**
 * #41 — TipsAdapter: открытие чаевых (default URL как у чата #94).
 */

import { TIPS_SERVICE_URL, tipsUrlForOrder } from "./tipsConfig.js"

/**
 * @param {string|number} orderId
 * @param {string|number} [tenantId]
 * @param {string} [tipsUrl]
 * @param {{
 *   openWindow?: (url: string, target: string) => unknown,
 *   assignLocation?: (url: string) => void,
 *   log?: (msg: string) => void,
 *   defaultUrl?: string
 * }} [deps]
 * @returns {{ opened: boolean, pending: boolean, fallback?: boolean }}
 */
export function openTipsService(orderId, tenantId, tipsUrl, deps = {}) {
  void tenantId
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

  const fallbackBase = Object.prototype.hasOwnProperty.call(deps, "defaultUrl")
    ? deps.defaultUrl
    : TIPS_SERVICE_URL

  let url = typeof tipsUrl === "string" ? tipsUrl.trim() : ""
  if (!url) {
    url = tipsUrlForOrder(orderId, fallbackBase)
  }

  if (!url) {
    log(`[Tips Integration Pending] Order: ${orderId}`)
    return { opened: false, pending: true }
  }

  const win = openWindow(url, "_blank")
  if (win) {
    return { opened: true, pending: false }
  }

  assignLocation(url)
  return { opened: true, pending: false, fallback: true }
}
