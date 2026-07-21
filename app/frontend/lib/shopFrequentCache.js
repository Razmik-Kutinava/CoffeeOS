import {
  readShopLocalStorage,
  removeShopLocalStorage,
  writeShopLocalStorage
} from "./shopLocalStorage.js"

/** Кэш секции «повторить» (Quick Repeat) — паттерн shopCartCache.js */
export const FREQUENT_CACHE_KEY = "coffeeos_shop_frequent_v1"
/** Счётчики карточек повтора — отдельный ключ: refresh данных их не затирает */
export const FREQUENT_QTY_KEY = "coffeeos_shop_frequent_qty_v1"

export function readFrequentCache() {
  return readShopLocalStorage(FREQUENT_CACHE_KEY)
}

export function writeFrequentCache(data) {
  writeShopLocalStorage(FREQUENT_CACHE_KEY, data)
}

export function readFrequentQty() {
  return readShopLocalStorage(FREQUENT_QTY_KEY)
}

export function writeFrequentQty(quantities) {
  writeShopLocalStorage(FREQUENT_QTY_KEY, quantities)
}

export function clearFrequentCache() {
  removeShopLocalStorage(FREQUENT_CACHE_KEY)
}
