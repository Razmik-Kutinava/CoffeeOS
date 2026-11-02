/**
 * TASK_121: превью цен перед повтором заказа из истории.
 */
import { writable, get } from "svelte/store"

export const HISTORY_REPEAT_PRICES_CHANGED_TEXT =
  "Повторить заказ нельзя: цены изменились"
export const HISTORY_REPEAT_PROMO_TEXT =
  "Повторить заказ нельзя: он был оформлен по акции"
export const HISTORY_REPEAT_UNAVAILABLE_TEXT =
  "Повторить заказ нельзя: некоторых позиций нет в этой точке"
export const HISTORY_REPEAT_PREVIEW_FAILED_TEXT =
  "Не удалось проверить цены. Попробуйте ещё раз."

export const HISTORY_REPEAT_BLOCK_REASONS = {
  prices: "prices",
  promo: "promo",
  unavailable: "unavailable"
}

const BLOCK_TEXT = {
  [HISTORY_REPEAT_BLOCK_REASONS.prices]: HISTORY_REPEAT_PRICES_CHANGED_TEXT,
  [HISTORY_REPEAT_BLOCK_REASONS.promo]: HISTORY_REPEAT_PROMO_TEXT,
  [HISTORY_REPEAT_BLOCK_REASONS.unavailable]: HISTORY_REPEAT_UNAVAILABLE_TEXT
}

export function historyRepeatBlockText(reason) {
  return BLOCK_TEXT[reason] || HISTORY_REPEAT_PRICES_CHANGED_TEXT
}

export const historyRepeatNotice = writable(/** @type {{ reason: string, text: string } | null} */ (null))

export function showHistoryRepeatNotice(reason) {
  historyRepeatNotice.set({ reason, text: historyRepeatBlockText(reason) })
}

export function dismissHistoryRepeatNotice() {
  historyRepeatNotice.set(null)
}

export function repeatPreviewPath(orderId) {
  return `/orders/${encodeURIComponent(String(orderId))}/repeat_preview`
}

export async function fetchRepeatPreview(order, { api }) {
  return api(repeatPreviewPath(order.id))
}

function cents(value) {
  const n = Number(value)
  if (!Number.isFinite(n)) throw new Error("invalid preview")
  return Math.round(n * 100)
}

function validatePreview(preview) {
  if (!preview || !Array.isArray(preview.items) || preview.items.length === 0) {
    throw new Error("invalid preview")
  }
  cents(preview.total)
  cents(preview.previous_total)
  cents(preview.previous_discount ?? 0)
}

/**
 * @returns {{ ok: true } | { ok: false, reason: string }}
 */
export function compareRepeatPreview(preview) {
  validatePreview(preview)
  const items = preview.items

  if (items.some((line) => line.unavailable)) {
    return { ok: false, reason: HISTORY_REPEAT_BLOCK_REASONS.unavailable }
  }

  const oldLinesSum = items.reduce(
    (sum, line) => sum + cents(line.price) * Number(line.quantity || 0),
    0
  )
  const previousTotal = cents(preview.previous_total)
  const previousDiscount = cents(preview.previous_discount ?? 0)

  if (previousDiscount > 0 || previousTotal < oldLinesSum) {
    return { ok: false, reason: HISTORY_REPEAT_BLOCK_REASONS.promo }
  }

  for (const line of items) {
    if (cents(line.unit_total) !== cents(line.price)) {
      return { ok: false, reason: HISTORY_REPEAT_BLOCK_REASONS.prices }
    }
  }

  if (cents(preview.total) !== previousTotal) {
    return { ok: false, reason: HISTORY_REPEAT_BLOCK_REASONS.prices }
  }

  return { ok: true }
}

/** @deprecated use get(historyRepeatNotice) in tests */
export function __readHistoryRepeatNoticeForTests() {
  return get(historyRepeatNotice)
}
