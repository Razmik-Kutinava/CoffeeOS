/**
 * #41 — TipsAdapter (нетмонет): открытие чаевых или pending-лог.
 *
 * @param {string|number} orderId
 * @param {string|number} [tenantId]
 * @param {string} [tipsUrl]
 * @param {{
 *   openWindow?: (url: string, target: string) => unknown,
 *   log?: (msg: string) => void
 * }} [deps]
 * @returns {{ opened: boolean, pending: boolean }}
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
  const log =
    deps.log ||
    ((msg) => {
      if (typeof console !== "undefined" && typeof console.info === "function") {
        console.info(msg)
      }
    })

  const url = typeof tipsUrl === "string" ? tipsUrl.trim() : ""
  if (!url) {
    log(`[Tips Integration Pending] Order: ${orderId}`)
    return { opened: false, pending: true }
  }

  openWindow(url, "_blank")
  return { opened: true, pending: false }
}
