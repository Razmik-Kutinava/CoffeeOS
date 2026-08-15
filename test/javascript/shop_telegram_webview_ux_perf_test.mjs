/**
 * #68 Telegram WebView UX / Performance (catalog SWR, retry, images, error kinds).
 * node --test test/javascript/shop_telegram_webview_ux_perf_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach } from "node:test"
import { readFileSync } from "node:fs"
import path from "node:path"
import { pathToFileURL } from "node:url"
import { fileURLToPath } from "node:url"

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(__dirname, "../..")
const src = (rel) => readFileSync(path.join(root, rel), "utf8")

function mockStorage() {
  const map = new Map()
  return {
    getItem(k) {
      return map.get(k) ?? null
    },
    setItem(k, v) {
      map.set(k, String(v))
    },
    removeItem(k) {
      map.delete(k)
    }
  }
}

const TENANT = "2fdee1ac-4674-41ee-b89e-87b45643f789"
const CATS = [{ id: "c1", name: "Черный", products: [{ id: "p1", name: "Эспрессо", price: 150 }] }]

let fetchImpl = async () => ({ ok: true, status: 200, json: async () => CATS })
let fetchCalls = 0

function installGlobals(storage) {
  globalThis.localStorage = storage
  globalThis.navigator = { onLine: true }
  globalThis.document = {
    querySelector: (sel) => {
      if (sel === 'meta[name="csrf-token"]') return { getAttribute: () => "csrf" }
      if (sel === 'meta[name="shop-api-key"]') return { getAttribute: () => "" }
      if (sel === 'meta[name="shop-tenant-id"]') return { getAttribute: () => TENANT }
      return null
    }
  }
  globalThis.window = {
    location: { search: `?tenant_id=${TENANT}`, href: `https://x/shop?tenant_id=${TENANT}` }
  }
  fetchCalls = 0
  globalThis.fetch = async (url, opts) => {
    fetchCalls += 1
    return fetchImpl(url, opts)
  }
}

installGlobals(mockStorage())

const catalogUrl = pathToFileURL(path.join(root, "app/frontend/lib/stores/catalog.js")).href
const networkUrl = pathToFileURL(path.join(root, "app/frontend/lib/shopNetwork.js")).href
const catalogMod = await import(`${catalogUrl}?uxperf=${Date.now()}`)
const networkMod = await import(`${networkUrl}?uxperf=${Date.now()}`)

const {
  loadCatalog,
  getCatalogCache,
  invalidateCatalog,
  shouldShowCatalogSkeleton,
  catalogRetryShowsSkeleton,
  CATALOG_CACHE_MAX_AGE_MS
} = catalogMod
const { catalogErrorKind } = networkMod

describe("performance budget / skeleton", () => {
  it("exports shouldShowCatalogSkeleton: no cache → skeleton, cache → first paint", () => {
    assert.equal(typeof shouldShowCatalogSkeleton, "function")
    assert.equal(shouldShowCatalogSkeleton(null), true)
    assert.equal(shouldShowCatalogSkeleton([]), true)
    assert.equal(shouldShowCatalogSkeleton(CATS), false)
  })

  it("retry does not swap visible catalog for skeleton", () => {
    assert.equal(typeof catalogRetryShowsSkeleton, "function")
    assert.equal(catalogRetryShowsSkeleton({ visibleCount: 2 }), false)
    assert.equal(catalogRetryShowsSkeleton({ visibleCount: 0 }), true)
  })
})

describe("catalog SWR + cache invalidation", () => {
  beforeEach(() => {
    invalidateCatalog()
    installGlobals(mockStorage())
    fetchImpl = async () => ({ ok: true, status: 200, json: async () => CATS })
  })

  it("cache key is tenant-scoped", async () => {
    await loadCatalog()
    const raw = globalThis.localStorage.getItem(`coffeeos_shop_catalog_v1:${TENANT}`)
    assert.ok(raw)
    assert.equal(getCatalogCache()[0].id, "c1")
  })

  it("coalesces parallel loadCatalog into one fetch", async () => {
    let release
    fetchImpl = () =>
      new Promise((resolve) => {
        release = () => resolve({ ok: true, status: 200, json: async () => CATS })
      })
    const a = loadCatalog()
    const b = loadCatalog()
    release()
    const [left, right] = await Promise.all([a, b])
    assert.equal(fetchCalls, 1)
    assert.equal(left[0].id, right[0].id)
  })

  it("does not keep expired catalog cache forever", () => {
    assert.equal(typeof CATALOG_CACHE_MAX_AGE_MS, "number")
    assert.ok(CATALOG_CACHE_MAX_AGE_MS > 0)
    assert.ok(CATALOG_CACHE_MAX_AGE_MS < 90 * 24 * 60 * 60 * 1000)
    globalThis.localStorage.setItem(
      `coffeeos_shop_catalog_v1:${TENANT}`,
      JSON.stringify({
        savedAt: "2020-01-01T00:00:00.000Z",
        ttlMs: 90 * 24 * 60 * 60 * 1000,
        payload: CATS
      })
    )
    assert.equal(getCatalogCache(), null)
  })

  it("revalidate still hits API when a fresh cache exists (SWR)", async () => {
    await loadCatalog()
    assert.ok(getCatalogCache()?.length)
    invalidateCatalog()
    fetchCalls = 0
    const next = [{ id: "c2", name: "Молочный", products: [] }]
    fetchImpl = async () => ({ ok: true, status: 200, json: async () => next })
    const cats = await loadCatalog()
    assert.equal(fetchCalls, 1)
    assert.equal(cats[0].id, "c2")
  })
})

describe("network vs server vs empty", () => {
  it("exports catalogErrorKind", () => {
    assert.equal(typeof catalogErrorKind, "function")
  })

  it("classifies TypeError / Failed to fetch as network", () => {
    assert.equal(catalogErrorKind(new TypeError("Failed to fetch"), { online: true }), "network")
    assert.equal(catalogErrorKind(new Error("offline"), { online: false }), "network")
  })

  it("classifies HTTP 4xx/5xx as server, not network", () => {
    const err = new Error("Ошибка сервера. Попробуйте позже.")
    err.httpStatus = 500
    assert.equal(catalogErrorKind(err, { online: true }), "server")
    const notFound = new Error("not found")
    notFound.httpStatus = 404
    assert.equal(catalogErrorKind(notFound, { online: true }), "server")
  })
})

describe("markup: lazy images, CLS, retry/SWR wiring", () => {
  it("catalog cards lazy-load images and keep aspect-ratio + onerror", () => {
    const file = src("app/frontend/components/CategorySection.svelte")
    assert.match(file, /loading=["']lazy["']/)
    assert.match(file, /aspect-\[4\/3\]/)
    assert.match(file, /onerror/)
  })

  it("category page images lazy-load and have onerror fallback", () => {
    const file = src("app/frontend/routes/CategoryProducts.svelte")
    assert.match(file, /loading=["']lazy["']/)
    assert.match(file, /onerror/)
  })

  it("product hero is not lazy (LCP)", () => {
    const file = src("app/frontend/routes/Product.svelte")
    assert.equal(/loading=["']lazy["']/.test(file), false)
  })

  it("Catalog uses cache-first skeleton/retry helpers and error kinds", () => {
    const file = src("app/frontend/routes/Catalog.svelte")
    assert.match(file, /shouldShowCatalogSkeleton/)
    assert.match(file, /catalogRetryShowsSkeleton/)
    assert.match(file, /catalogErrorKind/)
    assert.match(file, /getCatalogCache/)
  })

  it("Catalog listens for online to recover after offline", () => {
    const file = src("app/frontend/routes/Catalog.svelte")
    assert.match(file, /addEventListener\(\s*["']online["']/)
  })
})
