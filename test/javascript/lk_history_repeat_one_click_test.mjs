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

describe("TASK_94 Патч 1 — результат оплаты ЛК → Repeat", () => {
  const histOrder = {
    id: "hist-1",
    items: [
      { product_id: "p1", quantity: 1, selected_modifiers: [] },
      { product_id: "p2", quantity: 2, selected_modifiers: [] }
    ]
  }

  function payOut(state, extra = {}) {
    return {
      fsm: { state },
      state,
      statusText: "",
      errorText: state === "SUCCESS" ? "" : "Ошибка оплаты",
      showFallbackMethods: state !== "SUCCESS",
      showRetry: false,
      openPaymentSheet: false,
      savedCards: [ { id: "c1" }, { id: "c2" } ],
      resetAfterMs: 3000,
      error_code: state === "SUCCESS" ? "" : "1051",
      ...extra
    }
  }

  async function runWith(out) {
    const mod = await import("../../app/frontend/lib/historyRepeatAdapter.js")
    const store = await import("../../app/frontend/lib/repeatInlinePayUiStore.js")
    const navigate = mock.fn(async () => {})
    const openPaymentSheet = mock.fn(async () => {})
    const setTimeoutFn = mock.fn(() => 0)
    const result = await mod.runHistoryRepeatPayFlow({
      order: histOrder,
      api: async () => ({}),
      createOrder: async () => ({ orderId: "new-99" }),
      payFlow: async () => out,
      navigate,
      openPaymentSheet,
      setTimeoutFn
    })
    let ui
    const unsub = store.repeatInlinePayUi.subscribe((v) => { ui = v })
    unsub()
    return { result, navigate, openPaymentSheet, setTimeoutFn, ui }
  }

  it("CONFIRMED → главный экран `/`, таймеры не ставятся, inline UI сброшен", async () => {
    const r = await runWith(payOut("SUCCESS"))
    assert.equal(r.navigate.mock.callCount(), 1)
    assert.equal(r.navigate.mock.calls[0].arguments[0], "/")
    assert.equal(r.openPaymentSheet.mock.callCount(), 0)
    assert.equal(r.setTimeoutFn.mock.callCount(), 0, "reset-таймер после CONFIRMED не должен жить")
    assert.equal(r.ui.busy, false)
    assert.equal(r.ui.activeKey, null)
  })

  it("REJECTED → существующий экран оплаты (карты/СБП), не `/`", async () => {
    const r = await runWith(payOut("FALLBACK"))
    assert.equal(r.navigate.mock.callCount(), 0)
    assert.equal(r.openPaymentSheet.mock.callCount(), 1)
    const [item, opts] = r.openPaymentSheet.mock.calls[0].arguments
    assert.equal(item.product_id, "p1")
    assert.equal(opts?.preferNewCard, false, "сохранённые карты остаются доступны")
  })

  it("CANCELED → те же гарантии, что REJECTED", async () => {
    const r = await runWith(payOut("ERROR", { error_code: "CANCELED" }))
    assert.equal(r.navigate.mock.callCount(), 0)
    assert.equal(r.openPaymentSheet.mock.callCount(), 1)
  })

  it("нет карт (существующая ветка openPaymentSheet) → форма новой карты, не `/`", async () => {
    const r = await runWith(payOut("FALLBACK", { openPaymentSheet: true, savedCards: [] }))
    assert.equal(r.navigate.mock.callCount(), 0)
    assert.equal(r.openPaymentSheet.mock.callCount(), 1)
    assert.equal(r.openPaymentSheet.mock.calls[0].arguments[1]?.preferNewCard, true)
  })

  it("сеть/timeout (showRetry) → остаёмся с повтором, без навигации", async () => {
    const r = await runWith(payOut("ERROR", { showRetry: true, showFallbackMethods: false }))
    assert.equal(r.navigate.mock.callCount(), 0)
    assert.equal(r.openPaymentSheet.mock.callCount(), 0)
  })
})

describe("TASK_94 Патч 1 — regression: checkout и Quick Repeat вне ЛК", () => {
  it("Checkout успех по-прежнему через /payment-result, отказ — status=fail", () => {
    const src = readFileSync(join(root, "app/frontend/routes/Checkout.svelte"), "utf8")
    assert.match(src, /push\(`\/payment-result\?status=ok&order_id=\$\{orderId\}`\)/)
    assert.match(src, /push\(`\/payment-result\?status=fail&order_id=\$\{orderId\}`\)/)
    assert.doesNotMatch(src, /historyRepeatAdapter/)
  })

  it("RepeatSection (Quick Repeat) не использует навигацию ЛК-повтора", () => {
    const src = readFileSync(join(root, "app/frontend/components/RepeatSection.svelte"), "utf8")
    assert.doesNotMatch(src, /historyRepeatAdapter/)
    assert.match(src, /runRepeatWidgetPayFlow/)
  })
})
