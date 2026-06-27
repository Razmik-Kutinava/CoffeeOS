import {
  MODE_EXPANDED,
  MODE_HIDDEN,
  MODE_PEEK
} from "./cartSheetThresholds.js"
import {
  readShopLocalStorage,
  removeShopLocalStorage,
  writeShopLocalStorage
} from "./shopLocalStorage.js"

/** B1.13-S2b Q-rev4 — режим поп-апа при уходе с каталога */
export const CART_SHEET_MODE_KEY = "coffeeos_shop_cart_sheet_mode_v1"

const PERSISTABLE = new Set([MODE_PEEK, MODE_EXPANDED, MODE_HIDDEN])

export function readPersistedCartSheetMode() {
  const mode = readShopLocalStorage(CART_SHEET_MODE_KEY)
  return PERSISTABLE.has(mode) ? mode : null
}

export function writePersistedCartSheetMode(mode) {
  if (!PERSISTABLE.has(mode)) return
  writeShopLocalStorage(CART_SHEET_MODE_KEY, mode)
}

export function clearPersistedCartSheetMode() {
  removeShopLocalStorage(CART_SHEET_MODE_KEY)
}
