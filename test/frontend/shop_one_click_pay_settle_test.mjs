/**
 * waitForOrderSettled: cable accepted → всё равно finalize (saved_card / GetState).
 * Запуск: node --test test/frontend/shop_one_click_pay_settle_test.mjs
 */
import { describe, it } from "node:test"
import assert from "node:assert/strict"
import { waitForOrderSettled } from "../../app/frontend/lib/shopOneClickPay.js"

describe("waitForOrderSettled", () => {
  it("calls finalize when cable reports accepted (not cable-only resolve)", async () => {
    const calls = []
    const api = async (path, opts) => {
      calls.push({ path, method: opts?.method })
      return {
        payment_settled: true,
        status: "accepted",
        saved_card: { id: "card-1", masked_pan: "430000******0777" }
      }
    }

    const settled = await waitForOrderSettled(api, {
      orderId: "ord-1",
      reconnectToken: "tok-1",
      subscribe: ({ onStatus }) => {
        queueMicrotask(() => onStatus({ status: "accepted", payment_settled: true }))
        return () => {}
      }
    })

    assert.equal(settled.saved_card.id, "card-1")
    assert.ok(
      calls.some((c) => c.path.includes("/orders/ord-1/finalize") && c.method === "POST"),
      `expected finalize POST, got ${JSON.stringify(calls)}`
    )
  })

  it("poll finalize returns saved_card without cable", async () => {
    let n = 0
    const api = async () => {
      n += 1
      if (n < 2) return { payment_settled: false, status: "pending_payment" }
      return {
        payment_settled: true,
        status: "accepted",
        saved_card: { id: "card-2", masked_pan: "430000******0888" }
      }
    }

    const settled = await waitForOrderSettled(api, {
      orderId: "ord-2",
      reconnectToken: null,
      subscribe: () => () => {}
    })

    assert.equal(settled.saved_card.id, "card-2")
    assert.ok(n >= 2)
  })
})
