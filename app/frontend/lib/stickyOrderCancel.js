/**
 * #41 — отмена заказа из sticky-панели (sheet state + toast outcomes).
 */

import {
  resolveCancelSuccessResult,
  resolveCancelErrorResult
} from "./orderCancelFlow.js"

function normalizeId(id) {
  return id == null ? "" : String(id)
}

/**
 * Успешная отмена (HTTP 200): убрать заказ из sticky-списка.
 *
 * @param {{ orders: Array<object>, setOrders: (orders: Array<object>) => void }} state
 * @param {Record<string, unknown>} updatedOrder
 * @returns {{ toast: string, toastTone: "success", order: Record<string, unknown> }}
 */
export function applyStickyCancelSuccess(state, updatedOrder) {
  const outcome = resolveCancelSuccessResult(updatedOrder)
  const orderId = normalizeId(updatedOrder?.id ?? updatedOrder?.order_id)
  if (state && typeof state.setOrders === "function" && orderId) {
    state.setOrders(
      (state.orders || []).filter(
        (o) => normalizeId(o.id ?? o.order_id) !== orderId
      )
    )
  }
  return outcome
}

/**
 * Ошибка отмены: при forceStatus патчит заказ в sheet (preparing / can_cancel).
 *
 * @param {{ orders: Array<object> }} state
 * @param {string|number} orderId
 * @param {{ httpStatus?: number, message?: string, status?: number } | null | undefined} error
 * @returns {ReturnType<typeof resolveCancelErrorResult>}
 */
export function applyStickyCancelError(state, orderId, error) {
  const httpStatus = Number(error?.httpStatus ?? error?.status ?? 0)
  const outcome = resolveCancelErrorResult({
    httpStatus,
    message: error?.message
  })

  if (!state?.orders || !outcome.forceStatus) return outcome

  const id = normalizeId(orderId)
  const idx = state.orders.findIndex(
    (o) => normalizeId(o.id ?? o.order_id) === id
  )
  if (idx < 0) return outcome

  // #63: новая ссылка массива (Svelte 5), без in-place мутации
  state.orders = state.orders.map((o, i) =>
    i === idx
      ? { ...o, status: outcome.forceStatus, can_cancel: outcome.canCancel }
      : o
  )
  return outcome
}
