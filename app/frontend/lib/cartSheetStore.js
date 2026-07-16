import { get, writable } from "svelte/store"
import { api } from "./api.js"
import { CART_JUST_ADDED_KEY } from "./shopCartAdd.js"
import { addToCart } from "./shopCartAdd.js"
import { readCartCache, writeCartCache } from "./shopCartCache.js"
import {
  clearPersistedCartSheetMode,
  readPersistedCartSheetMode,
  writePersistedCartSheetMode
} from "./cartSheetModeCache.js"
import {
  MODE_EMPTY,
  MODE_EXPANDED,
  MODE_HIDDEN,
  MODE_PEEK,
  CHECKOUT_PEEK_REM,
  CHECKOUT_PEEK_VH,
  CHECKOUT_PAY_STACK_VH,
  SCROLL_TO_HIDDEN_PX,
  SCROLL_TO_PEEK_PX,
  SWIPE_UP_PX
} from "./cartSheetThresholds.js"

export const cartItems = writable([])
export const cartTotal = writable(0)
export const cartSheetMode = writable(MODE_EMPTY)
export const cartSheetBusy = writable(false)
export const cartUndoLine = writable(null)
export const cartSheetError = writable(null)
/** Фаза 2 UX: peek корзины + PaymentMethodsSheet в одной шторке на #/checkout */
export const checkoutPayOpen = writable(false)

let undoClearTimer = null

function clearCartUndo() {
  cartUndoLine.set(null)
  if (undoClearTimer) {
    clearTimeout(undoClearTimer)
    undoClearTimer = null
  }
}

export function clearCartSheetError() {
  cartSheetError.set(null)
}

/** Синхрон с Shop::CartService::MAX_ITEM_QUANTITY */
export const MAX_ITEM_QUANTITY = 99

let scrollAnchorY = 0
let eventsBound = false
let bumpChain = Promise.resolve()
let bumpInFlight = 0
let modePersistBound = false

function persistCartSheetMode() {
  const items = get(cartItems)
  const mode = get(cartSheetMode)
  if (!items.length || mode === MODE_EMPTY) {
    clearPersistedCartSheetMode()
    return
  }
  writePersistedCartSheetMode(mode)
}

function enqueueBump(index, delta) {
  bumpInFlight += 1
  cartSheetBusy.set(true)
  bumpChain = bumpChain
    .then(() => api(`/cart/items/${index}`, { method: "PATCH", body: JSON.stringify({ delta }) }))
    .then(() => refreshCartSheet())
    .catch(async (err) => {
      // Откат optimistic qty через refresh; сообщение — после refresh, иначе set(null) сотрёт.
      try {
        await refreshCartSheet()
      } catch (_e) {
        /* ignore */
      }
      cartSheetError.set(err?.message || "Не удалось изменить количество")
    })
    .finally(() => {
      bumpInFlight -= 1
      if (bumpInFlight <= 0) cartSheetBusy.set(false)
    })
}

export function isCatalogRoute(hash = null) {
  const h = (hash ?? (typeof window !== "undefined" ? window.location.hash : "")).replace("#", "") || "/"
  return h === "/" || h === ""
}

/**
 * Где видна шторка корзины.
 * Каталог + checkout (эталон заказчика: позиции под шторкой оплаты).
 * B1.13 «только каталог» — не блокер для UserCards / оформление.
 */
export function isCartSheetRoute(hash = null) {
  const h = (hash ?? (typeof window !== "undefined" ? window.location.hash : "")).replace("#", "") || "/"
  if (h === "/" || h === "") return true
  return h === "/checkout" || h.startsWith("/checkout?")
}

export function isCheckoutRoute(hash = null) {
  const h = (hash ?? (typeof window !== "undefined" ? window.location.hash : "")).replace("#", "") || "/"
  return h === "/checkout" || h.startsWith("/checkout?")
}

/** Эталон заказчика (UserCards): на #/checkout — peek с позициями, не hidden с каталога. */
export async function ensureCheckoutCartPeek() {
  await refreshCartSheet().catch(() => {})
  const items = get(cartItems)
  if (!items.length) {
    cartSheetMode.set(MODE_EMPTY)
    clearPersistedCartSheetMode()
    return
  }
  cartSheetMode.set(MODE_PEEK)
  resetScrollAnchor()
  writePersistedCartSheetMode(MODE_PEEK)
}

export const CHECKOUT_PAY_EVENT = "shop:checkout-pay"

export function requestCheckoutPay() {
  if (typeof window === "undefined") return
  window.dispatchEvent(new CustomEvent(CHECKOUT_PAY_EVENT))
}

/** Фаза 2: одна шторка — peek корзины сверху, PaymentMethodsSheet снизу (без backdrop). */
export function openCheckoutPayStack() {
  checkoutPayOpen.set(true)
  const items = get(cartItems)
  if (items.length) {
    cartSheetMode.set(MODE_PEEK)
    writePersistedCartSheetMode(MODE_PEEK)
  }
  if (typeof document !== "undefined") {
    document.documentElement.style.setProperty("--checkout-cart-peek-h", `${CHECKOUT_PEEK_VH}vh`)
    document.documentElement.style.setProperty("--checkout-pay-stack-h", `${CHECKOUT_PAY_STACK_VH}vh`)
  }
}

export function closeCheckoutPayStack() {
  checkoutPayOpen.set(false)
  if (typeof document !== "undefined") {
    document.documentElement.style.removeProperty("--checkout-cart-peek-h")
    document.documentElement.style.removeProperty("--checkout-pay-stack-h")
  }
  if (isCheckoutRoute()) void ensureCheckoutCartPeek()
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

/**
 * Открыть карточку товара на редактирование модификаторов.
 * В Product.svelte используется query `cart_line` для загрузки selected_modifiers из кэша.
 */
export function openEditCard(line) {
  const productId = line?.product_id
  const cart_line = line?.index
  const selected_modifiers = line?.selected_modifiers
  void selected_modifiers

  if (!productId || cart_line === undefined || cart_line === null) return "/"
  return `/product/${productId}?cart_line=${cart_line}`
}

function applyCartData(data) {
  const items = data?.items || []
  cartItems.set(items)
  cartTotal.set(Number(data?.total ?? 0))
  const mode = get(cartSheetMode)
  if (!items.length) {
    cartSheetMode.set(MODE_EMPTY)
    clearPersistedCartSheetMode()
    return
  }
  if (mode === MODE_EMPTY) {
    cartSheetMode.set(MODE_PEEK)
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
  }
}

export function resetScrollAnchor() {
  if (typeof window === "undefined") return
  scrollAnchorY = window.scrollY || 0
}

function isUnavailableCartError(err) {
  const msg = String(err?.message || err || "").toLowerCase()
  return msg.includes("товар недоступен") || msg.includes("законч") || msg.includes("out of stock")
}

export async function refreshCartSheet() {
  try {
    cartSheetError.set(null)
    const data = await api("/cart")
    writeCartCache(data)
    applyCartData(data)
    return data
  } catch (_e) {
    cartSheetError.set(_e?.message || "Ошибка обновления корзины")

    if (isUnavailableCartError(_e)) {
      cartItems.set([])
      cartTotal.set(0)
      cartSheetMode.set(MODE_EMPTY)
      clearPersistedCartSheetMode()
      writeCartCache({ items: [], total: 0 })
      cartSheetError.set("Товар недоступен. Корзина обновлена.")
      return { items: [], total: 0 }
    }

    const cached = readCartCache()
    if (cached?.items) {
      applyCartData(cached)
      return cached
    }
    cartItems.set([])
    cartTotal.set(0)
    cartSheetMode.set(MODE_EMPTY)
    clearPersistedCartSheetMode()
    throw _e
  }
}

/** Добавили товар: всегда peek (localStorage не переопределяет add-flow) */
export function onCartAdded() {
  clearCartUndo()
  cartSheetMode.set(MODE_PEEK)
  resetScrollAnchor()
  writePersistedCartSheetMode(MODE_PEEK)
  refreshCartSheet().catch(() => {})
}

export function onCatalogRouteChange(nowOnCatalog) {
  const items = get(cartItems)
  if (!items.length) return
  if (!nowOnCatalog) {
    persistCartSheetMode()
    return
  }
  try {
    if (typeof sessionStorage !== "undefined" && sessionStorage.getItem(CART_JUST_ADDED_KEY)) {
      sessionStorage.removeItem(CART_JUST_ADDED_KEY)
      cartSheetMode.set(MODE_PEEK)
      resetScrollAnchor()
      writePersistedCartSheetMode(MODE_PEEK)
      return
    }
  } catch (_e) {
    /* ignore */
  }
  const savedMode = readPersistedCartSheetMode()
  cartSheetMode.set(savedMode && savedMode !== MODE_EMPTY ? savedMode : MODE_PEEK)
  resetScrollAnchor()
}

/** Вход/выход с маршрутов, где видна CartSheet (каталог + checkout). */
export function onCartSheetRouteChange(nowOnSheetRoute) {
  if (!nowOnSheetRoute) return
  // На checkout — канон заказчика: всегда peek, не MODE_HIDDEN из localStorage каталога.
  if (isCheckoutRoute()) {
    void ensureCheckoutCartPeek()
    return
  }
  onCatalogRouteChange(nowOnSheetRoute)
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
  } else if (lines <= 1 && delta >= SCROLL_TO_PEEK_PX) {
    // 1 товар: 100px и 200px → hidden (peek при скролле пропускаем)
    cartSheetMode.set(MODE_HIDDEN)
  } else if (mode === MODE_EXPANDED && delta >= SCROLL_TO_PEEK_PX) {
    cartSheetMode.set(MODE_PEEK)
  }
}

/**
 * Свайп вверх:
 *   hidden       → peek
 *   peek (2+)    → expanded (горизонтальный ряд карточек)
 *   peek (1)     → noop (1 товар не раскрывается в expanded)
 *   expanded     → noop (уже максимум)
 */
export function expandFromSwipe() {
  const mode = get(cartSheetMode)
  const lines = cartLineCount(get(cartItems))
  if (!lines || mode === MODE_EMPTY) return

  if (mode === MODE_HIDDEN) {
    cartSheetMode.set(MODE_PEEK)
    resetScrollAnchor()
    return
  }

  if (mode === MODE_PEEK && lines >= 2) {
    cartSheetMode.set(MODE_EXPANDED)
    resetScrollAnchor()
  }
}

/**
 * Свайп вниз:
 *   expanded → peek
 *   peek     → hidden
 *   hidden   → noop
 */
export function collapseFromSwipe() {
  const mode = get(cartSheetMode)
  if (!cartLineCount(get(cartItems))) return

  if (mode === MODE_EXPANDED) {
    cartSheetMode.set(MODE_PEEK)
    resetScrollAnchor()
    return
  }

  if (mode === MODE_PEEK) {
    cartSheetMode.set(MODE_HIDDEN)
    resetScrollAnchor()
  }
}

/** Жест на gesture-zone: delta = startY − endY (вверх положительный). */
export function handleSheetGestureDelta(startY, endY) {
  if (get(checkoutPayOpen) && isCheckoutRoute()) return
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
    cartSheetMode.subscribe(() => persistCartSheetMode())
  }
}

export async function bumpCartLine(index, delta) {
  if (!optimisticBump(index, delta)) return
  clearCartUndo()
  enqueueBump(index, delta)
}

export async function removeCartLine(index) {
  if (get(cartSheetBusy)) return
  clearCartUndo()

  const removedLine = get(cartItems).find((l) => l.index === index)
  if (removedLine) {
    cartUndoLine.set({
      product_id: removedLine.product_id,
      quantity: removedLine.quantity,
      selected_modifiers: removedLine.selected_modifiers || []
    })
    undoClearTimer = setTimeout(() => {
      clearCartUndo()
    }, 30_000)
  }

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

export async function undoRemoveCartLine() {
  const line = get(cartUndoLine)
  if (!line) return

  clearCartUndo()
  try {
    await addToCart(
      {
        product_id: line.product_id,
        quantity: line.quantity,
        selected_modifiers: line.selected_modifiers
      },
      {}
    )
  } catch (_e) {
    // Если не смогли восстановить — вернём управление на UI (сумма уже держится на кэше).
    cartUndoLine.set(line)
    return
  }

  await refreshCartSheet().catch(() => {})
}
