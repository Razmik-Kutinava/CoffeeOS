import {
  readShopLocalStorage,
  removeShopLocalStorage,
  writeShopLocalStorage
} from "./shopLocalStorage.js"

/** Кэш секции «повторить» (Quick Repeat) — паттерн shopCartCache.js */
export const FREQUENT_CACHE_KEY = "coffeeos_shop_frequent_v1"

export function readFrequentCache() {
  return readShopLocalStorage(FREQUENT_CACHE_KEY)
}

export function writeFrequentCache(data) {
  writeShopLocalStorage(FREQUENT_CACHE_KEY, data)
}

export function clearFrequentCache() {
  removeShopLocalStorage(FREQUENT_CACHE_KEY)
}
