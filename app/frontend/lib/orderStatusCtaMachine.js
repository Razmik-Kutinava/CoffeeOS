/**
 * #38 — PWA CTA state machine карточки заказа (макс. 2 кнопки, UI-kit #37).
 */

import { CTA_STYLE } from "./orderStatusNotifyActions.js"

export { CTA_STYLE }

const LABELS = Object.freeze({
  cancel: "Отменить",
  push: "🔔 Уведомление о готовности",
  wallet: "Карта в Apple Wallet",
  chat: "Чат",
  tips: "Чаевые"
})

/**
 * @param {{
 *   status?: string,
 *   os?: "ios"|"android"|"desktop",
 *   canCancel?: boolean
 * }} opts
 * @returns {{ buttons: Array<{ kind: string, label: string }>, style: typeof CTA_STYLE }}
 */
export function orderStatusCtas(opts = {}) {
  const status = String(opts.status || "")
  const os = opts.os || "desktop"
  const canCancel = Boolean(opts.canCancel)
  const notifyKind = os === "ios" ? "wallet" : "push"
  const secondaryKind = os === "ios" ? "wallet" : "tips"

  /** @type {Array<{ kind: string, label: string }>} */
  let buttons = []

  if (status === "accepted") {
    if (canCancel) buttons.push({ kind: "cancel", label: LABELS.cancel })
    buttons.push({ kind: notifyKind, label: LABELS[notifyKind] })
  } else if (status === "preparing" || status === "ready") {
    buttons.push({ kind: "chat", label: LABELS.chat })
    buttons.push({ kind: secondaryKind, label: LABELS[secondaryKind] })
  }

  if (buttons.length > 2) buttons = buttons.slice(0, 2)

  return { buttons, style: CTA_STYLE }
}

/**
 * @param {string} cableState
 */
export function showReconnectBanner(cableState) {
  return cableState === "disconnected"
}
