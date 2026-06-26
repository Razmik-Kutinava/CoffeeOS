import { get, writable } from "svelte/store"
import { api } from "./api.js"
import { readCartCache, writeCartCache } from "./shopCartCache.js"
import {
  MODE_EMPTY,
  MODE_EXPANDED,
  MODE_HIDDEN,
  MODE_PEEK,
  SCROLL_TO_HIDDEN_PX,
  SCROLL_TO_HIDDEN_VH,
  SCROLL_TO_PEEK_PX,
  SCROLL_TO_PEEK_VH
} from "./cartSheetThresholds.js"

export const cartItems = writable([])
export const cartTotal = writable(0)
export const cartSheetMode = writable(MODE_EMPTY)
export const cartSheetBusy = writable(false)

/** Синхрон с Shop::CartService::MAX_ITEM_QUANTITY */
export const MAX_ITEM_QUANTITY = 99

let scrollAnchorY = 0
let eventsBound = false

export function isCatalogRoute(hash = null) {
  const h = (hash ?? (typeof window !== "undefined" ? window.location.hash : "")).replace("#", "") || "/"
  return h === "/" || h === ""
}

export function cartLineCount(items) {
  return (items || []).length
}

export function atMinQty(line) {
  return Number(line?.quantity) <= 1
}

export function atMaxQty(line) {
  return Number(line?.quantity) >= MAX_ITEM_QUANTITY
}

function applyCartData(data) {
  const items = data?.items || []
  cartItems.set(items)
  cartTotal.set(Number(data?.total ?? 0))
  const mode = get(cartSheetMode)
  if (!items.length) {
    cartSheetMode.set(MODE_EMPTY)
    return
  }
  if (mode === MODE_EMPTY) {
    cartSheetMode.set(MODE_EXPANDED)
    resetScrollAnchor()
  }
}

function optimisticBump(index, delta) {
  const items = get(cartItems)
  const line = items.find((l) => l.index === index)
  if (!line) return false
  if (delta < 0 && atMinQty(line)) return false
  if (delta > 0 && atMaxQty(line)) return false

  const qty = Number(line.quantity) + delta
  const unit = Number(line.unit_total) || Number(line.line_total) / Number(line.quantity)
  const next = items.map((l) => {
    if (l.index !== index) return l
    return { ...l, quantity: qty, line_total: unit * qty }
  })
  cartItems.set(next)
  cartTotal.set(next.reduce((sum, l) => sum + Number(l.line_total), 0))
  writeCartCache({ items: next, total: get(cartTotal) })
  return true
}

function optimisticRemove(index) {
  const next = get(cartItems)
    .filter((l) => l.index !== index)
    .map((l, i) => ({ ...l, index: i }))
  cartItems.set(next)
  const total = next.reduce((sum, l) => sum + Number(l.line_total), 0)
  cartTotal.set(total)
  writeCartCache({ items: next, total })
  if (!next.length) cartSheetMode.set(MODE_EMPTY)
}

export function resetScrollAnchor() {
  if (typeof window === "undefined") return
  scrollAnchorY = window.scrollY || 0
}

export async function refreshCartSheet() {
  try {
    const data = await api("/cart")
    writeCartCache(data)
    applyCartData(data)
    return data
  } catch (_e) {
    const cached = readCartCache()
    if (cached?.items) {
      applyCartData(cached)
      return cached
    }
    cartItems.set([])
    cartTotal.set(0)
    cartSheetMode.set(MODE_EMPTY)
    throw _e
  }
}

export function onCartAdded() {
  cartSheetMode.set(MODE_EXPANDED)
  resetScrollAnchor()
  refreshCartSheet().catch(() => {})
}

export function handleCatalogScroll() {
  if (!isCatalogRoute()) return
  const mode = get(cartSheetMode)
  const items = get(cartItems)
  if (!items.length) return
  if (mode !== MODE_EXPANDED && mode !== MODE_PEEK) return

  const y = window.scrollY || 0
  const delta = y - scrollAnchorY
  if (delta < 0) return

  const vh = window.innerHeight || 800
  const toPeek = Math.max(SCROLL_TO_PEEK_PX, vh * SCROLL_TO_PEEK_VH)
  const toHidden = toPeek + Math.max(SCROLL_TO_HIDDEN_PX, vh * SCROLL_TO_HIDDEN_VH)

  if (mode === MODE_EXPANDED && delta >= toPeek) {
    cartSheetMode.set(MODE_PEEK)
  } else if (delta >= toHidden) {
    cartSheetMode.set(MODE_HIDDEN)
  }
}

export function expandFromSwipe() {
  if (cartLineCount(get(cartItems)) <= 1) return
  cartSheetMode.set(MODE_EXPANDED)
  resetScrollAnchor()
}

export function bindCartSheetEvents() {
  if (eventsBound || typeof window === "undefined") return
  eventsBound = true
  window.addEventListener("shop:cart-added", onCartAdded)
}

export async function bumpCartLine(index, delta) {
  if (get(cartSheetBusy)) return
  if (!optimisticBump(index, delta)) return

  cartSheetBusy.set(true)
  try {
    await api(`/cart/items/${index}`, {
      method: "PATCH",
      body: JSON.stringify({ delta })
    })
    await refreshCartSheet()
  } catch (_e) {
    await refreshCartSheet()
  } finally {
    cartSheetBusy.set(false)
  }
}

export async function removeCartLine(index) {
  if (get(cartSheetBusy)) return
  optimisticRemove(index)

  cartSheetBusy.set(true)
  try {
    await api(`/cart/items/${index}`, { method: "DELETE" })
    await refreshCartSheet()
  } catch (_e) {
    await refreshCartSheet()
  } finally {
    cartSheetBusy.set(false)
  }
}
