/**
 * #37 — CTA Wallet / Push / «Состав заказа» в строке аккордеона.
 */

import { toggleExpandedOrder } from "./activeOrdersAccordion.js"

/** Токены UI-kit (accent проекта, h-9 ≈ 36px, rounded-lg, w-44). */
export const CTA_STYLE = Object.freeze({
  background: "#ff8c42",
  color: "#000000",
  fontWeight: 600,
  heightPx: 36,
  borderRadius: "0.5rem",
  fontSizeRem: 0.75,
  actionsWidthRem: 11,
  actionsGapRem: 0.5
})

const LABELS = Object.freeze({
  wallet: "Карта в Apple Wallet",
  push: "🔔 Уведомление о готовности",
  receipt: "Состав заказа"
})

/**
 * @param {{ os?: "ios"|"android"|"desktop" }} opts
 */
export function notifyActionsView({ os } = {}) {
  const primaryKind = os === "ios" ? "wallet" : "push"
  return {
    primaryLabel: primaryKind === "wallet" ? LABELS.wallet : LABELS.push,
    secondaryLabel: LABELS.receipt,
    primaryKind,
    actionsClass: "aoa__actions",
    buttonClass: "aoa__cta",
    style: CTA_STYLE
  }
}

/**
 * Клик «Состав заказа»: раскрыть/свернуть чек. Без isLoading.
 *
 * @param {object} state accordion state (`activeExpandedOrderId`)
 * @param {string|number} orderId
 * @param {{ isLoading?: boolean }} [ui]
 * @returns {{ isLoading: boolean }}
 */
export function openOrderReceipt(state, orderId, ui = {}) {
  if (ui && Object.prototype.hasOwnProperty.call(ui, "isLoading")) {
    ui.isLoading = false
  }
  toggleExpandedOrder(state, orderId)
  return { isLoading: false }
}

/** localStorage key после успешного добавления pass. */
export function walletAddedStorageKey(orderId) {
  return `order_${orderId}_wallet_added`
}

/**
 * iOS: скачать .pkpass (GET /shop/api/orders/:id/wallet_pass).
 * #37 шаг 4 — RED stub.
 *
 * @returns {Promise<{
 *   ok: boolean,
 *   isLoading: boolean,
 *   primaryLabel: string,
 *   error?: string
 * }>}
 */
export async function downloadWalletPass(_opts = {}) {
  return {
    ok: false,
    isLoading: true,
    primaryLabel: "Карта в Apple Wallet"
  }
}
