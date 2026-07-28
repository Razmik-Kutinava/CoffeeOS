/**
 * SBP deep link: init → redirect на qr.nspk.ru + опции polling return (Шаг 9/11).
 * CODE:BLACK lifecycle: checkOrderStatus + WAITING_FOR_BANK (ревизия 4.x / 5.2).
 */

import { clearPendingOrder } from "./codeblackPendingOrder.js"

export const SBP_LOADING_LABEL = "Оплата через СБП…"
export const SBP_INCOMPLETE_MESSAGE = "Оплата не завершена, попробовать снова"
export const SBP_WAITING_FOR_BANK_MESSAGE =
  "Завершите оплату в приложении банка и вернитесь в приложение"
export const SBP_I_PAID_LABEL = "Я оплатил"

const TERMINAL_PAYMENT_STATUSES = new Set(["CONFIRMED", "REJECTED", "CANCELED"])

const SBP_TERMINAL_STATUSES = new Set([
  "cancelled",
  "canceled",
  "rejected",
  "failed"
])

export function sbpPollOptions() {
  return { intervalMs: 2000, maxAttempts: 30 }
}

/** SuccessURL → success; Checkout completePaySuccess → ok. */
export function isSbpReturnSuccessStatus(status) {
  const s = String(status || "").toLowerCase()
  return s === "success" || s === "ok"
}

function isSbpTerminalFailure(res) {
  const status = String(res?.status || "").toLowerCase()
  if (SBP_TERMINAL_STATUSES.has(status)) return true
  const pay = String(res?.payment_status || "").toLowerCase()
  return SBP_TERMINAL_STATUSES.has(pay)
}

/**
 * Poll finalize после возврата из банка / NSPK (макс. 60с, шаг 2с).
 * Без бесконечного Loading: timeout / terminal → SBP_INCOMPLETE_MESSAGE.
 *
 * @param {(path: string, opts?: object) => Promise<object>} api
 * @param {{ orderId: string, sleep?: (ms: number) => Promise<void> }} params
 */
export async function pollSbpPaymentStatus(api, { orderId, sleep } = {}) {
  const { intervalMs, maxAttempts } = sbpPollOptions()
  const wait =
    sleep ||
    ((ms) =>
      new Promise((r) => {
        setTimeout(r, ms)
      }))

  for (let i = 0; i < maxAttempts; i += 1) {
    const res = await api(`/orders/${orderId}/finalize`, { method: "POST" })
    if (res?.payment_settled || res?.status === "accepted") return res
    if (isSbpTerminalFailure(res)) {
      throw Object.assign(new Error(SBP_INCOMPLETE_MESSAGE), { kind: "sbp_terminal" })
    }
    if (i < maxAttempts - 1) await wait(intervalMs)
  }

  throw Object.assign(new Error(SBP_INCOMPLETE_MESSAGE), { kind: "sbp_timeout" })
}

export function mapSbpInitError(status, body = {}) {
  const code = String(body?.error_code || "").trim()
  const msg = body?.error || body?.message
  if (code === "3001") {
    return "СБП сейчас недоступна для этой точки. Выберите оплату картой или попробуйте позже."
  }
  if (String(msg || "").match(/3001/) && String(msg || "").match(/сбп/i)) {
    return "СБП сейчас недоступна для этой точки. Выберите оплату картой или попробуйте позже."
  }
  if (msg && String(msg).trim()) return String(msg)
  if (status === 404) return "Заказ не найден"
  if (status === 400 || status === 422) return "Не удалось начать оплату СБП. Проверьте заказ."
  return "Ошибка оплаты СБП. Не удалось инициировать платёж."
}

/**
 * @param {(path: string, opts?: object) => Promise<object>} api
 * @param {{ orderId: string }} params
 * @returns {Promise<string>} payment_url
 */
export async function initSbpPayment(api, { orderId }) {
  try {
    const data = await api("/payments/sbp/init", {
      method: "POST",
      body: { order_id: orderId }
    })
    const url = data?.payment_url
    if (!url) throw Object.assign(new Error("Не получен payment_url"), { status: 500, body: {} })
    return url
  } catch (e) {
    const status = e.status ?? e.httpStatus
    const body = e.body ?? { error: e.message }
    throw new Error(mapSbpInitError(status, body))
  }
}

/**
 * Редирект только на *.nspk.ru (NSPK deep link).
 * @param {string} url
 * @param {(href: string) => void} [assignFn]
 */
export function redirectToSbp(url, assignFn) {
  const href = String(url || "").trim()
  let hostname = ""
  try {
    hostname = new URL(href).hostname
  } catch {
    throw new Error("Недопустимый URL СБП")
  }
  if (!hostname.endsWith("nspk.ru")) {
    throw new Error("Недопустимый URL: ожидается nspk.ru")
  }
  const go =
    assignFn ||
    ((u) => {
      window.location.assign(u)
    })
  go(href)
}

/**
 * Нормализация ответа GET /payments/status/:id → PENDING|CONFIRMED|REJECTED|CANCELED.
 * @param {{ status?: string }} body
 */
export function mapPaymentStatusPayload(body = {}) {
  const raw = String(body?.status || "").trim().toUpperCase()
  if (raw === "CANCELLED") return "CANCELED"
  if (raw === "PENDING" || raw === "CONFIRMED" || raw === "REJECTED" || raw === "CANCELED") {
    return raw
  }
  const lower = String(body?.status || "").toLowerCase()
  if (lower === "pending" || lower === "pending_payment" || lower === "processing") return "PENDING"
  if (lower === "accepted" || lower === "succeeded" || lower === "confirmed" || lower === "ok") {
    return "CONFIRMED"
  }
  if (lower === "failed" || lower === "rejected") return "REJECTED"
  if (lower === "cancelled" || lower === "canceled") return "CANCELED"
  return "PENDING"
}

/**
 * @param {(path: string, opts?: object) => Promise<object>} api
 * @param {{ orderId: string, storage?: Storage }} params
 * @returns {Promise<"PENDING"|"CONFIRMED"|"REJECTED"|"CANCELED">}
 */
export async function checkOrderStatus(api, { orderId, storage } = {}) {
  const id = String(orderId || "").trim()
  if (!id) throw new Error("Не указан orderId")
  const data = await api(`/payments/status/${id}`)
  const status = mapPaymentStatusPayload(data)
  if (TERMINAL_PAYMENT_STATUSES.has(status)) {
    clearPendingOrder({ storage })
  }
  return status
}
