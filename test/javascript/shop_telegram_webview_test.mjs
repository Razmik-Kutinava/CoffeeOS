/**
 * #66 Telegram In-App Browser / WebView compatibility (not Mini App, not bot).
 * node --test test/javascript/shop_telegram_webview_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, afterEach } from "node:test"
import {
  applyShopVisualViewport,
  catalogCacheKey,
  installShopWebViewCompat,
  isTelegramInAppBrowser,
  probeStorage,
  safeWebStorage,
  shopApiUsesSameOrigin,
  shopColdStartSteps,
  shopFetchCredentials,
  shopSpaHrefStaysInWebView,
  tenantOnReopen
} from "../../app/frontend/lib/shopWebView.js"
import { reconnectGuestOrder } from "../../app/frontend/lib/shopGuestSession.js"

const POINT_A = "2fdee1ac-4674-41ee-b89e-87b45643f789"
const OTHER = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

describe("Telegram WebView detection (not auth)", () => {
  it("detects Telegram Android/iOS In-App UA", () => {
    assert.equal(isTelegramInAppBrowser("Mozilla/5.0 Telegram-Android"), true)
    assert.equal(isTelegramInAppBrowser("Mozilla/5.0 (iPhone) Telegram"), true)
  })

  it("does not treat Chrome as Telegram WebView", () => {
    assert.equal(
      isTelegramInAppBrowser(
        "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/126.0.0.0 Mobile Safari/537.36"
      ),
      false
    )
  })
})

describe("API same-origin / cookies", () => {
  it("shop API prefix is same-origin (no extra CORS)", () => {
    assert.equal(shopApiUsesSameOrigin("/shop/api"), true)
    assert.equal(shopApiUsesSameOrigin("https://evil.example/api"), false)
  })

  it("fetch credentials stay same-origin for session cookies", () => {
    assert.equal(shopFetchCredentials(), "same-origin")
  })
})

describe("storage fallback", () => {
  it("probeStorage false when storage throws", () => {
    const throwing = {
      getItem() {
        throw new Error("SecurityError")
      },
      setItem() {
        throw new Error("SecurityError")
      },
      removeItem() {
        throw new Error("SecurityError")
      }
    }
    assert.equal(probeStorage(throwing), false)
  })

  it("safeWebStorage memory fallback reads/writes without throw", () => {
    const throwing = {
      getItem() {
        throw new Error("SecurityError")
      },
      setItem() {
        throw new Error("SecurityError")
      },
      removeItem() {
        throw new Error("SecurityError")
      }
    }
    const s = safeWebStorage("session", { sessionStorage: throwing })
    assert.doesNotThrow(() => s.setItem("k", "v"))
    assert.equal(s.getItem("k"), "v")
    s.removeItem("k")
    assert.equal(s.getItem("k"), null)
  })
})

describe("desktop APIs / SPA nav / viewport", () => {
  it("internal hash shop routes stay in WebView", () => {
    assert.equal(shopSpaHrefStaysInWebView("#/product/1"), true)
    assert.equal(shopSpaHrefStaysInWebView("/shop?tenant_id=" + POINT_A), true)
    assert.equal(shopSpaHrefStaysInWebView("https://t.me/something"), false)
  })

  it("sets --shop-vvh from visualViewport height", () => {
    const props = {}
    const root = { style: { setProperty: (k, v) => { props[k] = v } } }
    applyShopVisualViewport(root, { height: 640 })
    assert.equal(props["--shop-vvh"], "640px")
  })

  it("installShopWebViewCompat is safe without visualViewport", () => {
    const props = {}
    const env = {
      document: { documentElement: { style: { setProperty: (k, v) => { props[k] = v } } } },
      innerHeight: 700
    }
    const teardown = installShopWebViewCompat(env)
    assert.equal(typeof teardown, "function")
    teardown()
    assert.equal(props["--shop-vvh"], "700px")
  })
})

describe("tenant reopen / cold start / cache key", () => {
  it("cold start order is html → js → svelte → tenant → storage → api", () => {
    assert.deepEqual(shopColdStartSteps(), ["html", "js", "svelte", "tenant", "storage", "api"])
  })

  it("reopen prefers URL tenant_id over cached tenant", () => {
    assert.equal(tenantOnReopen({ urlTenant: POINT_A, cachedTenant: OTHER }), POINT_A)
    assert.equal(tenantOnReopen({ urlTenant: "  ", cachedTenant: OTHER }), OTHER)
  })

  it("catalog cache key is tenant-scoped", () => {
    assert.equal(catalogCacheKey(POINT_A), `coffeeos_shop_catalog_v1:${POINT_A}`)
    assert.notEqual(catalogCacheKey(POINT_A), catalogCacheKey(OTHER))
  })
})

describe("sessionStorage throw in guest reconnect", () => {
  const original = globalThis.sessionStorage

  afterEach(() => {
    globalThis.sessionStorage = original
  })

  it("reconnectGuestOrder does not throw when sessionStorage throws", async () => {
    globalThis.sessionStorage = {
      getItem() {
        throw new Error("SecurityError")
      },
      setItem() {
        throw new Error("SecurityError")
      },
      removeItem() {
        throw new Error("SecurityError")
      }
    }
    const result = await reconnectGuestOrder(async () => ({ ok: true }))
    assert.equal(result, null)
  })
})
