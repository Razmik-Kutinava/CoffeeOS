/** B1.12 — inline оплата на checkout (без #/payment). */

import { savePaymentSession } from "./tbankPayment.js"
import { guestReconnectToken } from "./shopGuestSession.js"

export const SETTLE_POLL_MS = 1500
export const SAVED_CARD_RETRY_MS = SETTLE_POLL_MS
export const SAVED_CARD_RETRY_ATTEMPTS = 5

export function buildInlinePaymentSession(res, config = {}) {
  return {
    order_id: res.order_id,
    total: res.total,
    provider_payment_id: res.provider_payment_id,
    terminal_key: res.terminal_key || config.terminal_key,
    payment_url: res.payment_url,
    reconnect_token: res.reconnect_token,
    payment_iframe: true,
    payment_method: "card",
    card_binding: res.card_binding === true,
    integration_script_url: config.integration_script_url,
    payment_started: false
  }
}

export function persistInlineSession(session, { started = false } = {}) {
  const next = { ...session, payment_started: started || session.payment_started }
  savePaymentSession(next)
  return next
}

/** Poll finalize + cable пока заказ не accepted. */
export function createSettlementWatch(api, { orderId, reconnectToken, subscribe, shouldRun, onSettled }) {
  let active = true
  const token = reconnectToken || guestReconnectToken()

  const unsubCable =
    subscribe?.({
      orderId,
      reconnectToken: token,
      onStatus: (payload) => {
        if (!active || !shouldRun()) return
        if (payload?.payment_settled || payload?.status === "accepted") {
          onSettled()
        }
      }
    }) || (() => {})

  const timer = setInterval(async () => {
    if (!active || !shouldRun()) return
    try {
      const q = token ? `?reconnect_token=${encodeURIComponent(token)}` : ""
      const res = await api(`/orders/${orderId}/finalize${q}`, { method: "POST" })
      if (res.payment_settled || res.status === "accepted") {
        onSettled()
      }
    } catch {
      /* webhook ещё не пришёл */
    }
  }, SETTLE_POLL_MS)

  return () => {
    active = false
    clearInterval(timer)
    unsubCable()
  }
}
