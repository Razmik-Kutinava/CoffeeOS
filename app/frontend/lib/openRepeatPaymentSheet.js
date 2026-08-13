/**
 * После отказа One-Click / invalid token: открыть канон PaymentMethodsSheet
 * (checkout pay-stack expanded), не InlinePayFallback expand в peek.
 */
import { push } from "svelte-spa-router"
import { get } from "svelte/store"
import { addToCart } from "./shopCartAdd.js"
import {
  markOpenPaymentSheet,
  persistPaymentSelection
} from "./repeatInvalidTokenStore.js"
import {
  requestCheckoutPay,
  isCheckoutRoute,
  refreshCartSheet,
  cartItems
} from "./cartSheetStore.js"
import { frequentCardKey, frequentQuantities } from "./frequentRepeatStore.js"

/**
 * @param {object} [item] — frequent card (если корзина пуста после fail — восстановить peek)
 * @param {{ preferNewCard?: boolean }} [opts]
 */
export async function openRepeatPaymentSheet(item, { preferNewCard = false } = {}) {
  if (preferNewCard) {
    persistPaymentSelection({ selectedCardId: null, selectionMode: "new_card" })
  }
  markOpenPaymentSheet()

  // pending_payment с defer_init не чистит корзину — не дублировать addToCart (bugbot).
  await refreshCartSheet().catch(() => {})
  const lines = get(cartItems) || []
  if (item?.product_id && lines.length === 0) {
    const qty = get(frequentQuantities)[frequentCardKey(item)] || 1
    try {
      await addToCart({
        product_id: item.product_id,
        quantity: qty,
        selected_modifiers: item.modifier_options?.selected_modifiers || []
      })
      await refreshCartSheet().catch(() => {})
    } catch (_e) {
      /* ignore */
    }
  }

  if (typeof window !== "undefined" && isCheckoutRoute()) {
    requestCheckoutPay()
    return
  }
  push("/checkout")
}

/**
 * UI после тапа «карта +»: не expanded в peek, а флаг открытия шторки.
 * @returns {{ showFallbackMethods: boolean, showExpandedCards: boolean, showNewCardForm: boolean, openPaymentSheet: boolean }}
 */
export function resolveOpenPaymentSheetUi() {
  return {
    showFallbackMethods: true,
    showExpandedCards: false,
    showNewCardForm: false,
    openPaymentSheet: true
  }
}
