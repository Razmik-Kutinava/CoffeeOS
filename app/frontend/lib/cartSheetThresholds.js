/** B1.13-S2: пороги из макетов b113_s2_customer_* */

export const MODE_EMPTY = "empty"
export const MODE_EXPANDED = "expanded"
export const MODE_PEEK = "peek"
export const MODE_HIDDEN = "hidden"

export const SHEET_VH = {
  empty: 12,
  expanded: 40,
  expandedMulti: 36,
  peek: 16,
  hidden: 9
}

export const SCROLL_TO_PEEK_VH = 0.12
export const SCROLL_TO_HIDDEN_VH = 0.1
export const SCROLL_TO_PEEK_PX = 80
export const SCROLL_TO_HIDDEN_PX = 80

export const SWIPE_UP_PX = 48

export function sheetHeightVh(mode, itemCount = 0) {
  if (mode === MODE_EMPTY) return SHEET_VH.empty
  if (mode === MODE_EXPANDED) {
    return itemCount > 1 ? SHEET_VH.expandedMulti : SHEET_VH.expanded
  }
  if (mode === MODE_PEEK) return SHEET_VH.peek
  if (mode === MODE_HIDDEN) return SHEET_VH.hidden
  return SHEET_VH.empty
}
