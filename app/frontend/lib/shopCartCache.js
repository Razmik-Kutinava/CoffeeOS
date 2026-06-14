import {
  readShopLocalStorage,
  removeShopLocalStorage,
  writeShopLocalStorage
} from "./shopLocalStorage.js"

export const CART_CACHE_KEY = "coffeeos_shop_cart_v1"

export function readCartCache() {
  return readShopLocalStorage(CART_CACHE_KEY)
}

export function writeCartCache(data) {
  writeShopLocalStorage(CART_CACHE_KEY, data)
}

export function clearCartCache() {
  removeShopLocalStorage(CART_CACHE_KEY)
}
