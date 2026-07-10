/** Checkout payment sheet — пороги vh / анимация (отдельно от каталога CartSheet) */

export const MODE_PEEK = "peek"
export const MODE_EXPANDED = "expanded"
export const MODE_EXPANDED_PLUS = "expanded_plus"

/**
 * Peek ниже, чтобы форма регистрации (Отправить код / OTP) оставалась кликабельной (s01).
 * 1–2 товара — чуть выше (полные карточки s02/s03); ≥3 — миниатюры.
 */
export const SHEET_VH = {
  peek: 30,
  peekOne: 36,
  peekTwo: 40,
  expanded: 62,
  expandedPlus: 78
}

/** Анимация переходов ≤ 400 мс (ТЗ) */
export const SHEET_TRANSITION_MS = 400
export const SWIPE_UP_PX = 32

export const MAX_SAVED_CARDS = 10

export function sheetHeightVh(mode, itemCount = 0) {
  if (mode === MODE_EXPANDED_PLUS) return SHEET_VH.expandedPlus
  if (mode === MODE_EXPANDED) return SHEET_VH.expanded
  if (itemCount === 1) return SHEET_VH.peekOne
  if (itemCount === 2) return SHEET_VH.peekTwo
  return SHEET_VH.peek
}
