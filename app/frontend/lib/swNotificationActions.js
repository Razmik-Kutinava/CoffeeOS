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
 * @param {string|number} orderId
 * @param {string|number} [tenantId]
 */
export function cancelOrderRequest(orderId, tenantId) {
  const tid = String(tenantId || "").trim()
  let url = `/shop/api/orders/${orderId}/cancel`
  if (tid) url += `?tenant_id=${encodeURIComponent(tid)}`
  const headers = { Accept: "application/json" }
  if (tid) headers["X-Shop-Tenant"] = tid
  return { url, headers }
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
 *   tenantId?: string|number,
 *   fetchImpl?: typeof fetch,
 *   openClient: (url: string) => Promise<unknown>,
 *   showLocalNotification: (title: string, body: string) => Promise<unknown>
 * }} opts
 */
export async function handleNotificationAction(opts) {
  const {
    action,
    orderId,
    tenantId,
    fetchImpl = globalThis.fetch.bind(globalThis),
    openClient,
    showLocalNotification
  } = opts

  if (action === "cancel") {
    try {
      const req = cancelOrderRequest(orderId, tenantId)
      const res = await fetchImpl(req.url, {
        method: "POST",
        credentials: "include",
        headers: req.headers
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

/**
 * #94 — handle FCM SW postMessage `{ type: "coffeeos_navigate", url }`.
 * Chat deep links open support; other actions assign location.
 *
 * @param {unknown} data
 * @param {{
 *   openSupportChat?: (orderId: string, chatUrl?: string) => unknown,
 *   openTipsService?: (orderId: string, tenantId?: string, tipsUrl?: string) => unknown,
 *   assignLocation?: (url: string) => void,
 *   chatUrl?: string,
 *   tipsUrl?: string
 * }} [deps]
 * @returns {{ handled: boolean, kind?: string }}
 */
export function handleCoffeeosNavigateMessage(data, deps = {}) {
  if (!data || typeof data !== "object") return { handled: false }
  const msg = /** @type {{ type?: string, url?: string }} */ (data)
  if (msg.type !== "coffeeos_navigate") return { handled: false }
  const url = typeof msg.url === "string" ? msg.url : ""
  if (!url) return { handled: false }

  const actionMatch = url.match(/[?&]action=([^&/#]+)/)
  const action = actionMatch ? decodeURIComponent(actionMatch[1]) : ""
  const orderMatch = url.match(/#\/order\/([^/?#]+)/)
  const orderId = orderMatch ? decodeURIComponent(orderMatch[1]) : ""

  if (action === "chat") {
    const open =
      deps.openSupportChat ||
      (() => {
        /* optional */
      })
    open(orderId || "unknown", deps.chatUrl)
    return { handled: true, kind: "chat" }
  }

  if (action === "tips") {
    const open =
      deps.openTipsService ||
      (() => {
        /* optional */
      })
    open(orderId || "unknown", "", deps.tipsUrl)
    return { handled: true, kind: "tips" }
  }

  const assign =
    deps.assignLocation ||
    ((u) => {
      if (typeof globalThis.location !== "undefined") {
        globalThis.location.assign(u)
      }
    })
  assign(url)
  return { handled: true, kind: "navigate" }
}

/**
 * #94 cold-start: when SW `openWindow` loads deep link without postMessage,
 * boot reads hash `?action=chat|tips` and runs the same navigate handler.
 *
 * @param {{ hash?: string }|string} locationLike
 * @param {Parameters<typeof handleCoffeeosNavigateMessage>[1]} [deps]
 */
export function handleCoffeeosHashBoot(locationLike, deps = {}) {
  const hash =
    typeof locationLike === "string"
      ? locationLike.includes("#")
        ? locationLike.slice(locationLike.indexOf("#"))
        : locationLike.startsWith("#")
          ? locationLike
          : ""
      : String((locationLike && locationLike.hash) || "")

  if (!hash || !/[?&]action=/.test(hash)) return { handled: false }

  const url = `/shop/${hash.startsWith("#") ? hash : `#${hash}`}`
  return handleCoffeeosNavigateMessage({ type: "coffeeos_navigate", url }, deps)
}
