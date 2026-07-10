/** Checkout payment sheet — пороги vh / анимация (отдельно от каталога CartSheet) */

export const MODE_PEEK = "peek"
export const MODE_EXPANDED = "expanded"
export const MODE_EXPANDED_PLUS = "expanded_plus"

export const SUBVIEW_PAYMENT_LIST = "payment_list"
export const SUBVIEW_CARD_FORM = "card_form"
export const SUBVIEW_THREE_DS = "three_ds"

export const SHEET_VH = {
  peek: 42,
  expanded: 62,
  expandedPlus: 78,
  cardForm: 85,
  threeDs: 92
}

/** Анимация переходов ≤ 400 мс (ТЗ) */
export const SHEET_TRANSITION_MS = 400
export const SWIPE_UP_PX = 32

export const MAX_SAVED_CARDS = 10

export function sheetHeightVh(mode, subView = SUBVIEW_PAYMENT_LIST) {
  if (mode === MODE_EXPANDED_PLUS) {
    if (subView === SUBVIEW_CARD_FORM) return SHEET_VH.cardForm
    if (subView === SUBVIEW_THREE_DS) return SHEET_VH.threeDs
    return SHEET_VH.expandedPlus
  }
  if (mode === MODE_EXPANDED) return SHEET_VH.expanded
  return SHEET_VH.peek
}
