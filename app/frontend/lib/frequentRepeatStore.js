import { writable } from "svelte/store"
import { api } from "./api.js"
import { addToCart } from "./shopCartAdd.js"
import { cartSheetMode } from "./cartSheetStore.js"
import { MODE_HIDDEN, MODE_EXPANDED } from "./cartSheetThresholds.js"
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
/** Тост секции «повторить»: { type: "success"|"error", message } | null */
export const repeatFeedback = writable(null)

let currentQuantities = {}
frequentQuantities.subscribe((v) => { currentQuantities = v })
let currentItems = []
frequentItems.subscribe((v) => { currentItems = Array.isArray(v) ? v : [] })

/** Ключ карточки — тот же формат, что в RepeatSection.svelte */
export function frequentCardKey(item, i) {
  return `${item.product_id}-${i}`
}

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

/**
 * «Повторить в 1 клик» (ТЗ Шаг 11): все позиции повтора в корзину с
 * сохранёнными модификаторами заказа и счётчиками F3. Успех → шторка
 * hidden + success-тост; ошибка → error-тост, режим шторки не меняется.
 */
export async function repeatAllToCart() {
  const items = currentItems.slice(0, 3)
  if (!items.length) return false
  try {
    // Последовательно: addToCart оптимистично пишет cart-кэш, гонки не нужны
    for (const [ i, item ] of items.entries()) {
      await addToCart({
        product_id: item.product_id,
        quantity: currentQuantities[frequentCardKey(item, i)] || 1,
        selected_modifiers: item.modifier_options?.selected_modifiers || []
      })
    }
    cartSheetMode.set(MODE_HIDDEN)
    repeatFeedback.set({ type: "success", message: "Заказ добавлен в корзину" })
    return true
  } catch (_e) {
    repeatFeedback.set({ type: "error", message: "Не удалось повторить заказ" })
    return false
  }
}

/** «+ещё» (ТЗ Шаг 11): развернуть шторку в expanded */
export function repeatMore() {
  cartSheetMode.set(MODE_EXPANDED)
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
