import { get, writable } from "svelte/store"
import { api } from "./api.js"
import { readCartCache, writeCartCache } from "./shopCartCache.js"
import {
  clearPersistedCartSheetLayout,
  readPersistedCartSheetLayout,
  writePersistedCartSheetLayout
} from "./cartSheetLayoutCache.js"
import {
  clearPersistedCartSheetMode,
  readPersistedCartSheetMode,
  writePersistedCartSheetMode
} from "./cartSheetModeCache.js"
import {
  EXPANDED_LAYOUT_HORIZONTAL,
  EXPANDED_LAYOUT_VERTICAL,
  MODE_EMPTY,
  MODE_EXPANDED,
  MODE_HIDDEN,
  MODE_PEEK,
  SCROLL_TO_HIDDEN_PX,
  SCROLL_TO_PEEK_PX,
  SWIPE_UP_PX
} from "./cartSheetThresholds.js"

export const cartItems = writable([])
export const cartTotal = writable(0)
export const cartSheetMode = writable(MODE_EMPTY)
export const cartSheetExpandedLayout = writable(EXPANDED_LAYOUT_VERTICAL)
export const cartSheetBusy = writable(false)

/** Синхрон с Shop::CartService::MAX_ITEM_QUANTITY */
export const MAX_ITEM_QUANTITY = 99

let scrollAnchorY = 0
let eventsBound = false
let bumpChain = Promise.resolve()
let bumpInFlight = 0
let modePersistBound = false
let layoutPersistBound = false

function persistCartSheetState() {
  const items = get(cartItems)
  const mode = get(cartSheetMode)
  if (!items.length || mode === MODE_EMPTY) {
    clearPersistedCartSheetMode()
    clearPersistedCartSheetLayout()
    return
  }
  writePersistedCartSheetMode(mode)
  if (mode === MODE_EXPANDED) {
    writePersistedCartSheetLayout(get(cartSheetExpandedLayout))
  }
}

function restoreCartSheetStateFromStorage() {
  const savedMode = readPersistedCartSheetMode()
  const savedLayout = readPersistedCartSheetLayout()
  if (savedMode) cartSheetMode.set(savedMode)
  if (savedLayout) cartSheetExpandedLayout.set(savedLayout)
  return savedMode
}

function resetExpandedLayoutVertical() {
  cartSheetExpandedLayout.set(EXPANDED_LAYOUT_VERTICAL)
}

function enqueueBump(index, delta) {
  bumpInFlight += 1
  cartSheetBusy.set(true)
  bumpChain = bumpChain
    .then(() =>
      api(`/cart/items/${index}`, {
        method: "PATCH",
        body: JSON.stringify({ delta })
      })
    )
    .then(() => refreshCartSheet())
    .catch(() => refreshCartSheet())
    .finally(() => {
      bumpInFlight -= 1
      if (bumpInFlight <= 0) cartSheetBusy.set(false)
    })
}

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
    clearPersistedCartSheetMode()
    clearPersistedCartSheetLayout()
    return
  }
  if (cartLineCount(items) <= 1) {
    resetExpandedLayoutVertical()
  }
  if (mode === MODE_EMPTY) {
    // Cold load on catalog: always expanded + vertical (restore only on tab return).
    cartSheetMode.set(MODE_EXPANDED)
    resetExpandedLayoutVertical()
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
  if (!next.length) {
    cartSheetMode.set(MODE_EMPTY)
    clearPersistedCartSheetMode()
    clearPersistedCartSheetLayout()
  } else if (cartLineCount(next) <= 1) {
    resetExpandedLayoutVertical()
  }
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
    clearPersistedCartSheetMode()
    clearPersistedCartSheetLayout()
    throw _e
  }
}

export function setCartSheetMode(mode) {
  cartSheetMode.set(mode)
  if (mode !== MODE_EXPANDED) resetExpandedLayoutVertical()
}

export function setCartSheetExpandedLayout(layout) {
  cartSheetExpandedLayout.set(layout)
}

export function onCartAdded() {
  cartSheetMode.set(MODE_EXPANDED)
  resetExpandedLayoutVertical()
  resetScrollAnchor()
  persistCartSheetState()
  refreshCartSheet().catch(() => {})
}

export function onCatalogRouteChange(nowOnCatalog) {
  const items = get(cartItems)
  if (!items.length) return

  if (!nowOnCatalog) {
    persistCartSheetState()
    return
  }

  restoreCartSheetStateFromStorage()
  if (get(cartSheetMode) === MODE_EMPTY) {
    cartSheetMode.set(MODE_EXPANDED)
    resetExpandedLayoutVertical()
  }
  resetScrollAnchor()
}

export function handleCatalogScroll() {
  if (!isCatalogRoute()) return
  const mode = get(cartSheetMode)
  const items = get(cartItems)
  const lines = cartLineCount(items)
  if (!lines) return
  if (mode !== MODE_EXPANDED && mode !== MODE_PEEK) return

  const y = window.scrollY || 0
  const delta = y - scrollAnchorY
  if (delta < 0) return

  if (delta >= SCROLL_TO_HIDDEN_PX) {
    cartSheetMode.set(MODE_HIDDEN)
    resetExpandedLayoutVertical()
  } else if (mode === MODE_EXPANDED && delta >= SCROLL_TO_PEEK_PX) {
    if (lines <= 1) {
      cartSheetMode.set(MODE_HIDDEN)
      resetExpandedLayoutVertical()
    } else {
      cartSheetMode.set(MODE_PEEK)
      resetExpandedLayoutVertical()
    }
  }
}

/**
 * Свайп вверх на drag-handle (канон прогон 5):
 * hidden/peek → expanded vertical; 2+ vertical → horizontal; иначе noop.
 */
export function expandFromSwipe() {
  const mode = get(cartSheetMode)
  const items = get(cartItems)
  const lines = cartLineCount(items)
  if (!lines || mode === MODE_EMPTY) return

  if (mode === MODE_HIDDEN || mode === MODE_PEEK) {
    cartSheetMode.set(MODE_EXPANDED)
    resetExpandedLayoutVertical()
    resetScrollAnchor()
    return
  }

  if (mode === MODE_EXPANDED && lines >= 2 && get(cartSheetExpandedLayout) === EXPANDED_LAYOUT_VERTICAL) {
    cartSheetExpandedLayout.set(EXPANDED_LAYOUT_HORIZONTAL)
    resetScrollAnchor()
  }
}

/**
 * Свайп вниз на drag-handle (канон прогон 5):
 * 1 товар: expanded → hidden; 2+ horizontal → vertical → hidden; peek → hidden.
 */
export function collapseFromSwipe() {
  const mode = get(cartSheetMode)
  const lines = cartLineCount(get(cartItems))
  if (!lines) return

  if (mode === MODE_EXPANDED) {
    if (lines <= 1) {
      cartSheetMode.set(MODE_HIDDEN)
      resetExpandedLayoutVertical()
      resetScrollAnchor()
      return
    }
    if (get(cartSheetExpandedLayout) === EXPANDED_LAYOUT_HORIZONTAL) {
      cartSheetExpandedLayout.set(EXPANDED_LAYOUT_VERTICAL)
      resetScrollAnchor()
      return
    }
    cartSheetMode.set(MODE_HIDDEN)
    resetExpandedLayoutVertical()
    resetScrollAnchor()
    return
  }

  if (mode === MODE_PEEK) {
    cartSheetMode.set(MODE_HIDDEN)
    resetExpandedLayoutVertical()
    resetScrollAnchor()
  }
}

/** Жест на gesture-zone: delta = startY − endY (вверх — положительный). */
export function handleSheetGestureDelta(startY, endY) {
  const delta = startY - endY
  if (delta >= SWIPE_UP_PX) {
    expandFromSwipe()
  } else if (endY - startY >= SWIPE_UP_PX) {
    collapseFromSwipe()
  }
}

export function bindCartSheetEvents() {
  if (eventsBound || typeof window === "undefined") return
  eventsBound = true
  window.addEventListener("shop:cart-added", onCartAdded)
  if (!modePersistBound) {
    modePersistBound = true
    cartSheetMode.subscribe(() => persistCartSheetState())
  }
  if (!layoutPersistBound) {
    layoutPersistBound = true
    cartSheetExpandedLayout.subscribe(() => persistCartSheetState())
  }
}

export async function bumpCartLine(index, delta) {
  if (!optimisticBump(index, delta)) return
  enqueueBump(index, delta)
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
