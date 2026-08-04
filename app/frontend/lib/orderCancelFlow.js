/**
 * #40 — copy/format + toast/network outcomes для отмены заказа гостем.
 */

export const CANCEL_SUCCESS_TOAST =
  "Заказ отменён. Деньги ушли на возврат и поступят на счет в течение 1–3 дней."

export const CANCEL_BLOCKED_TOAST =
  "Заказ уже взяли в работу, автовозврат недоступен. Пожалуйста, обратитесь в поддержку."

/**
 * @param {unknown} value
 * @returns {string}
 */
export function formatCancelAmountRub(value) {
  return `${Math.round(Number(value) || 0)} ₽`
}

/**
 * @param {{ orderNumber?: string, amount?: unknown }} opts
 * @returns {{
 *   title: string,
 *   body: string,
 *   confirmLabel: string,
 *   dismissLabel: string
 * }}
 */
export function buildAcceptedCancelModalCopy(opts = {}) {
  const orderNumber = String(opts.orderNumber || "").trim() || "—"
  const sum = formatCancelAmountRub(opts.amount)

  return {
    title: `Отменить заказ №${orderNumber}?`,
    body: `Вернём ${sum} на карту. Обычно деньги приходят за 1–3 дня.`,
    confirmLabel: `Да, отменить и вернуть ${sum}`,
    dismissLabel: "Оставить заказ"
  }
}

/**
 * @param {string} status
 * @returns {boolean}
 */
export function shouldShowAcceptedCancelModal(status) {
  return String(status || "") === "accepted"
}

/**
 * @param {Record<string, unknown>} order
 * @returns {{
 *   toast: string,
 *   toastTone: "success",
 *   order: Record<string, unknown>
 * }}
 */
export function resolveCancelSuccessResult(order) {
  return {
    toast: CANCEL_SUCCESS_TOAST,
    toastTone: "success",
    order
  }
}

/**
 * @param {{ httpStatus?: number, message?: string } | null | undefined} error
 * @returns {{
 *   toast: string,
 *   toastTone: "error",
 *   forceStatus: "preparing" | null,
 *   canCancel: boolean
 * }}
 */
export function resolveCancelErrorResult(error) {
  const httpStatus = Number(error?.httpStatus || 0)
  const blocked = httpStatus === 422 || httpStatus >= 500

  if (blocked) {
    return {
      toast: CANCEL_BLOCKED_TOAST,
      toastTone: "error",
      forceStatus: "preparing",
      canCancel: false
    }
  }

  return {
    toast: error?.message || CANCEL_BLOCKED_TOAST,
    toastTone: "error",
    forceStatus: null,
    canCancel: true
  }
}
