import { get, writable } from "svelte/store"
import { cartItems, cartTotal, refreshCartSheet } from "./cartSheetStore.js"
import {
  MODE_PEEK,
  MODE_EXPANDED,
  MODE_EXPANDED_PLUS,
  SUBVIEW_PAYMENT_LIST,
  SUBVIEW_CARD_FORM,
  SUBVIEW_THREE_DS,
  MAX_SAVED_CARDS,
  sheetHeightVh
} from "./checkoutPaymentSheetThresholds.js"

export const checkoutPaymentMode = writable(MODE_PEEK)
export const checkoutPaymentSubView = writable(SUBVIEW_PAYMENT_LIST)
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
    checkoutPaymentSubView.set(SUBVIEW_PAYMENT_LIST)
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
  checkoutPaymentSubView.set(SUBVIEW_PAYMENT_LIST)
}

export function collapseToPeek() {
  checkoutPaymentMode.set(MODE_PEEK)
  checkoutPaymentSubView.set(SUBVIEW_PAYMENT_LIST)
}

export function openPaymentList() {
  const items = get(checkoutPaymentItems)
  if (!items.length) return
  checkoutPaymentMode.set(MODE_EXPANDED_PLUS)
  checkoutPaymentSubView.set(SUBVIEW_PAYMENT_LIST)
  checkoutPaymentLimitError.set(null)
}

export function closePaymentList() {
  checkoutPaymentMode.set(MODE_EXPANDED)
  checkoutPaymentSubView.set(SUBVIEW_PAYMENT_LIST)
}

export function openCardForm(savedCardsCount = 0) {
  if (savedCardsCount >= MAX_SAVED_CARDS) {
    checkoutPaymentLimitError.set("Достигнут лимит: максимум 10 карт")
    return false
  }
  checkoutPaymentLimitError.set(null)
  checkoutPaymentMode.set(MODE_EXPANDED_PLUS)
  checkoutPaymentSubView.set(SUBVIEW_CARD_FORM)
  return true
}

export function closeCardForm() {
  checkoutPaymentSubView.set(SUBVIEW_PAYMENT_LIST)
}

export function openThreeDs() {
  checkoutPaymentMode.set(MODE_EXPANDED_PLUS)
  checkoutPaymentSubView.set(SUBVIEW_THREE_DS)
}

export function closeThreeDs() {
  checkoutPaymentSubView.set(SUBVIEW_CARD_FORM)
}

/** После expiry таймера 3DS — начать добавление карты заново */
export function restartAddCardAfterThreeDsExpiry() {
  closeThreeDs()
  openCardForm(0)
}

export function currentSheetHeightVh() {
  return sheetHeightVh(get(checkoutPaymentMode), get(checkoutPaymentSubView))
}
