/**
 * #40 — copy/format для отмены заказа гостем (модалка accepted).
 */

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
