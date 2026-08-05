/** #35 — состояние sticky OrderStatusSheet (peek/hidden), cable + reconnect. */

export const ORDER_STATUS_SHEET_MODES = Object.freeze({
  PEEK: "peek",
  EXPANDED: "expanded",
  HIDDEN: "hidden"
})

export const SHEET_POINTER_POLICY = Object.freeze({
  catalogClicksPassThrough: true,
  blockCatalogUnderSheet: false
})

export function shouldScrollStatusList(orders) {
  return (orders?.length || 0) > 2
}

export function mapReconnectError(status) {
  if (status === 404) return "hide"
  if (status >= 500) return "error_retry"
  return "error_retry"
}

function normalizeId(id) {
  return id == null ? "" : String(id)
}

export function createOrderStatusSheetState() {
  const state = {
    mode: ORDER_STATUS_SHEET_MODES.HIDDEN,
    orders: [],
    connection: "idle",
    setOrders(orders) {
      state.orders = Array.isArray(orders) ? orders.slice() : []
      state.mode =
        state.orders.length > 0
          ? ORDER_STATUS_SHEET_MODES.PEEK
          : ORDER_STATUS_SHEET_MODES.HIDDEN
    },
    setConnection(value) {
      state.connection = value
    }
  }
  return state
}

export function applyCableEvent(state, payload, hooks = {}) {
  if (!payload || payload.type !== "status_changed") return
  const orderId = normalizeId(payload.order_id ?? payload.orderId)
  if (!orderId) return

  const terminal = ["issued", "closed", "cancelled"].includes(String(payload.status || ""))
  if (terminal) {
    state.setOrders(
      state.orders.filter((o) => normalizeId(o.id ?? o.order_id) !== orderId)
    )
    // Quick Repeat: после terminal — UI узнаёт has_active_order без reload
    if (typeof hooks.onTerminal === "function") hooks.onTerminal()
    return
  }

  const idx = state.orders.findIndex((o) => normalizeId(o.id ?? o.order_id) === orderId)
  if (idx < 0) return

  const prev = state.orders[idx]
  const next = {
    ...prev,
    status: payload.status,
    order_number: payload.order_number ?? prev.order_number,
    payment_settled: payload.payment_settled ?? prev.payment_settled
  }
  // #41: sticky CTA зависит от can_cancel вместе со status
  if (Object.prototype.hasOwnProperty.call(payload, "can_cancel")) {
    next.can_cancel = payload.can_cancel
  }
  state.orders[idx] = next
}

export function applyReconnectOrders(state, orders) {
  state.setOrders(Array.isArray(orders) ? orders : [])
}
