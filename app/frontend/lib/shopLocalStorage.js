/** Метаданные TTL (для touch/скольжения). Hard burn через 24ч убран. */
export const SHOP_LS_TTL_MS = 90 * 24 * 60 * 60 * 1000

const REFRESH_TOKEN_KEY = "shop_refresh_token"

export function readShopLocalStorage(key, _ttlMs = SHOP_LS_TTL_MS) {
  try {
    const raw = localStorage.getItem(key)
    if (!raw) return null

    const parsed = JSON.parse(raw)
    if (!parsed || typeof parsed !== "object" || parsed.savedAt == null || !("payload" in parsed)) {
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

/** Скользящий TTL: обновить savedAt без смены payload. */
export function touchShopLocalStorage(key) {
  const payload = readShopLocalStorage(key)
  if (payload == null) return
  writeShopLocalStorage(key, payload)
}

export function removeShopLocalStorage(key) {
  try {
    localStorage.removeItem(key)
  } catch {
    /* ignore */
  }
}

export function saveShopRefreshToken(token) {
  if (!token) return
  try {
    localStorage.setItem(REFRESH_TOKEN_KEY, String(token))
  } catch {
    /* quota */
  }
}

export function loadShopRefreshToken() {
  try {
    return localStorage.getItem(REFRESH_TOKEN_KEY) || null
  } catch {
    return null
  }
}

export function clearShopRefreshToken() {
  try {
    localStorage.removeItem(REFRESH_TOKEN_KEY)
  } catch {
    /* ignore */
  }
}
