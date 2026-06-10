import { createConsumer } from "@rails/actioncable"

function shopTenantId() {
  const q = new URLSearchParams(window.location.search).get("tenant_id")
  if (q && String(q).trim()) return String(q).trim()
  return document.querySelector('meta[name="shop-tenant-id"]')?.getAttribute("content") || ""
}

/**
 * Подписка на live-обновления статуса заказа (B1.1 этап 2).
 * @returns {() => void} unsubscribe
 */
export function subscribeGuestOrderStatus({ orderId, reconnectToken, onStatus, onConnection }) {
  if (!orderId || !reconnectToken || !shopTenantId()) {
    onConnection?.("unavailable")
    return () => {}
  }

  const consumer = createConsumer()
  let disconnected = false

  const subscription = consumer.subscriptions.create(
    {
      channel: "Shop::GuestOrderChannel",
      order_id: orderId,
      tenant_id: shopTenantId(),
      reconnect_token: reconnectToken
    },
    {
      connected() {
        disconnected = false
        onConnection?.("connected")
      },
      disconnected() {
        if (!disconnected) {
          disconnected = true
          onConnection?.("disconnected")
        }
      },
      rejected() {
        onConnection?.("rejected")
      },
      received(data) {
        if (data?.type === "status_changed" && data.status) {
          onStatus?.({
            status: data.status,
            payment_settled: data.payment_settled,
            can_cancel: data.can_cancel,
            cancelled_by: data.cancelled_by,
            cancel_message: data.cancel_message
          })
        }
      }
    }
  )

  return () => {
    subscription.unsubscribe()
    consumer.disconnect()
  }
}
