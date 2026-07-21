import { writable } from "svelte/store"
import { push } from "svelte-spa-router"
import { api } from "./api.js"
import { addToCart } from "./shopCartAdd.js"
import { cartSheetMode } from "./cartSheetStore.js"
import { MODE_HIDDEN, MODE_EXPANDED } from "./cartSheetThresholds.js"
import { readFrequentCache, writeFrequentCache, readFrequentQty, writeFrequentQty } from "./shopFrequentCache.js"

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

/** Стабильный ключ карточки: товар + модификаторы (не позиция — порядок топ-3 меняется при refresh) */
export function frequentCardKey(item) {
  return `${item.product_id}:${JSON.stringify(item.modifier_options || {})}`
}

/** Счётчик −1+: минимум 1, мгновенная запись в localStorage (переживает перезагрузку) */
export function setFrequentQty(key, qty) {
  const next = { ...currentQuantities, [key]: Math.max(1, Number(qty) || 1) }
  frequentQuantities.set(next)
  writeFrequentQty(next)
  return next
}

/** Мгновенный старт из localStorage (< 50 мс, без сети); актуализация — refreshFrequentProducts */
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
 * «Повторить в 1 клик» (ТЗ Шаг 11): позиции повтора в корзину с сохранёнными
 * модификаторами и счётчиками. Успех → hidden + success-тост; ошибка → error-тост, режим не меняется.
 */
export async function repeatAllToCart() {
  const items = currentItems.slice(0, 3)
  if (!items.length) return false
  let added = 0
  try {
    // Последовательно: addToCart оптимистично пишет cart-кэш, гонки не нужны
    for (const item of items) {
      await addToCart({
        product_id: item.product_id,
        quantity: currentQuantities[frequentCardKey(item)] || 1,
        selected_modifiers: item.modifier_options?.selected_modifiers || []
      })
      added += 1
    }
    cartSheetMode.set(MODE_HIDDEN)
    repeatFeedback.set({ type: "success", message: "Заказ добавлен в корзину" })
    return true
  } catch (_e) {
    // Частичное добавление — честный тост: повторный клик даст дубли первых позиций
    repeatFeedback.set({ type: "error", message: added ? `Добавлено ${added} из ${items.length} — проверьте корзину` : "Не удалось повторить заказ" })
    return false
  }
}

/** «+ещё» (ТЗ Шаг 11): развернуть шторку в expanded */
export function repeatMore() {
  cartSheetMode.set(MODE_EXPANDED)
}

/** Флаг «оплатить в 1 клик»: Checkout снимает его и автооткрывает шит оплаты */
export const REPEAT_AUTOPAY_KEY = "shop_repeat_autopay"

/**
 * «Оплатить в 1 клик» (скрин 06): повтор в корзину → checkout с автооткрытым шитом
 * оплаты. Списание — канон one_click с подтверждением; при ошибке добавления навигации нет.
 */
export async function repeatPayOneClick() {
  const ok = await repeatAllToCart()
  if (!ok) return false
  try {
    sessionStorage.setItem(REPEAT_AUTOPAY_KEY, "1")
  } catch (_e) {
    /* приватный режим: без автооткрытия, просто checkout */
  }
  push("/checkout")
  return true
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
