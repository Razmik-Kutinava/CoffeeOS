/**
 * #38 — логика action buttons FCM / Service Worker (тесты + источник правды).
 * Classic SW (`firebase_sw/show.js.erb`) держит зеркало без ESM import.
 */

export const CANCEL_ERROR_MESSAGE = "Не удалось отменить, проверьте сеть"

const ACTION_TITLES = Object.freeze({
  cancel: "Отменить",
  chat: "Чат",
  tips: "Чаевые"
})

/**
 * @param {unknown} raw
 * @returns {string[]}
 */
export function parseNotificationActions(raw) {
  if (Array.isArray(raw)) {
    return raw.map(String).filter(Boolean)
  }
  if (typeof raw !== "string" || !raw.trim()) return []
  try {
    const parsed = JSON.parse(raw)
    return Array.isArray(parsed) ? parsed.map(String).filter(Boolean) : []
  } catch {
    return []
  }
}

/**
 * @param {string|number} orderId
 * @param {"chat"|"tips"|string} action
 */
export function orderDeepLink(orderId, action) {
  return `/shop/#/order/${orderId}?action=${encodeURIComponent(action)}`
}

/**
 * @param {{ body?: string, data?: Record<string, unknown> }} input
 */
export function buildShowNotificationOptions(input = {}) {
  const data = { ...(input.data || {}) }
  const actions = parseNotificationActions(data.actions).map((action) => ({
    action,
    title: ACTION_TITLES[action] || action
  }))

  const opts = {
    body: input.body || "",
    data,
    actions
  }
  if (data.tag) opts.tag = String(data.tag)
  return opts
}

/**
 * @param {{
 *   action: string,
 *   orderId: string|number,
 *   fetchImpl?: typeof fetch,
 *   openClient: (url: string) => Promise<unknown>,
 *   showLocalNotification: (title: string, body: string) => Promise<unknown>
 * }} opts
 */
export async function handleNotificationAction(opts) {
  const {
    action,
    orderId,
    fetchImpl = globalThis.fetch.bind(globalThis),
    openClient,
    showLocalNotification
  } = opts

  if (action === "cancel") {
    try {
      const res = await fetchImpl(`/shop/api/orders/${orderId}/cancel`, {
        method: "POST",
        credentials: "include",
        headers: { Accept: "application/json" }
      })
      if (!res.ok) {
        await showLocalNotification("CoffeeOS", CANCEL_ERROR_MESSAGE)
        return { kind: "cancel_error" }
      }
      return { kind: "cancel_ok" }
    } catch {
      await showLocalNotification("CoffeeOS", CANCEL_ERROR_MESSAGE)
      return { kind: "cancel_error" }
    }
  }

  if (action === "chat" || action === "tips") {
    const url = orderDeepLink(orderId, action)
    await openClient(url)
    return { kind: "navigate" }
  }

  return { kind: "ignored" }
}
