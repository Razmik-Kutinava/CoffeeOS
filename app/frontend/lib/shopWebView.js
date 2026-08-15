/**
 * Telegram In-App Browser / WebView compatibility (not Mini App, not bot).
 * Isolated layer: detect, storage fallback, viewport, SPA stay-in-webview.
 * UA is not auth (#64/#65/#66).
 */

export function isTelegramInAppBrowser(ua = "") {
  return /Telegram/i.test(String(ua || ""))
}

export function shopApiUsesSameOrigin(prefix = "/shop/api") {
  const p = String(prefix || "")
  return p.startsWith("/") && !p.startsWith("//")
}

export function shopFetchCredentials() {
  return "same-origin"
}

export function probeStorage(storage) {
  if (!storage) return false
  try {
    const k = "__coffeeos_wv_probe__"
    storage.setItem(k, "1")
    const ok = storage.getItem(k) === "1"
    storage.removeItem(k)
    return ok
  } catch {
    return false
  }
}

function memoryStorage() {
  const map = new Map()
  return {
    getItem(key) {
      return map.has(key) ? map.get(key) : null
    },
    setItem(key, value) {
      map.set(key, String(value))
    },
    removeItem(key) {
      map.delete(key)
    }
  }
}

/** Native local/sessionStorage or in-memory fallback (WebView SecurityError). */
export function safeWebStorage(kind, env = globalThis) {
  const native = kind === "session" ? env.sessionStorage : env.localStorage
  if (probeStorage(native)) return native
  return memoryStorage()
}

export function applyShopVisualViewport(rootEl, viewport) {
  if (!rootEl?.style?.setProperty) return null
  const height = Number(viewport?.height || viewport?.innerHeight || 0)
  if (!height) return null
  rootEl.style.setProperty("--shop-vvh", `${Math.round(height)}px`)
  return height
}

export function installShopWebViewCompat(env = globalThis) {
  const root = env.document?.documentElement
  const vv = env.visualViewport
  const fallback = { height: vv?.height || env.innerHeight }
  applyShopVisualViewport(root, vv || fallback)

  if (vv && typeof vv.addEventListener === "function") {
    const onResize = () => applyShopVisualViewport(root, vv)
    vv.addEventListener("resize", onResize)
    return () => vv.removeEventListener("resize", onResize)
  }
  return () => {}
}

/** Internal shop hash/path stays in Telegram WebView; external t.me etc. do not. */
export function shopSpaHrefStaysInWebView(href) {
  const s = String(href || "")
  if (!s) return true
  if (s.startsWith("#") || s.startsWith("/shop") || s.startsWith("/#")) return true
  if (/^https?:\/\/t\.me\//i.test(s)) return false
  try {
    const u = new URL(s, "https://coffeeos.example")
    if (u.pathname.startsWith("/shop") || u.hash.startsWith("#/")) return true
  } catch {
    /* ignore */
  }
  return !/^https?:\/\//i.test(s)
}

export function shopColdStartSteps() {
  return ["html", "js", "svelte", "tenant", "storage", "api"]
}

export function tenantOnReopen({ urlTenant, cachedTenant } = {}) {
  const url = String(urlTenant || "").trim()
  if (url) return url
  return String(cachedTenant || "").trim()
}

export function catalogCacheKey(tenantId) {
  const t = String(tenantId || "").trim()
  return t ? `coffeeos_shop_catalog_v1:${t}` : "coffeeos_shop_catalog_v1"
}
