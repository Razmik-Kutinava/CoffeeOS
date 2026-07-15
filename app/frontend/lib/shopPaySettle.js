/** Ожидание settled после Charge / 3DS (webhook → finalize). */

import { subscribeGuestOrderStatus } from "./shopOrderCable.js"

const SETTLE_POLL_MS = 1200
const SETTLE_MAX_ATTEMPTS = 25

/**
 * Ждём accepted после оплаты.
 * @returns {Promise<object>} finalize payload
 */
export async function waitForOrderSettled(
  api,
  { orderId, reconnectToken, subscribe = subscribeGuestOrderStatus, isCancelled = () => false } = {}
) {
  return new Promise((resolve, reject) => {
    let done = false
    let unsub = () => {}

    const finish = (fn, value) => {
      if (done) return
      done = true
      clearTimeout(timeout)
      clearInterval(cancelWatch)
      unsub()
      fn(value)
    }

    const timeout = setTimeout(() => {
      finish(reject, new Error("Оплата ещё обрабатывается. Проверьте историю заказов."))
    }, SETTLE_MAX_ATTEMPTS * SETTLE_POLL_MS + 5000)

    const cancelWatch = setInterval(() => {
      if (isCancelled()) {
        finish(reject, Object.assign(new Error("3DS aborted"), { kind: "three_ds_abort" }))
      }
    }, 200)

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
        if (done || isCancelled()) return
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
