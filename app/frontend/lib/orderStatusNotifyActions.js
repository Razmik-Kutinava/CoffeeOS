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

const WALLET_SUCCESS_LABEL = "✓ Карта добавлена"
const WALLET_ERROR_TOAST = "Не удалось добавить карту. Попробуйте позже."

/**
 * iOS: скачать .pkpass (GET /shop/api/orders/:id/wallet_pass).
 *
 * @param {{
 *   orderId: string|number,
 *   fetchImpl?: typeof fetch,
 *   createObjectURL?: (blob: Blob) => string,
 *   locationAssign?: (url: string) => void,
 *   storage?: Storage,
 *   onToast?: (msg: string) => void
 * }} opts
 */
export async function downloadWalletPass(opts = {}) {
  const {
    orderId,
    fetchImpl = globalThis.fetch.bind(globalThis),
    createObjectURL = (blob) => URL.createObjectURL(blob),
    locationAssign = (url) => {
      globalThis.location.href = url
    },
    storage = globalThis.localStorage,
    onToast
  } = opts

  const idleLabel = LABELS.wallet
  const url = `/shop/api/orders/${orderId}/wallet_pass`

  try {
    const res = await fetchImpl(url, {
      method: "GET",
      credentials: "same-origin",
      headers: { Accept: "application/vnd.apple.pkpass" },
      cache: "no-store"
    })

    if (!res.ok) {
      if (typeof onToast === "function") onToast(WALLET_ERROR_TOAST)
      return { ok: false, isLoading: false, primaryLabel: idleLabel, error: String(res.status) }
    }

    const blob = await res.blob()
    const blobUrl = createObjectURL(blob)
    locationAssign(blobUrl)
    storage?.setItem(walletAddedStorageKey(orderId), "true")

    return { ok: true, isLoading: false, primaryLabel: WALLET_SUCCESS_LABEL }
  } catch (err) {
    if (typeof onToast === "function") onToast(WALLET_ERROR_TOAST)
    return {
      ok: false,
      isLoading: false,
      primaryLabel: idleLabel,
      error: err?.message || "network"
    }
  }
}

const PUSH_SUCCESS_LABEL = "✓ Уведомления включены"
const PUSH_DENIED_TOAST = "Уведомления запрещены в настройках браузера"
const PUSH_NETWORK_TOAST = "Не удалось включить уведомления. Проверьте сеть."

/**
 * Android/Desktop: FCM через registerShopPush.
 * #37 шаг 5 — RED stub.
 *
 * @param {{
 *   registerShopPushImpl?: () => Promise<{ok:boolean, reason?:string}>,
 *   onToast?: (msg: string) => void
 * }} [opts]
 */
export async function subscribeOrderPush(_opts = {}) {
  return {
    ok: false,
    isLoading: true,
    primaryLabel: LABELS.push
  }
}
