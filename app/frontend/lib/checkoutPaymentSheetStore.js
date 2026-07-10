import { get, writable } from "svelte/store"
import { cartItems, cartTotal, refreshCartSheet } from "./cartSheetStore.js"
import {
  MODE_PEEK,
  MODE_EXPANDED,
  MODE_EXPANDED_PLUS,
  MAX_SAVED_CARDS,
  sheetHeightVh
} from "./checkoutPaymentSheetThresholds.js"

export const checkoutPaymentMode = writable(MODE_PEEK)
export const checkoutPaymentItems = writable([])
export const checkoutPaymentTotal = writable(0)
export const checkoutPaymentLimitError = writable(null)

let synced = false

/** Синхрон с cartItems / cartTotal каталога */
export function syncCheckoutPaymentCart() {
  const items = get(cartItems) || []
  checkoutPaymentItems.set(items)
  checkoutPaymentTotal.set(Number(get(cartTotal) || 0))
  if (!items.length) {
    checkoutPaymentMode.set(MODE_PEEK)
  }
  return items
}

export function bindCheckoutPaymentCart() {
  if (synced) return
  synced = true
  cartItems.subscribe(() => syncCheckoutPaymentCart())
  cartTotal.subscribe(() => syncCheckoutPaymentCart())
  refreshCartSheet().catch(() => syncCheckoutPaymentCart())
}

export function expandSheet() {
  const items = get(checkoutPaymentItems)
  if (!items.length) return
  checkoutPaymentMode.set(MODE_EXPANDED)
}

export function collapseToPeek() {
  checkoutPaymentMode.set(MODE_PEEK)
}

export function openPaymentList() {
  const items = get(checkoutPaymentItems)
  if (!items.length) return
  checkoutPaymentMode.set(MODE_EXPANDED_PLUS)
  checkoutPaymentLimitError.set(null)
}

export function closePaymentList() {
  checkoutPaymentMode.set(MODE_EXPANDED)
}

/** Guard лимита 10 карт перед открытием NewCardSheet (B1.12) */
export function assertCanAddCard(savedCardsCount = 0) {
  if (savedCardsCount >= MAX_SAVED_CARDS) {
    checkoutPaymentLimitError.set("Достигнут лимит: максимум 10 карт")
    return false
  }
  checkoutPaymentLimitError.set(null)
  return true
}

export function currentSheetHeightVh() {
  const items = get(checkoutPaymentItems) || []
  return sheetHeightVh(get(checkoutPaymentMode), items.length)
}
