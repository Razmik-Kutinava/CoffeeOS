/**
 * #37 Шаг 5 — Android/Desktop FCM push subscribe [RED / TDD].
 *
 * node --test test/javascript/order_status_push_subscribe_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import { subscribeOrderPush } from "../../app/frontend/lib/orderStatusNotifyActions.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const accordionPath = join(
  root,
  "app/frontend/components/ActiveOrdersAccordion.svelte"
)

describe("subscribeOrderPush (#37 step 5)", () => {
  it("on granted+ok: success label and isLoading false", async () => {
    const toasts = []
    const result = await subscribeOrderPush({
      registerShopPushImpl: async () => ({ ok: true, registered: true }),
      onToast: (msg) => toasts.push(msg)
    })

    assert.equal(result.ok, true)
    assert.equal(result.isLoading, false)
    assert.match(result.primaryLabel, /Уведомления включены/)
    assert.equal(toasts.length, 0)
  })

  it("on denied: soft toast and idle label", async () => {
    const toasts = []
    const result = await subscribeOrderPush({
      registerShopPushImpl: async () => ({
        ok: false,
        reason: "denied",
        permission: "denied"
      }),
      onToast: (msg) => toasts.push(msg)
    })

    assert.equal(result.ok, false)
    assert.equal(result.isLoading, false)
    assert.match(result.primaryLabel, /Уведомление о готовности/)
    assert.ok(toasts.some((t) => /запрещены/i.test(t)))
  })

  it("on network/register failure: network toast", async () => {
    const toasts = []
    const result = await subscribeOrderPush({
      registerShopPushImpl: async () => {
        throw new Error("network boom")
      },
      onToast: (msg) => toasts.push(msg)
    })

    assert.equal(result.ok, false)
    assert.equal(result.isLoading, false)
    assert.match(result.primaryLabel, /Уведомление о готовности/)
    assert.ok(toasts.some((t) => /сеть|уведомлен/i.test(t)))
  })
})

describe("ActiveOrdersAccordion wires push subscribe (#37 step 5 / #41)", () => {
  it("imports subscribeOrderPush and handles push kind in onAction", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /subscribeOrderPush/)
    assert.match(src, /kind === ["']push["']|kind === 'push'/)
    assert.match(src, /onAction/)
  })
})
