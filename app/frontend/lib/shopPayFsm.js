/** FSM кнопки «Оплатить» (состояния 0–7) — UserCards / nonPCI. */

import { isOfflineError } from "./shopNetwork.js"

export const PAY_FSM = {
  DEFAULT: 0,
  CONNECTING: 1,
  PROCESSING: 2,
  THREE_DS: 3,
  SUCCESS: 4,
  CLIENT_ERROR: 5,
  BANK_ERROR: 6,
  NET_ERROR: 7
}

export const MIN_LOADER_MS = 600
export const NET_TIMEOUT_MS = 10_000
export const SUCCESS_REDIRECT_MS = 1500

export const PAY_FSM_LABELS = {
  [PAY_FSM.DEFAULT]: "Оплатить",
  [PAY_FSM.CONNECTING]: "Установка соединения…",
  [PAY_FSM.PROCESSING]: "Обработка банком…",
  [PAY_FSM.THREE_DS]: "Подтвердите по СМС",
  [PAY_FSM.SUCCESS]: "Оплачено ✔",
  [PAY_FSM.CLIENT_ERROR]:
    "Недостаточно средств, или карта заблокирована банком, или истёк срок действия карты",
  [PAY_FSM.BANK_ERROR]: "Сбой банка: позже",
  [PAY_FSM.NET_ERROR]: "Нет связи. Повторить"
}

/** Коды Т-Банка: отказ по карте → State 5 Client Error. */
const CLIENT_ERROR_CODES = new Set([
  "1005",
  "1013",
  "1014",
  "1041",
  "1051",
  "1053",
  "1054",
  "1057",
  "1061",
  "1062",
  "1078",
  // #46: лимит запросов авторизации — сменить карту, не blind retry.
  "119",
  "2200"
])

export function payFsmLabel(state) {
  return PAY_FSM_LABELS[state] || PAY_FSM_LABELS[PAY_FSM.DEFAULT]
}

export function isPayFsmBusy(state) {
  return (
    state === PAY_FSM.CONNECTING ||
    state === PAY_FSM.PROCESSING ||
    state === PAY_FSM.THREE_DS ||
    state === PAY_FSM.SUCCESS
  )
}

export function isPayFsmClickable(state) {
  return (
    state === PAY_FSM.DEFAULT ||
    state === PAY_FSM.CLIENT_ERROR ||
    state === PAY_FSM.BANK_ERROR ||
    state === PAY_FSM.NET_ERROR
  )
}

export function shouldLockPaymentMethods(state) {
  return isPayFsmBusy(state)
}

/**
 * G7: действие CTA по FSM.
 * CLIENT_ERROR (сообщение про карту) → открыть NewCardForm, не retry той же карты.
 */
export function resolvePayFsmCtaAction(state) {
  if (state === PAY_FSM.CLIENT_ERROR) return "open_new_card"
  if (state === PAY_FSM.NET_ERROR || state === PAY_FSM.BANK_ERROR) return "retry"
  return "pay"
}

/** D4=C: при входе в CLIENT_ERROR сразу открываем форму новой карты. */
export function shouldAutoOpenNewCardOnClientError(state) {
  return state === PAY_FSM.CLIENT_ERROR
}

/** ErrorCode / HTTP / сеть → FSM 5–7. */
export function fsmFromPaymentError(error, { httpStatus } = {}) {
  if (typeof navigator !== "undefined" && (!navigator.onLine || isOfflineError(error))) {
    return PAY_FSM.NET_ERROR
  }

  const msg = String(error?.message || error || "").toLowerCase()
  if (/timeout|timed out|abort/i.test(msg)) return PAY_FSM.NET_ERROR
  if (/failed to fetch|network|offline|load failed|err_network/i.test(msg)) {
    return PAY_FSM.NET_ERROR
  }

  const status = Number(httpStatus || error?.httpStatus || 0)
  if (status >= 500) return PAY_FSM.BANK_ERROR

  const code = String(error?.error_code || "").trim()
  if (code && CLIENT_ERROR_CODES.has(code)) return PAY_FSM.CLIENT_ERROR

  if (/истёк|истек|expir|недостаточно|средств|заблокирован|блокир|отклон|лимит|запросов авторизац|cvv|cvc|карт/i.test(msg)) {
    return PAY_FSM.CLIENT_ERROR
  }
  if (/сеть|network|offline|повторить/i.test(msg)) return PAY_FSM.NET_ERROR
  if (/сервер|шлюз|банк|инфра|позже|недоступн/i.test(msg)) return PAY_FSM.BANK_ERROR

  return PAY_FSM.BANK_ERROR
}

/** Anti-flicker: удерживаем Connecting/Processing минимум ms. */
export async function withMinLoaderMs(ms, fn) {
  const started = Date.now()
  const result = await fn()
  const elapsed = Date.now() - started
  if (elapsed < ms) {
    await new Promise((resolve) => setTimeout(resolve, ms - elapsed))
  }
  return result
}

export async function apiWithPayTimeout(api, path, opts = {}, timeoutMs = NET_TIMEOUT_MS) {
  let timer
  try {
    return await Promise.race([
      api(path, opts),
      new Promise((_, reject) => {
        timer = setTimeout(() => {
          const err = new Error("timeout")
          err.kind = "timeout"
          reject(err)
        }, timeoutMs)
      })
    ])
  } finally {
    clearTimeout(timer)
  }
}
