import {
  clearShopRefreshToken,
  loadShopRefreshToken,
  saveShopRefreshToken
} from "./shopLocalStorage.js"

function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") || ""
}

function shopApiKey() {
  const meta = document.querySelector('meta[name="shop-api-key"]')?.getAttribute("content")
  if (meta && meta.trim()) return meta.trim()
  return ""
}

function shopRefreshUrl() {
  const tid =
    (typeof window !== "undefined" &&
      new URLSearchParams(window.location.search).get("tenant_id")) ||
    document.querySelector('meta[name="shop-tenant-id"]')?.getAttribute("content") ||
    ""
  let url = "/shop/api/session/refresh"
  if (tid) url += `?tenant_id=${encodeURIComponent(tid)}`
  return url
}

/** Один inflight: App + CartSheet + Checkout не гоняют параллельный refresh одним токеном. */
let inflight = null

/**
 * Silent Refresh по shop_refresh_token.
 * CSRF + API key — как у app/frontend/lib/api.js (иначе Fly Auth → 401).
 * @returns {Promise<{ verified: boolean, email?: string, profile?: object }>}
 */
export async function silentRefreshSession() {
  if (inflight) return inflight
  inflight = doSilentRefresh().finally(() => {
    inflight = null
  })
  return inflight
}

async function doSilentRefresh() {
  const token = loadShopRefreshToken()
  if (!token) return { verified: false }

  try {
    const headers = {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken()
    }
    const apiKey = shopApiKey()
    if (apiKey) headers["X-Shop-Api-Key"] = apiKey

    const res = await fetch(shopRefreshUrl(), {
      method: "POST",
      credentials: "same-origin",
      headers,
      body: JSON.stringify({ refresh_token: token }),
      cache: "no-store"
    })
    const data = await res.json().catch(() => ({}))
    if (!res.ok) {
      // Не стирать ротированный токен: параллельный refresh со старым → 401.
      if (loadShopRefreshToken() === token) clearShopRefreshToken()
      return { verified: false }
    }
    if (data.refresh_token) saveShopRefreshToken(data.refresh_token)
    return {
      verified: true,
      email: data.profile?.email,
      profile: data.profile
    }
  } catch {
    if (loadShopRefreshToken() === token) clearShopRefreshToken()
    return { verified: false }
  }
}
