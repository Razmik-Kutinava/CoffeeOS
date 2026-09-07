/**
 * #81 — denied → settings + accordion wire [RED / TDD].
 *
 * node --test test/javascript/order_status_push_subscribe_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  subscribeOrderPush,
  openNotificationSettings,
  PUSH_DENIED_TOAST
} from "../../app/frontend/lib/orderStatusNotifyActions.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const accordionPath = join(
  root,
  "app/frontend/components/ActiveOrdersAccordion.svelte"
)

describe("subscribeOrderPush (#37 step 5 / #81)", () => {
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
    assert.equal(result.openSettings, undefined)
  })

  it("on denied: soft toast, idle label, openSettings flag", async () => {
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
    assert.equal(result.error, "denied")
    assert.equal(result.openSettings, true)
    assert.match(result.primaryLabel, /Уведомление о готовности/)
    assert.ok(toasts.some((t) => t === PUSH_DENIED_TOAST))
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
    assert.notEqual(result.openSettings, true)
  })
})

describe("openNotificationSettings (#81)", () => {
  it("calls injectable openSettings and returns opened", () => {
    let called = 0
    const result = openNotificationSettings({
      openSettings: () => {
        called += 1
        return true
      }
    })
    assert.equal(called, 1)
    assert.equal(result.attempted, true)
    assert.equal(result.opened, true)
  })

  it("best-effort: no crash when openSettings fails / missing", () => {
    const result = openNotificationSettings({
      openSettings: () => {
        throw new Error("blocked")
      }
    })
    assert.equal(result.attempted, true)
    assert.equal(result.opened, false)
  })
})

describe("ActiveOrdersAccordion wires push + denied settings (#81)", () => {
  it("imports subscribeOrderPush and handles push kind in onAction", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /subscribeOrderPush/)
    assert.match(src, /kind === ["']push["']|kind === 'push'/)
    assert.match(src, /onAction/)
  })

  it("wires openNotificationSettings on denied toast click", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /openNotificationSettings/)
    assert.match(src, /active-order-notify-toast/)
    assert.match(src, /onclick|on:click/)
  })

  it("opens support chat with default Telegram URL path", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /openSupportChat/)
    assert.match(
      src,
      /SUPPORT_TELEGRAM_URL|shopAboutConfig|supportTelegram|getSupport/
    )
  })
})
