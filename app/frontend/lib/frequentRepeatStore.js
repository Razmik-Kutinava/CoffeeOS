import { writable } from "svelte/store"
import { api } from "./api.js"
import { readFrequentCache, writeFrequentCache } from "./shopFrequentCache.js"

/** Секция «повторить»: 1–3 частых товара клиента (GET /shop/api/frequent_products) */
export const frequentItems = writable([])
/** Каталог по категориям для expanded-режима шторки */
export const frequentCategories = writable({})
/** true после первой инициализации (из кэша или сети) */
export const frequentLoaded = writable(false)

/**
 * Мгновенный старт из localStorage (< 50 мс, без сети) — вызывать при
 * открытии шторки; фоновую актуализацию запускать отдельно.
 */
export function initFrequentFromCache() {
  const cached = readFrequentCache()
  if (cached && Array.isArray(cached.frequent_items)) {
    frequentItems.set(cached.frequent_items)
  }
  if (cached && cached.categories && typeof cached.categories === "object") {
    frequentCategories.set(cached.categories)
  }
  frequentLoaded.set(true)
  return cached
}

/** Фоновый GET: успех — перезапись stores и кэша; offline/500 — кэш остаётся, UI не блокируем */
export async function refreshFrequentProducts() {
  try {
    const data = await api("/frequent_products")
    frequentItems.set(data?.frequent_items || [])
    frequentCategories.set(data?.categories || {})
    writeFrequentCache(data)
    frequentLoaded.set(true)
    return data
  } catch (_e) {
    // Ошибка сети: закешированные данные уже в stores — ничего не чистим
    return null
  }
}
