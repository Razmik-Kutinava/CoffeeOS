/** TTL localStorage для витрины — как OTP/email verification на бэке (24ч). */
export const SHOP_LS_TTL_MS = 24 * 60 * 60 * 1000

export function readShopLocalStorage(key, ttlMs = SHOP_LS_TTL_MS) {
  try {
    const raw = localStorage.getItem(key)
    if (!raw) return null

    const parsed = JSON.parse(raw)
    if (!parsed || typeof parsed !== "object" || parsed.savedAt == null || !("payload" in parsed)) {
      localStorage.removeItem(key)
      return null
    }

    const savedAt = new Date(parsed.savedAt).getTime()
    if (Number.isNaN(savedAt) || Date.now() - savedAt > ttlMs) {
      localStorage.removeItem(key)
      return null
    }

    return parsed.payload
  } catch {
    try {
      localStorage.removeItem(key)
    } catch {
      /* ignore */
    }
    return null
  }
}

export function writeShopLocalStorage(key, payload, ttlMs = SHOP_LS_TTL_MS) {
  try {
    localStorage.setItem(
      key,
      JSON.stringify({
        savedAt: new Date().toISOString(),
        ttlMs,
        payload
      })
    )
  } catch {
    /* quota */
  }
}

export function removeShopLocalStorage(key) {
  try {
    localStorage.removeItem(key)
  } catch {
    /* ignore */
  }
}
