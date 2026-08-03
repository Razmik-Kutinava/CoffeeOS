/**
 * #37 — лёгкая детекция ОС для CTA Wallet / Push.
 * Без сторонних библиотек.
 *
 * @param {{
 *   userAgent?: string,
 *   platform?: string,
 *   maxTouchPoints?: number,
 *   hasWindow?: boolean
 * }} [env] — injectable для тестов; без аргумента читает `navigator` / `window`
 * @returns {"ios"|"android"|"desktop"}
 */
export function getDeviceOS(env) {
  const hasWindow =
    env && Object.prototype.hasOwnProperty.call(env, "hasWindow")
      ? Boolean(env.hasWindow)
      : typeof window !== "undefined"

  if (!hasWindow) return "desktop"

  const nav = env || (typeof navigator !== "undefined" ? navigator : null)
  if (!nav) return "desktop"

  const ua = String(nav.userAgent || "")
  const platform = String(nav.platform || "")
  const maxTouchPoints = Number(nav.maxTouchPoints || 0)

  if (/iPhone|iPod/i.test(ua)) return "ios"
  // iPadOS 13+: Safari отдаёт MacIntel + touch
  if (platform === "MacIntel" && maxTouchPoints > 1) return "ios"
  if (/Android/i.test(ua)) return "android"
  return "desktop"
}
