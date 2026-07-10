/** Checkout payment sheet — пороги vh / анимация (отдельно от каталога CartSheet) */

export const MODE_PEEK = "peek"
export const MODE_EXPANDED = "expanded"
export const MODE_EXPANDED_PLUS = "expanded_plus"

export const SHEET_VH = {
  peek: 42,
  expanded: 62,
  expandedPlus: 78
}

/** Анимация переходов ≤ 400 мс (ТЗ) */
export const SHEET_TRANSITION_MS = 400
export const SWIPE_UP_PX = 32

export const MAX_SAVED_CARDS = 10

export function sheetHeightVh(mode) {
  if (mode === MODE_EXPANDED_PLUS) return SHEET_VH.expandedPlus
  if (mode === MODE_EXPANDED) return SHEET_VH.expanded
  return SHEET_VH.peek
}
