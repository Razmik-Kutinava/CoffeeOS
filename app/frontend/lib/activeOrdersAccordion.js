/** #36 — accordion активных заказов + текстовый чек (без кнопок в чеке). */

import { orderProgressView } from "./orderStatusProgress.js"

export const RECEIPT_SCROLL = Object.freeze({
  maxHeightPx: 350,
  overflowY: "auto"
})

export const CHEVRON = Object.freeze({
  collapsed: ">",
  expanded: "v"
})

function normalizeId(id) {
  return id == null ? "" : String(id)
}

export function createActiveOrdersAccordionState(orders = []) {
  return {
    orders: Array.isArray(orders) ? orders.slice() : [],
    activeExpandedOrderId: null
  }
}

/** Ровно один expanded: повторный клик сворачивает. */
export function toggleExpandedOrder(state, orderId) {
  const id = normalizeId(orderId)
  if (!id) return
  state.activeExpandedOrderId =
    normalizeId(state.activeExpandedOrderId) === id ? null : id
}

function firstProductName(order) {
  const items = Array.isArray(order?.items) ? order.items : []
  const first = items[0]
  if (!first) return ""
  return String(first.name || first.product_name || "").trim()
}

/**
 * #35 D2 / скрин 06: третий сегмент мета-строки.
 * cart_expanded → название позиции; peek (скрин 01) → точка продаж.
 */
export function statusMetaThird(order, sheetContext = "peek") {
  const salesPoint =
    order?.sales_point?.name || order?.tenant?.name || ""
  if (sheetContext === "cart_expanded") {
    // Без silent fallback на точку: иначе expanded выглядит как peek (скрин 01).
    return firstProductName(order)
  }
  return salesPoint
}

export function accordionRowView(order, activeExpandedOrderId, opts = {}) {
  const id = normalizeId(order?.id ?? order?.order_id)
  const expanded = id !== "" && normalizeId(activeExpandedOrderId) === id
  const progress = orderProgressView(order)
  const salesPointName =
    order?.sales_point?.name || order?.tenant?.name || ""
  const sheetContext = opts?.sheetContext || "peek"

  return {
    orderId: id,
    orderNumber: order?.order_number || "",
    salesPointName,
    metaThird: statusMetaThird(order, sheetContext),
    eta: progress.subtitle || null,
    expanded,
    chevron: expanded ? CHEVRON.expanded : CHEVRON.collapsed,
    steps: progress.steps || [],
    fillPercent: progress.fillPercent ?? 0,
    showProgress: progress.showProgress !== false
  }
}

export function receiptView(order) {
  const items = Array.isArray(order?.items) ? order.items : []
  const lines = items.map((item) => ({
    name: item.name || item.product_name || "",
    modifiers: Array.isArray(item.modifiers) ? item.modifiers : [],
    quantity: item.quantity ?? 0,
    price: Number(item.price ?? item.unit_price ?? 0),
    discount: Number(item.discount ?? 0),
    lineTotal: Number(item.line_total ?? item.lineTotal ?? item.total_price ?? 0)
  }))

  return {
    lines,
    subtotal: Number(order?.subtotal ?? 0),
    discount: Number(order?.discount ?? 0),
    totalAmount: Number(order?.total_amount ?? order?.totalAmount ?? 0),
    hasActionButtons: false,
    interactive: false
  }
}

export function receiptScrollStyle() {
  return {
    maxHeight: `${RECEIPT_SCROLL.maxHeightPx}px`,
    overflowY: RECEIPT_SCROLL.overflowY
  }
}
