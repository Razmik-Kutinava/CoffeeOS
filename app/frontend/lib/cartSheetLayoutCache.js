import {
  EXPANDED_LAYOUT_HORIZONTAL,
  EXPANDED_LAYOUT_VERTICAL
} from "./cartSheetThresholds.js"
import {
  readShopLocalStorage,
  removeShopLocalStorage,
  writeShopLocalStorage
} from "./shopLocalStorage.js"

/** B1.13-S2b прогон 5 — раскладка expanded (vertical | horizontal) */
export const CART_SHEET_LAYOUT_KEY = "coffeeos_shop_cart_sheet_layout_v1"

const PERSISTABLE = new Set([EXPANDED_LAYOUT_VERTICAL, EXPANDED_LAYOUT_HORIZONTAL])

export function readPersistedCartSheetLayout() {
  const layout = readShopLocalStorage(CART_SHEET_LAYOUT_KEY)
  return PERSISTABLE.has(layout) ? layout : null
}

export function writePersistedCartSheetLayout(layout) {
  if (!PERSISTABLE.has(layout)) return
  writeShopLocalStorage(CART_SHEET_LAYOUT_KEY, layout)
}

export function clearPersistedCartSheetLayout() {
  removeShopLocalStorage(CART_SHEET_LAYOUT_KEY)
}
