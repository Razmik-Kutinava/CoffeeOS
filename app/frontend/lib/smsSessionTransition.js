/**
 * TASK_117 — подтверждение смены клиентской сессии по SMS-ссылке.
 * Pending token в query `sms_transition`; generation отсекает устаревшие ответы.
 */
import { clearSubscriptionOfferCtaCache } from "./subscriptionOfferCta.js"
import { pushRegisteredStorageKey } from "./orderStatusNotifyActions.js"

export const SMS_TRANSITION_TITLE = "Открыть заказ другого профиля?"
export const SMS_TRANSITION_CART_WARNING =
  "Корзина текущей точки будет очищена."
export const SMS_TRANSITION_CONFIRM_LABEL = "Открыть"
export const SMS_TRANSITION_DECLINE_LABEL = "Отмена"
export const SMS_TRANSITION_QUERY_KEY = "sms_transition"

let generation = 0
let busyToken = null

export function bumpSessionGeneration() {
  generation += 1
  busyToken = null
  return generation
}

export function currentSessionGeneration() {
  return generation
}

export function isStaleGeneration(g) {
  return g !== generation
}

export function smsTransitionBusy() {
  return busyToken != null
}

export function smsTransitionPending() {
  return busyToken != null
}

/** @returns {boolean} true если заняли слот */
export function beginSmsTransition(token) {
  if (busyToken != null) return false
  if (!token) return false
  busyToken = String(token)
  return true
}

export function endSmsTransition() {
  busyToken = null
}

export function parseSmsTransitionToken(search) {
  const raw = String(search || "")
  const q = raw.startsWith("?") ? raw.slice(1) : raw
  try {
    return new URLSearchParams(q).get(SMS_TRANSITION_QUERY_KEY)
  } catch {
    return null
  }
}

export function stripSmsTransitionFromSearch(search) {
  const raw = String(search || "")
  const hasQ = raw.startsWith("?")
  const q = hasQ ? raw.slice(1) : raw
  let params
  try {
    params = new URLSearchParams(q)
  } catch {
    return raw
  }
  params.delete(SMS_TRANSITION_QUERY_KEY)
  const body = params.toString()
  if (!body) return ""
  return hasQ || raw.length ? `?${body}` : body
}

export function profilePathAfterConfirm(orderId) {
  return `/profile?order=${encodeURIComponent(String(orderId || ""))}`
}

function defaultStorage() {
  try {
    return globalThis.localStorage ?? null
  } catch {
    return null
  }
}

/** R5 + сброс кэша оффера после подтверждённой смены клиента. */
export function clearClientCachesAfterSmsConfirm({ storage = defaultStorage() } = {}) {
  try {
    storage?.removeItem(pushRegisteredStorageKey())
  } catch {
    /* ignore */
  }
  clearSubscriptionOfferCtaCache()
}

/**
 * @param {string} token
 * @param {{ api: Function, generation?: number, storage?: Storage }} opts
 */
export async function confirmSmsTransition(token, opts = {}) {
  const { api, generation: g = currentSessionGeneration(), storage = defaultStorage() } = opts
  try {
    const body = await api("/session/sms_transition", {
      method: "POST",
      body: JSON.stringify({ token })
    })
    if (isStaleGeneration(g)) {
      return { ok: false, reason: "stale" }
    }
    if (!body?.ok) {
      return { ok: false, reason: "rejected" }
    }
    clearClientCachesAfterSmsConfirm({ storage })
    bumpSessionGeneration()
    endSmsTransition()
    return { ok: true, order_id: body.order_id }
  } catch {
    if (isStaleGeneration(g)) return { ok: false, reason: "stale" }
    return { ok: false, reason: "error" }
  }
}

/**
 * @param {string} token
 * @param {{ api: Function, storage?: Storage }} opts
 */
export async function declineSmsTransition(token, opts = {}) {
  const { api } = opts
  try {
    await api("/session/sms_transition", {
      method: "DELETE",
      body: JSON.stringify({ token })
    })
    endSmsTransition()
    return { ok: true }
  } catch {
    endSmsTransition()
    return { ok: false, reason: "error" }
  }
}
