/**
 * TASK_94: ЛК history → Repeat → existing one-click pay flow.
 *
 * node --test test/javascript/lk_history_repeat_one_click_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, mock, beforeEach, afterEach } from "node:test"
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")

describe("TASK_94 — Profile / OrderReceipt wire (not stub)", () => {
  it("Profile shop-lk-repeat-btn starts history repeat, not only openReceipt", () => {
    const src = readFileSync(join(root, "app/frontend/routes/Profile.svelte"), "utf8")
    assert.match(src, /data-testid="shop-lk-repeat-btn"/)
    assert.match(src, /runHistoryRepeatPayFlow|startHistoryRepeat/)
    // repeat button must not be solely openReceipt(order.id)
    const repeatBtn = src.match(
      /data-testid="shop-lk-repeat-btn"[^>]*onclick=\{([^}]+)\}/
    )
    assert.ok(repeatBtn, "repeat button onclick present")
    assert.doesNotMatch(repeatBtn[1], /openReceipt\(order\.id\)/)
  })

  it("OrderReceipt ПОВТОРИТЬ uses history pay flow, not empty stub", () => {
    const src = readFileSync(join(root, "app/frontend/routes/OrderReceipt.svelte"), "utf8")
    assert.match(src, /data-testid="shop-order-repeat-stub"/)
    assert.match(src, /runHistoryRepeatPayFlow|startHistoryRepeat/)
    assert.doesNotMatch(
      src,
      /function onRepeatStub\(\)\s*\{\s*\/\*\s*Subtask 12/
    )
  })
})

describe("TASK_94 — historyRepeatAdapter", () => {
  it("exports mapper + createOrder + runHistoryRepeatPayFlow using existing pay helpers", async () => {
    const src = readFileSync(
      join(root, "app/frontend/lib/historyRepeatAdapter.js"),
      "utf8"
    )
    assert.match(src, /export function historyOrderItemsToRepeatItems/)
    assert.match(src, /export async function createOrderFromHistoryOrder/)
    assert.match(src, /export async function runHistoryRepeatPayFlow/)
    assert.match(src, /createRepeatInlineOrder|addToCart/)
    assert.match(src, /runRepeatWidgetPayFlow/)
    assert.match(src, /patchRepeatInlinePayUi|repeatInlinePayUi/)
    // must not invent a second T-Bank client
    assert.doesNotMatch(src, /tinkoff|stripe|TBankAdapter/i)
  })

  it("maps historical order lines to product_id + modifiers + qty", async () => {
    const { historyOrderItemsToRepeatItems } = await import(
      "../../app/frontend/lib/historyRepeatAdapter.js"
    )
    const mapped = historyOrderItemsToRepeatItems({
      id: "hist-1",
      items: [
        {
          product_id: "p1",
          quantity: 2,
          selected_modifiers: [ { id: "m1", price: 10 } ],
          product_name: "Латте"
        },
        { product_id: "p2", quantity: 1, selected_modifiers: [], product_name: "Круассан" }
      ]
    })
    assert.equal(mapped.length, 2)
    assert.equal(mapped[0].product_id, "p1")
    assert.equal(mapped[0].quantity, 2)
    assert.deepEqual(mapped[0].modifier_options.selected_modifiers, [
      { id: "m1", price: 10 }
    ])
    assert.equal(mapped[1].product_id, "p2")
  })

  it("createOrderFromHistoryOrder clears cart, adds all lines, POSTs new order; does not PATCH historical", async () => {
    const mod = await import("../../app/frontend/lib/historyRepeatAdapter.js")
    const calls = []
    const api = async (path, opts = {}) => {
      calls.push({ path, method: opts.method || "GET", body: opts.body })
      if (path === "/cart" && opts.method === "DELETE") return {}
      if (path === "/orders" && opts.method === "POST") {
        return { order_id: "new-99", id: "new-99" }
      }
      throw new Error(`unexpected ${opts.method} ${path}`)
    }
    const addCalls = []
    const { orderId } = await mod.createOrderFromHistoryOrder(
      {
        id: "hist-1",
        items: [
          { product_id: "p1", quantity: 1, selected_modifiers: [] },
          { product_id: "p2", quantity: 2, selected_modifiers: [] }
        ]
      },
      {
        api,
        loadProfile: () => ({ name: "Test", email: "t@test.com" }),
        addToCartFn: async (payload) => {
          addCalls.push(payload)
          return {}
        }
      }
    )

    assert.equal(orderId, "new-99")
    assert.equal(addCalls.length, 2)
    assert.equal(addCalls[1].product_id, "p2")
    assert.equal(addCalls[1].quantity, 2)
    assert.ok(calls.some((c) => c.path === "/cart" && c.method === "DELETE"))
    assert.ok(calls.some((c) => c.path === "/orders" && c.method === "POST"))
    assert.ok(!calls.some((c) => String(c.path).includes("hist-1")))
    const post = calls.find((c) => c.path === "/orders" && c.method === "POST")
    const body = JSON.parse(post.body)
    assert.equal(body.defer_payment_init, true)
  })
})
