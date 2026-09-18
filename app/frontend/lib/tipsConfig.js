/**
 * Tips (нетмонет) URL — одна строка конфигурации, как SUPPORT_TELEGRAM_URL.
 * Override: VITE_SHOP_TIPS_URL.
 */
export const TIPS_SERVICE_URL = "https://t.me/code_black_support_bot"

export function tipsUrlForOrder(orderId, baseUrl = TIPS_SERVICE_URL) {
  const base = typeof baseUrl === "string" ? baseUrl.trim() : ""
  if (!base) return ""
  const oid = String(orderId || "").trim()
  if (!oid) return base
  const sep = base.includes("?") ? "&" : "?"
  return `${base}${sep}start=tips_${encodeURIComponent(oid)}`
}
