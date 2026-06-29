/** B1.13-S2b rev2 — пороги скролла каталога (Q-rev3, от якоря) */

export const MODE_EMPTY = "empty"
export const MODE_EXPANDED = "expanded"
export const MODE_PEEK = "peek"
export const MODE_HIDDEN = "hidden"

export const EXPANDED_LAYOUT_VERTICAL = "vertical"
export const EXPANDED_LAYOUT_HORIZONTAL = "horizontal"

export const SHEET_VH = {
  empty: 12,
  expanded: 42,
  expandedMulti: 38,
  expandedMultiHorizontal: 44,
  peek: 18,
  hidden: 14
}

/** Суммарный скролл вниз от якоря: expanded → peek */
export const SCROLL_TO_PEEK_PX = 60
/** Суммарный скролл вниз от якоря: → hidden (чип) */
export const SCROLL_TO_HIDDEN_PX = 130

/** Минимальный сдвиг пальца на gesture-zone (px) */
export const SWIPE_UP_PX = 32

/** B1.13-S2a — анимация перехода между состояниями */
export const SHEET_TRANSITION_MS = 300

/** B1.13-S2a — поп-ап над bottom bar (совпадает с высотой BottomNav) */
export const CART_SHEET_BOTTOM_REM = 3.5

/** B1.13-S2a — адаптация viewport 320–414px */
export const CART_SHEET_MAX_WIDTH_PX = 414

export function sheetHeightVh(mode, itemCount = 0, expandedLayout = EXPANDED_LAYOUT_VERTICAL) {
  if (mode === MODE_EMPTY) return SHEET_VH.empty
  if (mode === MODE_EXPANDED) {
    if (itemCount <= 1) return SHEET_VH.expanded
    if (expandedLayout === EXPANDED_LAYOUT_HORIZONTAL) return SHEET_VH.expandedMultiHorizontal
    return SHEET_VH.expandedMulti
  }
  if (mode === MODE_PEEK) return SHEET_VH.peek
  if (mode === MODE_HIDDEN) return SHEET_VH.hidden
  return SHEET_VH.empty
}
