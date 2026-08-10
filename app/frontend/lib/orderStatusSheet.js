/** #35 — состояние sticky OrderStatusSheet (peek/hidden), cable + reconnect.
 *  #47 — polling /orders/active как страховка, если Cable молчит на PWA.
 */

export const ORDER_STATUS_SHEET_MODES = Object.freeze({
  PEEK: "peek",
  EXPANDED: "expanded",
  HIDDEN: "hidden"
})

export const SHEET_POINTER_POLICY = Object.freeze({
  catalogClicksPassThrough: true,
  blockCatalogUnderSheet: false
})

/** Интервал sync активных заказов (как CATALOG_POLL_MS). Cable — fast-path. */
export const ACTIVE_ORDERS_POLL_MS = 8_000

let activeOrdersPollTimer = null

/**
 * Периодический tick пока sheet mounted. Visibility — в компоненте (G2).
 * @param {() => void} onTick
 */
export function startActiveOrdersPolling(onTick) {
  stopActiveOrdersPolling()
  if (typeof onTick !== "function") return

  activeOrdersPollTimer = setInterval(() => {
    try {
      onTick()
    } catch {
      /* leave last UI state */
    }
  }, ACTIVE_ORDERS_POLL_MS)
}

export function stopActiveOrdersPolling() {
  if (activeOrdersPollTimer) {
    clearInterval(activeOrdersPollTimer)
    activeOrdersPollTimer = null
  }
}

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

/** Terminal для снятия карточки / refresh frequent — выдача или отмена (не ready). */
export const SHEET_TERMINAL_STATUSES = Object.freeze([
  "issued",
  "closed",
  "cancelled"
])

/** Стабильный ключ набора id — poll не tear-down Cable, если список тот же. */
export function activeOrderIdsKey(orders) {
  const ids = (Array.isArray(orders) ? orders : [])
    .map((o) => normalizeId(o?.id ?? o?.order_id))
    .filter(Boolean)
  ids.sort()
  return ids.join(",")
}

export function applyCableEvent(state, payload, hooks = {}) {
  if (!payload || payload.type !== "status_changed") return
  const orderId = normalizeId(payload.order_id ?? payload.orderId)
  if (!orderId) return

  const status = String(payload.status || "")
  // ready остаётся в шторке («Готов» + CTA); иначе окно ready → пусто +0₽ без «повторить»
  const terminal = SHEET_TERMINAL_STATUSES.includes(status)
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
  const list = Array.isArray(orders) ? orders : []
  // accepted|preparing|ready — карточка до выдачи; issued/cancelled отсекает API
  state.setOrders(list)
}
