const ORDER_ID_KEY = "shop_last_order_id"
const TOKEN_KEY = "shop_reconnect_token"

export function saveGuestOrderSession(orderId, reconnectToken) {
  try {
    sessionStorage.setItem(ORDER_ID_KEY, String(orderId))
    if (reconnectToken) sessionStorage.setItem(TOKEN_KEY, reconnectToken)
  } catch (_) {
    /* ignore */
  }
}

export function lastGuestOrderId() {
  try {
    return sessionStorage.getItem(ORDER_ID_KEY)
  } catch (_) {
    return null
  }
}

export function clearGuestOrderSession() {
  try {
    sessionStorage.removeItem(ORDER_ID_KEY)
    sessionStorage.removeItem(TOKEN_KEY)
  } catch (_) {
    /* ignore */
  }
}

export async function reconnectGuestOrder(api) {
  const orderId = lastGuestOrderId()
  const token = sessionStorage.getItem(TOKEN_KEY)
  if (!orderId || !token) return null

  try {
    return await api("/session/reconnect", {
      method: "POST",
      body: JSON.stringify({ order_id: orderId, reconnect_token: token })
    })
  } catch (_) {
    return null
  }
}

export function returningFromPaymentPage() {
  const ref = document.referrer || ""
  return /tbank\.ru|tinkoff\.ru/i.test(ref)
}
