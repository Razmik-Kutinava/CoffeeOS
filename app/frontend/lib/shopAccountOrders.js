import { api } from "./api.js"
import { isOfflineError } from "./shopNetwork.js"

/**
 * @typedef {{ id: number|string, order_number?: string, title?: string, created_at: string, total?: number, status?: string }} AccountOrderRow
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
