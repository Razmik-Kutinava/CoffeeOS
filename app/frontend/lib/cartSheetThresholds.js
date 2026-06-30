/** B1.13-S2b — пороги и высоты cart sheet (канон финальный) */

export const MODE_EMPTY = "empty"
export const MODE_EXPANDED = "expanded"
export const MODE_PEEK = "peek"
export const MODE_HIDDEN = "hidden"

export const SHEET_VH = {
  empty:         12,
  expandedSingle: 40,
  expandedMulti:  30,
  peekSingle:    28,
  peekMulti:     44,
  hidden:        20
}

/** Маркер сборки cart sheet — менять при каждом UX-фиксе для верификации на Fly */
export const CART_SHEET_BUILD = "prog15"

/** Суммарный скролл вниз от якоря: expanded → peek (1 item → hidden) */
export const SCROLL_TO_PEEK_PX = 100
/** Суммарный скролл вниз от якоря: → hidden */
export const SCROLL_TO_HIDDEN_PX = 200

/** Минимальный сдвиг пальца на gesture-zone для засчёта свайпа (px) */
export const SWIPE_UP_PX = 32

export const SHEET_TRANSITION_MS = 300
export const CART_SHEET_BOTTOM_REM = 3.5
export const CART_SHEET_MAX_WIDTH_PX = 414

export function sheetHeightVh(mode, itemCount = 0) {
  if (mode === MODE_EMPTY)    return SHEET_VH.empty
  if (mode === MODE_EXPANDED) return itemCount <= 1 ? SHEET_VH.expandedSingle : SHEET_VH.expandedMulti
  if (mode === MODE_PEEK)     return itemCount <= 1 ? SHEET_VH.peekSingle     : SHEET_VH.peekMulti
  if (mode === MODE_HIDDEN)   return SHEET_VH.hidden
  return SHEET_VH.empty
}
