/** B1.13-S2b — пороги и высоты cart sheet (канон: карточки −15%, hidden = чипы) */

export const MODE_EMPTY = "empty"
export const MODE_EXPANDED = "expanded"
export const MODE_PEEK = "peek"
export const MODE_HIDDEN = "hidden"

/**
 * Высоты под сетку каталога (карточки ~8.5rem):
 * expanded — верх шторки у 1-го ряда; peek — середина 2-го ряда; hidden — ниже, ряд чипов.
 */
export const SHEET_VH = {
  empty:         12,
  expandedSingle: 52,
  expandedMulti:  56,
  peekSingle:    34,
  peekMulti:     38,
  /** Peek с секцией «повторить» внутри одной шторки (скрины 01–02) */
  peekSingleWithRepeat: 46,
  peekMultiWithRepeat:  50,
  hidden:        24
}

/** Маркер сборки cart sheet — менять при каждом UX-фиксе для верификации на Fly */
export const CART_SHEET_BUILD = "prog32"

/** Высота единой шторки checkout: peek корзины + PaymentMethodsSheet (Фаза 2 UX) */
export const CHECKOUT_PAY_STACK_VH = 92
/** Высота peek-полосы в stacked checkout (vh) */
export const CHECKOUT_PEEK_VH = 15
/** @deprecated use CHECKOUT_PEEK_VH — CSS var legacy rem fallback */
export const CHECKOUT_PEEK_REM = 7.5

/** Суммарный скролл вниз от якоря: expanded → peek (1 item → hidden) */
export const SCROLL_TO_PEEK_PX = 100
/** Суммарный скролл вниз от якоря: → hidden */
export const SCROLL_TO_HIDDEN_PX = 200

/** Минимальный сдвиг пальца на gesture-zone для засчёта свайпа (px); 20 — чувствительнее (заказчик 2026-07-23) */
export const SWIPE_UP_PX = 20

export const SHEET_TRANSITION_MS = 300
/** 0 — прижать к низу экрана (бар навигации убран B1.13-CR; 3.5rem оставлял «воздух») */
export const CART_SHEET_BOTTOM_REM = 0
export const CART_SHEET_MAX_WIDTH_PX = 414

export function sheetHeightVh(mode, itemCount = 0) {
  if (mode === MODE_EMPTY)    return SHEET_VH.empty
  if (mode === MODE_EXPANDED) return itemCount <= 1 ? SHEET_VH.expandedSingle : SHEET_VH.expandedMulti
  if (mode === MODE_PEEK)     return itemCount <= 1 ? SHEET_VH.peekSingle     : SHEET_VH.peekMulti
  if (mode === MODE_HIDDEN)   return SHEET_VH.hidden
  return SHEET_VH.empty
}
