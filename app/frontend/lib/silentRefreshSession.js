import {
  clearShopRefreshToken,
  loadShopRefreshToken,
  saveShopRefreshToken
} from "./shopLocalStorage.js"

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

/**
 * Silent Refresh по shop_refresh_token.
 * @returns {Promise<{ verified: boolean, email?: string, profile?: object }>}
 */
export async function silentRefreshSession() {
  const token = loadShopRefreshToken()
  if (!token) return { verified: false }

  try {
    const res = await fetch(shopRefreshUrl(), {
      method: "POST",
      credentials: "same-origin",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ refresh_token: token }),
      cache: "no-store"
    })
    const data = await res.json().catch(() => ({}))
    if (!res.ok) {
      clearShopRefreshToken()
      return { verified: false }
    }
    if (data.refresh_token) saveShopRefreshToken(data.refresh_token)
    return {
      verified: true,
      email: data.profile?.email,
      profile: data.profile
    }
  } catch {
    clearShopRefreshToken()
    return { verified: false }
  }
}
