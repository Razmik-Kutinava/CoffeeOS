import { api, resolvedShopTenantId } from "../api.js"
import { applyOperatingHours } from "../shopOperatingHours.js"
import { writeShopLocalStorage } from "../shopLocalStorage.js"
import { catalogCacheKey } from "../shopWebView.js"

let inflight = null
let pollTimer = null
let visibilityHandler = null

/** Интервал автообновления меню на открытой витрине (планшет без F5). */
export const CATALOG_POLL_MS = 8_000

/** Кэш витрины не живёт бесконечно; reopen старше порога → skeleton + сеть. */
export const CATALOG_CACHE_MAX_AGE_MS = 30 * 60 * 1000

export function shouldShowCatalogSkeleton(cached) {
  return !Array.isArray(cached) || cached.length === 0
}

export function catalogRetryShowsSkeleton({ visibleCount } = {}) {
  return !(Number(visibleCount) > 0)
}

function catalogLsKey() {
  return catalogCacheKey(resolvedShopTenantId())
}

function readCatalogCache() {
  try {
    const raw = localStorage.getItem(catalogLsKey())
    if (!raw) return null
    const parsed = JSON.parse(raw)
    if (!parsed || typeof parsed !== "object" || parsed.savedAt == null || !("payload" in parsed)) {
      return null
    }
    const saved = Date.parse(parsed.savedAt)
    if (!Number.isFinite(saved) || Date.now() - saved > CATALOG_CACHE_MAX_AGE_MS) {
      return null
    }
    return Array.isArray(parsed.payload) ? parsed.payload : null
  } catch {
    return null
  }
}

function writeCatalogCache(categories) {
  writeShopLocalStorage(catalogLsKey(), categories)
}

/** SWR: UI рисует getCatalogCache() сразу; этот вызов — сеть + обновление кэша. */
export async function loadCatalog() {
  if (inflight) return inflight
  inflight = (async () => {
    try {
      const res = await api("/categories")
      const categories = Array.isArray(res) ? res : (res.data ?? [])
      if (res.meta?.operating_hours) applyOperatingHours(res.meta.operating_hours)
      writeCatalogCache(categories)
      return categories
    } catch (e) {
      let cached = null
      try {
        cached = readCatalogCache()
      } catch {
        cached = null
      }
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
