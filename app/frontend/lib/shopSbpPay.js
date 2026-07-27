/**
 * SBP deep link: init → redirect на qr.nspk.ru + опции polling return (Шаг 9/11).
 */

export const SBP_LOADING_LABEL = "Оплата через СБП…"

export function sbpPollOptions() {
  return { intervalMs: 2000, maxAttempts: 30 }
}

export function mapSbpInitError(status, body = {}) {
  const msg = body?.error || body?.message
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
