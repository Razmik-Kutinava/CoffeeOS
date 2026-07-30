/**
 * Widget inline pay: «оплатить в клик» → POST widget_init → poll status → result (#33 Шаг 4).
 */
import { api } from "./api.js"

export const WIDGET_STATUS_LABELS = {
  PROCESSING: "статусы от банка",
  SUCCESS: "Оплачено!",
  ERROR: "Ошибка оплаты"
}

export const WIDGET_POLL_MS = 2000
export const WIDGET_POLL_MAX = 15

/**
 * @param {string} orderId
 * @param {{ cardId?: string }} [opts] — id сохранённой карты → RebillId на бэке
 */
export async function widgetInitPayment(orderId, { cardId } = {}) {
  const body = { order_id: orderId }
  if (cardId) body.card_id = cardId
  const data = await api("/payments/widget_init", {
    method: "POST",
    body: JSON.stringify(body)
  })
  return data
}

export async function widgetPollStatus(orderId, { maxAttempts = WIDGET_POLL_MAX, intervalMs = WIDGET_POLL_MS } = {}) {
  for (let i = 0; i < maxAttempts; i++) {
    const data = await api(`/payments/status/${orderId}`)
    const s = String(data?.status || "").toUpperCase()
    if (s === "CONFIRMED" || s === "REJECTED" || s === "CANCELED") {
      return { ...data, status: s }
    }
    await new Promise(r => setTimeout(r, intervalMs))
  }
  return { status: "TIMEOUT" }
}

export function isCardRelatedError(data) {
  const code = String(data?.error_code || "")
  const cardCodes = new Set([
    "1051", "1005", "1006", "1012", "1014", "1030", "1034",
    "1041", "1043", "1054", "1057", "1058", "1059",
    "1062", "1063", "1065", "1082", "1089", "1091", "1096"
  ])
  return cardCodes.has(code)
}
