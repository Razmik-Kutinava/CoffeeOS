/**
 * #87 — после успешного Quick Repeat / card pay корзина очищается (7.1).
 * node --test test/javascript/clear_cart_after_successful_pay_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"

import { clearCartAfterSuccessfulPay } from "../../app/frontend/lib/cartSheetStore.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")

describe("#87 clearCartAfterSuccessfulPay", () => {
  it("DELETEs /cart then refreshes cart sheet", async () => {
    const calls = []
    await clearCartAfterSuccessfulPay({
      api: async (path, opts = {}) => {
        calls.push({ path, method: opts.method || "GET" })
        return { items: [], total: 0 }
      },
      refreshCart: async () => {
        calls.push({ path: "refreshCart", method: "LOCAL" })
      }
    })
    assert.deepEqual(calls, [
      { path: "/cart", method: "DELETE" },
      { path: "refreshCart", method: "LOCAL" }
    ])
  })

  it("does not throw when refresh omitted (api clear still runs)", async () => {
    const calls = []
    await clearCartAfterSuccessfulPay({
      api: async (path, opts = {}) => {
        calls.push({ path, method: opts.method || "GET" })
        return {}
      }
    })
    assert.deepEqual(calls, [{ path: "/cart", method: "DELETE" }])
  })
})

describe("#87 widgetRepeatPayFlow clears cart on confirmed (source)", () => {
  it("imports and awaits clearCartAfterSuccessfulPay after confirmed", () => {
    const src = readFileSync(join(root, "app/frontend/lib/widgetRepeatPayFlow.js"), "utf8")
    assert.match(src, /clearCartAfterSuccessfulPay/)
    assert.match(
      src,
      /result\.kind === ["']confirmed["'][\s\S]*clearCartAfterSuccessfulPay/,
      "clear cart only on confirmed pay success"
    )
  })
})

describe("#87 receipt composition is Order not cart (source)", () => {
  it("receiptView reads order.items and is non-interactive", () => {
    const src = readFileSync(join(root, "app/frontend/lib/activeOrdersAccordion.js"), "utf8")
    assert.match(src, /order\?\.items/)
    assert.match(src, /interactive:\s*false/)
  })
})
