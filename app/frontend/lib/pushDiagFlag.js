/**
 * TASK_108 — флаг пошаговой диагностики registerShopPush (проверки на устройствах).
 * По умолчанию выключен; переключается скрытым жестом на экране заказа.
 *
 * iOS (#99): чтение синхронное — флаг читается до `Notification.requestPermission()`.
 */

export const PUSH_DIAG_STORAGE_KEY = "coffeeos_push_diag_v1"

/** Решение владельца 2026-10-29: 7 нажатий за 3 с на заголовок «Заказ». */
export const PUSH_DIAG_GESTURE = Object.freeze({ taps: 7, windowMs: 3000 })

/** Значение на время жизни страницы, если localStorage недоступен. */
let memoryValue = false

function resolveStorage(opts) {
  if (opts && Object.prototype.hasOwnProperty.call(opts, "storage")) return opts.storage
  try {
    return globalThis.localStorage ?? null
  } catch {
    return null
  }
}

/**
 * @param {{ storage?: Storage|null }} [opts]
 * @returns {boolean}
 */
export function isPushDiagEnabled(opts) {
  try {
    const value = resolveStorage(opts)?.getItem(PUSH_DIAG_STORAGE_KEY)
    if (value === "1") return true
    if (value === "0") return false
  } catch {
    /* storage недоступен — значение из памяти */
  }
  return memoryValue
}

/**
 * @param {boolean} on
 * @param {{ storage?: Storage|null }} [opts]
 */
export function setPushDiagEnabled(on, opts) {
  memoryValue = Boolean(on)
  try {
    resolveStorage(opts)?.setItem(PUSH_DIAG_STORAGE_KEY, memoryValue ? "1" : "0")
  } catch {
    /* storage недоступен — флаг живёт до закрытия страницы */
  }
}

/**
 * @param {{ storage?: Storage|null }} [opts]
 * @returns {boolean} новое значение
 */
export function togglePushDiag(opts) {
  const next = !isPushDiagEnabled(opts)
  setPushDiagEnabled(next, opts)
  return next
}

export function pushDiagToggleText(on) {
  return on ? "Диагностика уведомлений включена" : "Диагностика уведомлений выключена"
}

/**
 * Счётчик серии нажатий: `tap()` → true на `taps`-м нажатии в окне `windowMs`.
 *
 * @param {{ taps?: number, windowMs?: number, now?: () => number }} [opts]
 */
export function createTapGesture(opts = {}) {
  const taps = opts.taps ?? PUSH_DIAG_GESTURE.taps
  const windowMs = opts.windowMs ?? PUSH_DIAG_GESTURE.windowMs
  const now = opts.now ?? (() => Date.now())
  let stamps = []
  return {
    tap() {
      const t = now()
      stamps = stamps.filter((s) => t - s < windowMs)
      stamps.push(t)
      if (stamps.length < taps) return false
      stamps = []
      return true
    }
  }
}
