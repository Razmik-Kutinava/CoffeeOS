/**
 * #37 — CTA Wallet / Push / «Состав заказа» в строке аккордеона.
 */

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
