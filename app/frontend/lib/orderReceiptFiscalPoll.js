/**
 * #73 Патч 1 — live-refresh секции ОФД на `#/order/:id/receipt`.
 * Poll только пока «Чек формируется»; не трогает OrderStatusSheet / receiptView.
 */

export const ORDER_RECEIPT_FISCAL_POLL_MS = 5_000

/**
 * @param {any} order
 * @returns {boolean}
 */
export function shouldKeepPollingFiscal(order) {
  if (!order?.payment_settled || !order?.fiscal_expected) return false
  if (order.status === "cancelled") return false

  const receipts = Array.isArray(order.fiscal_receipts) ? order.fiscal_receipts : []
  const hasVisible = receipts.some(
    (r) =>
      Boolean(r?.url) ||
      Boolean(r?.fn_number || r?.fiscal_document_number || r?.fiscal_document_attribute)
  )
  return !hasVisible
}
