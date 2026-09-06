/**
 * #38 / #40 / #41 / #77 — PWA CTA state machine карточки заказа (макс. 2 кнопки).
 */

import { CTA_STYLE } from "./orderStatusNotifyActions.js"

export { CTA_STYLE }

const LABELS = Object.freeze({
  cancel: "Отменить заказ",
  cancelHintAccepted: "Вернем 100% · 1–3 дня",
  // #37 MCP-канон (не #41 черновик «Включить Push»)
  push: "🔔 Уведомление о готовности",
  wallet: "Карта в Apple Wallet",
  chat: "Чат с поддержкой",
  tips: "Оставить чаевые",
  subscription: "Оформить подписку"
})

/**
 * @param {{
 *   status?: string,
 *   os?: "ios"|"android"|"desktop",
 *   canCancel?: boolean,
 *   hasPushSubscription?: boolean,
 *   subscriptionOfferEnabled?: boolean,
 *   secondCtaMode?: "tips"|"subscription",
 *   eligibleForSubscriptionOffer?: boolean
 * }} opts
 * @returns {{
 *   buttons: Array<{ kind: string, label: string, hint?: string }>,
 *   style: typeof CTA_STYLE
 * }}
 */
export function orderStatusCtas(opts = {}) {
  let status = String(opts.status || "")
  if (status === "paid") status = "accepted"

  const os = opts.os || "desktop"
  const canCancel = Boolean(opts.canCancel)
  const hasPushSubscription = Boolean(opts.hasPushSubscription)
  const notifyKind = os === "ios" ? "wallet" : "push"
  const offerOn =
    Boolean(opts.subscriptionOfferEnabled) && String(opts.secondCtaMode || "") === "subscription"
  const eligible = Boolean(opts.eligibleForSubscriptionOffer)

  /** @type {Array<{ kind: string, label: string, hint?: string }>} */
  let buttons = []

  if (status === "pending_payment") {
    if (canCancel) {
      buttons.push({ kind: "cancel", label: LABELS.cancel })
    }
  } else if (status === "accepted") {
    if (canCancel) {
      buttons.push({
        kind: "cancel",
        label: LABELS.cancel,
        hint: LABELS.cancelHintAccepted
      })
    }
    buttons.push({ kind: notifyKind, label: LABELS[notifyKind] })
  } else if (status === "preparing" || status === "ready") {
    buttons.push({ kind: "chat", label: LABELS.chat })
    if (hasPushSubscription) {
      // #77: subscription offer only on ready when enabled + eligible; else tips fallback
      if (status === "ready" && offerOn && eligible) {
        buttons.push({ kind: "subscription", label: LABELS.subscription })
      } else {
        buttons.push({ kind: "tips", label: LABELS.tips })
      }
    } else {
      buttons.push({ kind: notifyKind, label: LABELS[notifyKind] })
    }
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
