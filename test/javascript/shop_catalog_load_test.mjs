/**
 * #64 catalog load: tenant_id, API error, storage throw, cache fallback.
 * node --test test/javascript/shop_catalog_load_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach } from "node:test"
import path from "node:path"
import { pathToFileURL } from "node:url"
import { fileURLToPath } from "node:url"

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(__dirname, "../..")

function mockStorage(throwing = false) {
  const map = new Map()
  return {
    getItem(k) {
      if (throwing) throw new Error("SecurityError")
      return map.get(k) ?? null
    },
    setItem(k, v) {
      if (throwing) throw new Error("SecurityError")
      map.set(k, String(v))
    },
    removeItem(k) {
      if (throwing) throw new Error("SecurityError")
      map.delete(k)
    }
  }
}

const TENANT = "2fdee1ac-4674-41ee-b89e-87b45643f789"
const CATS = [{ id: "c1", name: "Черный", products: [{ id: "p1", name: "Эспрессо" }] }]

let fetchImpl = async () => ({ ok: true, status: 200, json: async () => CATS })

function installGlobals(storage) {
  globalThis.localStorage = storage
  globalThis.document = {
    querySelector: (sel) => {
      if (sel === 'meta[name="csrf-token"]') return { getAttribute: () => "csrf" }
      if (sel === 'meta[name="shop-api-key"]') return { getAttribute: () => "" }
      if (sel === 'meta[name="shop-tenant-id"]') return { getAttribute: () => TENANT }
      return null
    }
  }
  globalThis.window = { location: { search: `?tenant_id=${TENANT}`, href: `https://x/shop?tenant_id=${TENANT}` } }
  globalThis.fetch = async (url, opts) => fetchImpl(url, opts)
}

installGlobals(mockStorage(false))

const catalogUrl = pathToFileURL(path.join(root, "app/frontend/lib/stores/catalog.js")).href
const { loadCatalog, getCatalogCache, invalidateCatalog } = await import(`${catalogUrl}?t=${Date.now()}`)

describe("loadCatalog", () => {
  beforeEach(() => {
    invalidateCatalog()
    installGlobals(mockStorage(false))
    fetchImpl = async () => ({ ok: true, status: 200, json: async () => CATS })
  })

  it("passes tenant_id from URL to catalog API", async () => {
    let called = ""
    fetchImpl = async (url) => {
      called = String(url)
      return { ok: true, status: 200, json: async () => CATS }
    }
    const cats = await loadCatalog()
    assert.equal(cats[0].name, "Черный")
    assert.match(called, /\/shop\/api\/categories/)
    assert.match(called, new RegExp(`tenant_id=${TENANT}`))
  })

  it("on API 500 sets failure (no cache) by throwing", async () => {
    fetchImpl = async () => ({
      ok: false,
      status: 500,
      statusText: "Server Error",
      json: async () => ({ error: "boom" })
    })
    await assert.rejects(() => loadCatalog(), /boom|сервер/i)
  })

  it("uses cache when API fails and cache is valid", async () => {
    const cats = await loadCatalog()
    assert.equal(cats.length, 1)
    invalidateCatalog()
    fetchImpl = async () => {
      throw new Error("Failed to fetch")
    }
    const cached = await loadCatalog()
    assert.equal(cached[0].id, "c1")
    assert.equal(getCatalogCache()[0].id, "c1")
  })

  it("succeeds when localStorage throws and API returns catalog", async () => {
    installGlobals(mockStorage(true))
    invalidateCatalog()
    const cats = await loadCatalog()
    assert.equal(cats[0].name, "Черный")
  })

  it("does not reuse another tenant catalog cache on reopen", async () => {
    await loadCatalog()
    assert.equal(getCatalogCache()[0].id, "c1")
    invalidateCatalog()
    globalThis.window = {
      location: {
        search: `?tenant_id=${"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"}`,
        href: "https://x/shop?tenant_id=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
      }
    }
    fetchImpl = async () => {
      throw new Error("Failed to fetch")
    }
    await assert.rejects(() => loadCatalog(), /Failed to fetch/)
  })
})
