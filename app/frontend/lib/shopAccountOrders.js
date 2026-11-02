import { api } from "./api.js"
import { isOfflineError } from "./shopNetwork.js"

/** TASK_116: выделение заказа в истории до первого касания, не дольше 3 с. */
export const HISTORY_ORDER_HIGHLIGHT_MS = 3000

/**
 * @typedef {{ id?: string, name?: string, display_address?: string, closed?: boolean }} AccountOrderTenant
 * @typedef {{ id: number|string, order_number?: string, title?: string, created_at: string, total?: number, status?: string, tenant?: AccountOrderTenant }} AccountOrderRow
 */

/**
 * @param {{ page?: number, perPage?: number }} [opts]
 * @returns {Promise<{ orders: AccountOrderRow[], errorKind: null | 'network' | 'server' | 'auth' }>}
 */
export async function fetchAccountOrderHistory(opts = {}) {
  const page = opts.page || 1
  const perPage = opts.perPage || 20
  try {
    const orders = await api(`/orders/history?page=${page}&per_page=${perPage}`)
    return { orders: Array.isArray(orders) ? orders : [], errorKind: null }
  } catch (e) {
    if (Number(e.httpStatus) === 401) return { orders: [], errorKind: "auth" }
    if (isOfflineError(e)) return { orders: [], errorKind: "network" }
    return { orders: [], errorKind: "server" }
  }
}

/** @param {string} iso */
export function formatOrderHistoryDate(iso) {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ""
  return d.toLocaleDateString("ru-RU", { day: "2-digit", month: "2-digit" })
}

/** @param {AccountOrderRow} order */
export function orderHistoryLabel(order) {
  if (order.order_number) return order.order_number
  if (order.id != null) return `#${order.id}`
  return "Заказ"
}

/** @param {AccountOrderRow} order */
export function orderHistoryTitle(order) {
  return order.title?.trim() || "Заказ"
}

/**
 * TASK_116: название точки или «Точка закрыта» без названия (R11).
 * @param {{ tenant?: AccountOrderTenant } | null | undefined} orderOrTenant
 */
export function orderHistoryPointLabel(orderOrTenant) {
  const tenant = orderOrTenant?.tenant ?? orderOrTenant
  if (!tenant || typeof tenant !== "object") return ""
  if (tenant.closed) return "Точка закрыта"
  return (tenant.name || "").trim()
}

/**
 * @param {string} [hash] location.hash, например `#/profile?order=42`
 * @returns {string | null}
 */
export function parseProfileHighlightOrderId(hash) {
  const raw = hash == null ? "" : String(hash)
  const qi = raw.indexOf("?")
  if (qi < 0) return null
  const path = raw.slice(0, qi)
  if (!path.includes("/profile")) return null
  const id = new URLSearchParams(raw.slice(qi + 1)).get("order")
  return id && String(id).trim() ? String(id).trim() : null
}
