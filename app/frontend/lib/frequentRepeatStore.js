import { writable } from "svelte/store"
import { api } from "./api.js"
import {
  readFrequentCache,
  writeFrequentCache,
  readFrequentQty,
  writeFrequentQty
} from "./shopFrequentCache.js"

/** Секция «повторить»: 1–3 частых товара клиента (GET /shop/api/frequent_products) */
export const frequentItems = writable([])
/** Каталог по категориям для expanded-режима шторки */
export const frequentCategories = writable({})
/** true после первой инициализации (из кэша или сети) */
export const frequentLoaded = writable(false)
/** Счётчики карточек повтора: ключ карточки → количество (минимум 1) */
export const frequentQuantities = writable({})

let currentQuantities = {}
frequentQuantities.subscribe((v) => { currentQuantities = v })

/**
 * Изменение счётчика −1+: минимум 1 (удаления из повтора нет),
 * мгновенная синхронная запись в localStorage — переживает перезагрузку.
 */
export function setFrequentQty(key, qty) {
  const next = { ...currentQuantities, [key]: Math.max(1, Number(qty) || 1) }
  frequentQuantities.set(next)
  writeFrequentQty(next)
  return next
}

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
  const qty = readFrequentQty()
  if (qty && typeof qty === "object") {
    frequentQuantities.set(qty)
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
