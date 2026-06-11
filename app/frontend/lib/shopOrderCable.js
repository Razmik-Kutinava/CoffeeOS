import { createConsumer } from "@rails/actioncable"

const MAX_WS_RETRIES = 3
const WS_RETRY_INTERVAL_MS = 5000

function shopTenantId() {
  const q = new URLSearchParams(window.location.search).get("tenant_id")
  if (q && String(q).trim()) return String(q).trim()
  return document.querySelector('meta[name="shop-tenant-id"]')?.getAttribute("content") || ""
}

/**
 * Подписка на live-обновления статуса заказа (B1.1 + B2.1 retry).
 * @returns {() => void} unsubscribe
 */
export function subscribeGuestOrderStatus({ orderId, reconnectToken, onStatus, onConnection }) {
  const tenantId = shopTenantId()
  if (!orderId || !tenantId) {
    onConnection?.("unavailable")
    return () => {}
  }

  const consumer = createConsumer()
  let subscription = null
  let retryCount = 0
  let retryTimer = null
  let disconnected = false
  let stopped = false

  const channelParams = {
    channel: "Shop::GuestOrderChannel",
    order_id: orderId,
    tenant_id: tenantId
  }
  if (reconnectToken) {
    channelParams.reconnect_token = reconnectToken
  }

  function clearRetryTimer() {
    if (retryTimer) {
      clearTimeout(retryTimer)
      retryTimer = null
    }
  }

  function scheduleRetry() {
    if (stopped || retryCount >= MAX_WS_RETRIES) return

    clearRetryTimer()
    retryTimer = setTimeout(() => {
      retryTimer = null
      if (stopped) return
      retryCount += 1
      subscription?.unsubscribe()
      subscription = null
      connect()
    }, WS_RETRY_INTERVAL_MS)
  }

  function connect() {
    subscription = consumer.subscriptions.create(channelParams, {
      connected() {
        disconnected = false
        retryCount = 0
        clearRetryTimer()
        onConnection?.("connected")
      },
      disconnected() {
        if (stopped || disconnected) return
        disconnected = true
        onConnection?.("disconnected")
        scheduleRetry()
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
    })
  }

  connect()

  return () => {
    stopped = true
    clearRetryTimer()
    subscription?.unsubscribe()
    subscription = null
    consumer.disconnect()
  }
}
