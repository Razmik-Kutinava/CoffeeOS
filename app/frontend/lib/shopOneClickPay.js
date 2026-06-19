/** B1.12-R3 — оплата в 1 клик: формат карты, ошибки, ожидание webhook. */

export const PAY_BTN = {
  idle: "idle",
  loading: "loading",
  success: "success",
  error: "error"
}

export const SUCCESS_REDIRECT_MS = 1500
const SETTLE_POLL_MS = 1200
const SETTLE_MAX_ATTEMPTS = 25

/** `[Visa] •••• 0777` из ответа saved_cards */
export function formatSavedCardLabel(card) {
  if (!card) return ""
  const brand = (card.payment_system || "Card").trim()
  const masked = String(card.masked_pan || "")
  const digits = masked.replace(/\D/g, "")
  const last4 = digits.length >= 4 ? digits.slice(-4) : masked.slice(-4)
  return `${brand} •••• ${last4}`
}

/** Q7: карта → привязать другую · сеть/инфра → повторить */
export function classifyCheckoutPayError(message) {
  const msg = String(message || "Не удалось оплатить").trim()
  const lower = msg.toLowerCase()

  if (/сеть|network|fetch|timeout|инфра|позже|недоступн|502|503|504/i.test(lower)) {
    return { message: msg, showBindOther: false, showRetry: true, kind: "network" }
  }
  if (/истёк|истек|expir|недостаточно|средств|заблокирован|блокир|отклон/i.test(lower)) {
    return { message: msg, showBindOther: true, showRetry: false, kind: "card" }
  }
  if (/подтвердите email/i.test(lower)) {
    return { message: msg, showBindOther: false, showRetry: false, kind: "auth" }
  }

  return { message: msg, showBindOther: false, showRetry: true, kind: "other" }
}

export function isOfflineLikeError(error) {
  const msg = String(error?.message || error || "").toLowerCase()
  return /failed to fetch|network|offline|timeout/i.test(msg)
}

/**
 * Ждём accepted после recurrent Charge (webhook / finalize).
 * @returns {Promise<object>} finalize или show response
 */
export async function waitForOrderSettled(api, { orderId, reconnectToken, subscribe }) {
  return new Promise((resolve, reject) => {
    let done = false
    let unsub = () => {}

    const finish = (fn, value) => {
      if (done) return
      done = true
      clearTimeout(timeout)
      unsub()
      fn(value)
    }

    const timeout = setTimeout(() => {
      finish(reject, new Error("Оплата ещё обрабатывается. Проверьте историю заказов."))
    }, SETTLE_MAX_ATTEMPTS * SETTLE_POLL_MS + 5000)

    unsub =
      subscribe?.({
        orderId,
        reconnectToken,
        onStatus: (payload) => {
          if (payload?.payment_settled || payload?.status === "accepted") {
            finish(resolve, { payment_settled: true, status: payload.status })
          }
        }
      }) || (() => {})

    const poll = async () => {
      for (let i = 0; i < SETTLE_MAX_ATTEMPTS; i += 1) {
        if (done) return
        try {
          const q = reconnectToken
            ? `?reconnect_token=${encodeURIComponent(reconnectToken)}`
            : ""
          const res = await api(`/orders/${orderId}/finalize${q}`, { method: "POST" })
          if (res.payment_settled || res.status === "accepted") {
            finish(resolve, res)
            return
          }
        } catch {
          /* retry */
        }
        await new Promise((r) => setTimeout(r, SETTLE_POLL_MS))
      }
      if (!done) {
        finish(reject, new Error("Оплата ещё обрабатывается. Проверьте историю заказов."))
      }
    }

    poll()
  })
}
