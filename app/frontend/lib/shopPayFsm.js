/** FSM кнопки «Оплатить» (состояния 0–7) — UserCards / nonPCI. */

import { isOfflineError } from "./shopNetwork.js"
import {
  ctaChangeCard,
  ctaRetryPayment,
  ctaTryLater,
  payErrorCardDeclined,
  payErrorCardExpired,
  payErrorInsufficientFunds,
  payErrorPaymentFailed,
  payErrorTooManyAttempts
} from "./paymentMethodI18n.js"

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
  [PAY_FSM.CLIENT_ERROR]: ctaChangeCard(),
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

/**
 * #26 step5: не auto-open NewCardForm при CLIENT_ERROR —
 * иначе стираются selection + inline. CTA click → open_new_card.
 */
export function shouldAutoOpenNewCardOnClientError(_state) {
  return false
}

/** TASK_100 Матрица: категории ошибки оплаты. */
export const PAY_ERROR_CATEGORY = {
  INSUFFICIENT_FUNDS: "insufficient_funds",
  CARD_EXPIRED: "card_expired",
  TOO_MANY_ATTEMPTS: "too_many_attempts",
  CARD_DECLINED: "card_declined",
  PAYMENT_FAILED: "payment_failed"
}

const TOO_MANY_ATTEMPTS_CODES = new Set(["119", "2200"])
const BANK_MESSAGE_RE = /сервер|шлюз|банк|инфра|позже|недоступн/i

/**
 * Категория Матрицы TASK_100. null — сеть / 5xx / сбой банка (вне Матрицы, тексты FSM как были).
 * Неизвестный код без карточной семантики → PAYMENT_FAILED, не карта.
 */
export function classifyPaymentError(error, { httpStatus } = {}) {
  if (error?.kind === "three_ds_abort") return PAY_ERROR_CATEGORY.PAYMENT_FAILED

  const fsm = fsmFromPaymentError(error, { httpStatus })
  if (fsm === PAY_FSM.NET_ERROR) return null

  const code = String(error?.error_code || "").trim()
  if (code === "1051") return PAY_ERROR_CATEGORY.INSUFFICIENT_FUNDS
  if (code === "1014") return PAY_ERROR_CATEGORY.CARD_EXPIRED
  if (TOO_MANY_ATTEMPTS_CODES.has(code)) return PAY_ERROR_CATEGORY.TOO_MANY_ATTEMPTS
  if (fsm === PAY_FSM.CLIENT_ERROR) return PAY_ERROR_CATEGORY.CARD_DECLINED

  const status = Number(httpStatus || error?.httpStatus || 0)
  if (status >= 500) return null
  if (BANK_MESSAGE_RE.test(String(error?.message || error || ""))) return null

  return PAY_ERROR_CATEGORY.PAYMENT_FAILED
}

/**
 * Текст ошибки и CTA — раздельно (alert ≠ кнопка).
 * @returns {{ message: string, cta: { label: string, action: "change_card"|"close"|"retry" } }|null}
 */
export function resolvePaymentErrorUi(category) {
  switch (category) {
    case PAY_ERROR_CATEGORY.INSUFFICIENT_FUNDS:
      return { message: payErrorInsufficientFunds(), cta: { label: ctaChangeCard(), action: "change_card" } }
    case PAY_ERROR_CATEGORY.CARD_EXPIRED:
      return { message: payErrorCardExpired(), cta: { label: ctaChangeCard(), action: "change_card" } }
    case PAY_ERROR_CATEGORY.TOO_MANY_ATTEMPTS:
      return { message: payErrorTooManyAttempts(), cta: { label: ctaTryLater(), action: "close" } }
    case PAY_ERROR_CATEGORY.CARD_DECLINED:
      return { message: payErrorCardDeclined(), cta: { label: ctaChangeCard(), action: "change_card" } }
    case PAY_ERROR_CATEGORY.PAYMENT_FAILED:
      return { message: payErrorPaymentFailed(), cta: { label: ctaRetryPayment(), action: "retry" } }
    default:
      return null
  }
}

/**
 * Текст в PaymentMethodsSheet (alert) при отказе оплаты.
 * Friendly copy; сырой `Failed to fetch` / ErrorCode не кладём.
 * @param {{ message?: string }|Error|null} error
 * @param {number} fsmState
 * @param {string|null} [category] — явная категория (3DS abort); иначе из error
 * @returns {string|null}
 */
export function resolveCheckoutSheetInlineError(error, fsmState, category = undefined) {
  if (
    fsmState !== PAY_FSM.NET_ERROR &&
    fsmState !== PAY_FSM.CLIENT_ERROR &&
    fsmState !== PAY_FSM.BANK_ERROR
  ) {
    return null
  }
  let cat = category === undefined ? classifyPaymentError(error) : category
  if (!cat && fsmState === PAY_FSM.CLIENT_ERROR) cat = PAY_ERROR_CATEGORY.CARD_DECLINED
  const ui = resolvePaymentErrorUi(cat)
  return ui ? ui.message : payFsmLabel(fsmState)
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
  if (BANK_MESSAGE_RE.test(msg)) return PAY_FSM.BANK_ERROR

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
