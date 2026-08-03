/**
 * #37 Шаг 2 — CTA-кнопки статуса (Wallet / Push / Состав) [RED stub].
 * Верстка/логика — GREEN.
 */

/** Токены UI-kit для кнопок в правой колонке аккордеона. */
export const CTA_STYLE = Object.freeze({})

/**
 * @param {{ os?: "ios"|"android"|"desktop" }} opts
 * @returns {{
 *   primaryLabel: string,
 *   secondaryLabel: string,
 *   primaryKind: "wallet"|"push",
 *   actionsClass: string,
 *   buttonClass: string,
 *   style: typeof CTA_STYLE
 * }}
 */
export function notifyActionsView(_opts = {}) {
  return {
    primaryLabel: undefined,
    secondaryLabel: undefined,
    primaryKind: undefined,
    actionsClass: undefined,
    buttonClass: undefined,
    style: CTA_STYLE
  }
}
