/** Локальный стейт invalid RebillId (не auth refresh). */

import { writable } from "svelte/store"

const INVALID_REBILL_PREFIX = "shop_invalid_rebill_"
const INVALID_ANY_KEY = "shop_invalid_rebill_active"
const SELECTION_KEY = "shop_repeat_payment_selection"
export const OPEN_PAYMENT_SHEET_KEY = "shop_open_payment_sheet"

/** @type {import('svelte/store').Writable<boolean>} */
export const invalidRebillActive = writable(false)

function storage() {
  try {
    return sessionStorage
  } catch (_e) {
    return null
  }
}

export function refreshInvalidRebillFlag() {
  invalidRebillActive.set(getIsTokenInvalid())
}

export function setTokenInvalid(cardId) {
  const s = storage()
  if (!s || !cardId) return
  s.setItem(`${INVALID_REBILL_PREFIX}${cardId}`, "1")
  s.setItem(INVALID_ANY_KEY, "1")
  refreshInvalidRebillFlag()
}

function canIterateStorage(s) {
  return typeof s.key === "function" && typeof s.length === "number"
}

function anyInvalidRebill(s) {
  if (canIterateStorage(s)) {
    for (let i = 0; i < s.length; i += 1) {
      const key = s.key(i)
      if (key?.startsWith(INVALID_REBILL_PREFIX) && key !== INVALID_ANY_KEY && s.getItem(key) === "1") {
        return true
      }
    }
    return false
  }
  return s.getItem(INVALID_ANY_KEY) === "1"
}

export function clearTokenInvalid(cardId) {
  const s = storage()
  if (!s) return
  if (cardId) {
    s.removeItem(`${INVALID_REBILL_PREFIX}${cardId}`)
    if (canIterateStorage(s)) {
      if (!anyInvalidRebill(s)) s.removeItem(INVALID_ANY_KEY)
    } else {
      s.removeItem(INVALID_ANY_KEY)
    }
  } else {
    for (let i = s.length - 1; i >= 0; i -= 1) {
      const key = s.key(i)
      if (key?.startsWith(INVALID_REBILL_PREFIX)) s.removeItem(key)
    }
    s.removeItem(INVALID_ANY_KEY)
  }
  refreshInvalidRebillFlag()
}

export function getIsTokenInvalid(cardId) {
  const s = storage()
  if (!s) return false
  if (cardId) return s.getItem(`${INVALID_REBILL_PREFIX}${cardId}`) === "1"
  return anyInvalidRebill(s)
}

export function persistPaymentSelection({ selectedCardId, selectionMode }) {
  const s = storage()
  if (!s) return
  s.setItem(
    SELECTION_KEY,
    JSON.stringify({
      selectedCardId: selectedCardId ?? null,
      selectionMode: selectionMode || "saved_card"
    })
  )
}

export function loadPaymentSelection() {
  const s = storage()
  if (!s) return { selectedCardId: null, selectionMode: "saved_card" }
  try {
    const raw = s.getItem(SELECTION_KEY)
    if (!raw) return { selectedCardId: null, selectionMode: "saved_card" }
    const parsed = JSON.parse(raw)
    return {
      selectedCardId: parsed?.selectedCardId ?? null,
      selectionMode: parsed?.selectionMode || "saved_card"
    }
  } catch (_e) {
    return { selectedCardId: null, selectionMode: "saved_card" }
  }
}

export function shouldShowAddCardCta({ isTokenInvalid, hasRepeatContext, cartItemCount }) {
  return !!isTokenInvalid && !!hasRepeatContext && Number(cartItemCount) > 0
}

export function mapPaymentErrorSurface({ httpStatus, phase }) {
  void httpStatus
  if (phase === "pay") return "inline"
  return "toast"
}

const INVALID_REBILL_CODES = new Set([
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
  "1078"
])

export function isInvalidRebillPaymentError({ error_code, httpStatus }) {
  const status = Number(httpStatus || 0)
  if (status >= 500) return false
  if (status === 200 && String(error_code || "") === "0") return false
  const code = String(error_code || "").trim()
  return !!(code && INVALID_REBILL_CODES.has(code))
}

export function markOpenPaymentSheet() {
  storage()?.setItem(OPEN_PAYMENT_SHEET_KEY, "1")
}

export function consumeOpenPaymentSheet() {
  const s = storage()
  if (!s) return false
  const flag = s.getItem(OPEN_PAYMENT_SHEET_KEY) === "1"
  if (flag) s.removeItem(OPEN_PAYMENT_SHEET_KEY)
  return flag
}
