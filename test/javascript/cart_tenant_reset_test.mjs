/**
 * TASK_120 — корзина при переходе в другую точку: сообщение, очистка кэша, DELETE /cart при «Товар недоступен».
 * node --test test/javascript/cart_tenant_reset_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach, afterEach } from "node:test"
import { get } from "svelte/store"

const POINT_A = "2fdee1ac-4674-41ee-b89e-87b45643f789"
const RESET_TEXT = "Корзина очищена: вы перешли в другую точку"

const originals = {
  window: globalThis.window,
  document: globalThis.document,
  localStorage: globalThis.localStorage,
  sessionStorage: globalThis.sessionStorage,
  fetch: globalThis.fetch,
  navigator: globalThis.navigator
}

let calls = []
let routes = {}
let dispatched = []
let listeners = {}

function memoryStorage() {
  const m = new Map()
  return {
    getItem: (k) => (m.has(k) ? m.get(k) : null),
    setItem: (k, v) => m.set(k, String(v)),
    removeItem: (k) => m.delete(k),
    clear: () => m.clear()
  }
}

function jsonResponse(status, body) {
  return {
    ok: status >= 200 && status < 300,
    status,
    statusText: String(status),
    json: async () => body
  }
}

beforeEach(() => {
  calls = []
  routes = {}
  dispatched = []
  listeners = {}
  globalThis.window = {
    location: { search: `?tenant_id=${POINT_A}`, hash: "#/" },
    scrollY: 0,
    addEventListener: (type, fn) => {
      ;(listeners[type] ||= []).push(fn)
    },
    dispatchEvent: (ev) => {
      dispatched.push(ev.type)
      ;(listeners[ev.type] || []).forEach((fn) => fn(ev))
      return true
    }
  }
  globalThis.document = {
    querySelector: (sel) =>
      sel === 'meta[name="csrf-token"]' ? { getAttribute: () => "csrf" } : null
  }
  globalThis.localStorage = memoryStorage()
  globalThis.sessionStorage = memoryStorage()
  Object.defineProperty(globalThis, "navigator", { value: { onLine: true }, configurable: true })
  globalThis.fetch = async (url, opts = {}) => {
    const path = String(url).replace(/^\/shop\/api/, "").replace(/\?.*$/, "")
    const method = opts.method || "GET"
    calls.push(`${method} ${path}`)
    const handler = routes[`${method} ${path}`]
    if (!handler) return jsonResponse(200, { items: [], total: 0 })
    return handler()
  }
})

afterEach(() => {
  for (const [k, v] of Object.entries(originals)) {
    Object.defineProperty(globalThis, k, { value: v, configurable: true, writable: true })
  }
})

const store = await import("../../app/frontend/lib/cartSheetStore.js")
const { addToCart } = await import("../../app/frontend/lib/shopCartAdd.js")
const { readCartCache, writeCartCache } = await import("../../app/frontend/lib/shopCartCache.js")

const STALE = { items: [{ index: 0, product_id: 7, quantity: 1, line_total: 222 }], total: 222 }

describe("TASK_120 cart reset flag", () => {
  it("exports the customer message", () => {
    assert.equal(store.CART_TENANT_RESET_MESSAGE, RESET_TEXT)
  })

  it("Subtask 2: refreshCartSheet with cart_reset clears cache/store and shows message", async () => {
    writeCartCache(STALE)
    store.cartItems.set(STALE.items)
    routes["GET /cart"] = () => jsonResponse(200, { items: [], total: 0, cart_reset: true })

    await store.refreshCartSheet()

    assert.deepEqual(get(store.cartItems), [])
    assert.equal(get(store.cartTotal), 0)
    assert.deepEqual(readCartCache()?.items, [])
    assert.equal(get(store.cartSheetError), RESET_TEXT)
  })

  it("Subtask 3/4: no flag — no message", async () => {
    routes["GET /cart"] = () => jsonResponse(200, { items: [], total: 0 })

    await store.refreshCartSheet()

    assert.equal(get(store.cartSheetError), null)
  })

  it("Subtask 2: flag on DELETE line response survives the follow-up refresh", async () => {
    store.cartItems.set(STALE.items)
    routes["DELETE /cart/items/0"] = () => jsonResponse(200, { items: [], total: 0, cart_reset: true })
    routes["GET /cart"] = () => jsonResponse(200, { items: [], total: 0 })

    await store.removeCartLine(0)

    assert.equal(get(store.cartSheetError), RESET_TEXT)
  })

  it("Subtask 2: shop:cart-reset event shows the message", () => {
    store.bindCartSheetEvents()
    store.clearCartSheetError()

    globalThis.window.dispatchEvent({ type: "shop:cart-reset" })

    assert.equal(get(store.cartSheetError), RESET_TEXT)
  })

  it("Subtask 2: addToCart with cart_reset dispatches shop:cart-reset", async () => {
    routes["POST /cart/add"] = () =>
      jsonResponse(200, { cart: [{ index: 0, product_id: 9, quantity: 1 }], total: 150, cart_reset: true })

    await addToCart({ product_id: 9, quantity: 1 }, { product: { id: 9, name: "Латте" } })

    assert.ok(dispatched.includes("shop:cart-reset"), `events: ${dispatched.join(",")}`)
  })

  it("addToCart without flag does not dispatch shop:cart-reset", async () => {
    routes["POST /cart/add"] = () => jsonResponse(200, { cart: [], total: 0 })

    await addToCart({ product_id: 9, quantity: 1 }, { product: { id: 9, name: "Латте" } })

    assert.ok(!dispatched.includes("shop:cart-reset"))
  })
})

describe("TASK_120 Subtask 5: 404 «Товар недоступен»", () => {
  it("refreshCartSheet calls DELETE /cart together with local clear", async () => {
    writeCartCache(STALE)
    routes["GET /cart"] = () => jsonResponse(404, { error: "Товар недоступен" })

    await store.refreshCartSheet()

    assert.ok(calls.includes("DELETE /cart"), `calls: ${calls.join(",")}`)
    assert.deepEqual(get(store.cartItems), [])
    assert.deepEqual(readCartCache()?.items || [], [])
  })

  it("addToCart calls DELETE /cart, clears cache and rethrows", async () => {
    writeCartCache(STALE)
    routes["POST /cart/add"] = () => jsonResponse(404, { error: "Товар недоступен" })

    await assert.rejects(
      addToCart({ product_id: 9, quantity: 1 }, { product: { id: 9, name: "Латте" } }),
      /Товар недоступен/
    )

    assert.ok(calls.includes("DELETE /cart"), `calls: ${calls.join(",")}`)
    assert.equal(readCartCache(), null)
  })

  it("addToCart other 404 (Товар не найден) does not clear server cart", async () => {
    routes["POST /cart/add"] = () => jsonResponse(404, { error: "Товар не найден" })

    await assert.rejects(addToCart({ product_id: 9, quantity: 1 }, { product: { id: 9, name: "Латте" } }))

    assert.ok(!calls.includes("DELETE /cart"))
  })
})
