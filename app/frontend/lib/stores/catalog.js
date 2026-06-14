import { api } from "../api.js"
import {
  readShopLocalStorage,
  writeShopLocalStorage
} from "../lib/shopLocalStorage.js"

let inflight = null
let pollTimer = null
let visibilityHandler = null

/** Интервал автообновления меню на открытой витрине (планшет без F5). */
export const CATALOG_POLL_MS = 8_000

const CATALOG_LS_KEY = "coffeeos_shop_catalog_v1"

function readCatalogCache() {
  const parsed = readShopLocalStorage(CATALOG_LS_KEY)
  return Array.isArray(parsed) ? parsed : null
}

function writeCatalogCache(categories) {
  writeShopLocalStorage(CATALOG_LS_KEY, categories)
}

/** Каждый заход на витрину — свежий каталог; polling подхватывает изменения из УК. */
export async function loadCatalog() {
  if (inflight) return inflight
  inflight = (async () => {
    try {
      const res = await api("/categories")
      const categories = Array.isArray(res) ? res : (res.data ?? [])
      writeCatalogCache(categories)
      return categories
    } catch (e) {
      const cached = readCatalogCache()
      if (cached?.length) return cached
      throw e
    } finally {
      inflight = null
    }
  })()
  return inflight
}

export function getCatalogCache() {
  return readCatalogCache()
}

/** Сброс in-flight перед принудительным refetch (polling / visibility). */
export function invalidateCatalog() {
  inflight = null
}

/**
 * Периодически подтягивает каталог с API (изменения УК → все открытые витрины).
 * @param {(categories: object[]) => void} onUpdate
 */
export function startCatalogPolling(onUpdate) {
  stopCatalogPolling()

  const tick = async () => {
    try {
      invalidateCatalog()
      const cats = await loadCatalog()
      onUpdate?.(cats)
    } catch {
      /* оставляем последний успешный каталог */
    }
  }

  pollTimer = setInterval(tick, CATALOG_POLL_MS)
  visibilityHandler = () => {
    if (document.visibilityState === "visible") tick()
  }
  document.addEventListener("visibilitychange", visibilityHandler)
}

export function stopCatalogPolling() {
  if (pollTimer) {
    clearInterval(pollTimer)
    pollTimer = null
  }
  if (visibilityHandler) {
    document.removeEventListener("visibilitychange", visibilityHandler)
    visibilityHandler = null
  }
}
