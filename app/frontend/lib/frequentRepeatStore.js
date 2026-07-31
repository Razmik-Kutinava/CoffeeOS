import { writable } from "svelte/store"
import { push } from "svelte-spa-router"
import { api } from "./api.js"
import { addToCart } from "./shopCartAdd.js"
import { cartSheetMode } from "./cartSheetStore.js"
import { MODE_HIDDEN, MODE_EXPANDED } from "./cartSheetThresholds.js"
import { readFrequentCache, writeFrequentCache, readFrequentQty, writeFrequentQty } from "./shopFrequentCache.js"

/** Секция «повторить» — GET /shop/api/frequent_products */
export const frequentItems = writable([])
export const frequentCategories = writable({})
export const frequentLoaded = writable(false)
export const frequentQuantities = writable({})
export const repeatFeedback = writable(null)
/** Ревизия 2026-07-31: true → CartSheet скрывает «повторить» */
export const hasActiveOrder = writable(false)

let currentQuantities = {}
frequentQuantities.subscribe((v) => { currentQuantities = v })
let currentItems = []
frequentItems.subscribe((v) => { currentItems = Array.isArray(v) ? v : [] })

export function frequentCardKey(item) {
  return `${item.product_id}:${JSON.stringify(item.modifier_options || {})}`
}

export function setFrequentQty(key, qty) {
  const next = { ...currentQuantities, [key]: Math.max(1, Number(qty) || 1) }
  frequentQuantities.set(next)
  writeFrequentQty(next)
  return next
}

function applyFrequentPayload(data) {
  const active = !!(data && data.has_active_order)
  hasActiveOrder.set(active)
  if (active) frequentItems.set([])
  else frequentItems.set(Array.isArray(data?.frequent_items) ? data.frequent_items : [])
  if (data?.categories && typeof data.categories === "object") frequentCategories.set(data.categories)
}

export function initFrequentFromCache() {
  const cached = readFrequentCache()
  if (cached) applyFrequentPayload(cached)
  const qty = readFrequentQty()
  if (qty && typeof qty === "object") frequentQuantities.set(qty)
  frequentLoaded.set(true)
  return cached
}

export async function repeatAllToCart() {
  const items = currentItems.slice(0, 3)
  if (!items.length) return false
  let added = 0
  try {
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
    repeatFeedback.set({
      type: "error",
      message: added ? `Добавлено ${added} из ${items.length} — проверьте корзину` : "Не удалось повторить заказ"
    })
    return false
  }
}

export function repeatMore() {
  cartSheetMode.set(MODE_EXPANDED)
}

export const REPEAT_AUTOPAY_KEY = "shop_repeat_autopay"

function checkoutWithAutopay() {
  cartSheetMode.set(MODE_HIDDEN)
  try { sessionStorage.setItem(REPEAT_AUTOPAY_KEY, "1") } catch (_e) {}
  push("/checkout")
}

export async function repeatPayOneClickItem(item) {
  if (!item?.product_id) return false
  try {
    await addToCart({
      product_id: item.product_id,
      quantity: currentQuantities[frequentCardKey(item)] || 1,
      selected_modifiers: item.modifier_options?.selected_modifiers || []
    })
    checkoutWithAutopay()
    return true
  } catch (_e) {
    repeatFeedback.set({ type: "error", message: "Не удалось добавить в корзину" })
    return false
  }
}

/** @param {string} [email] — после F5: frequent по verified email */
export async function refreshFrequentProducts(email) {
  try {
    let path = "/frequent_products"
    const e = email && String(email).trim().toLowerCase()
    if (e) path += `?email=${encodeURIComponent(e)}`
    const data = await api(path)
    applyFrequentPayload(data || {})
    writeFrequentCache(data)
    frequentLoaded.set(true)
    return data
  } catch (_e) {
    return null
  }
}
