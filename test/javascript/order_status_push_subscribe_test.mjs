/**
 * #81 / #92 — denied → settings + recovery UI [TDD].
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
  PUSH_DENIED_TOAST,
  PUSH_OPEN_SETTINGS_CTA,
  PUSH_WATCH_READINESS_CTA,
  PUSH_SETTINGS_FALLBACK
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

describe("openNotificationSettings (#81 / #92)", () => {
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
    assert.equal(result.fallbackInstruction, null)
  })

  it("best-effort: no crash when openSettings fails / missing", () => {
    const result = openNotificationSettings({
      openSettings: () => {
        throw new Error("blocked")
      }
    })
    assert.equal(result.attempted, true)
    assert.equal(result.opened, false)
    assert.equal(result.fallbackInstruction, PUSH_SETTINGS_FALLBACK)
  })

  it("#92: when deep-link unavailable returns fallback instruction", () => {
    const result = openNotificationSettings({
      openSettings: () => false
    })
    assert.equal(result.attempted, true)
    assert.equal(result.opened, false)
    assert.ok(result.fallbackInstruction)
    assert.match(result.fallbackInstruction, /настройк|уведомлен/i)
    assert.equal(result.fallbackInstruction, PUSH_SETTINGS_FALLBACK)
  })

  it("#92: Android intent path attempts openWindow", () => {
    const urls = []
    const result = openNotificationSettings({
      userAgent: "Mozilla/5.0 (Linux; Android 14) Chrome/120.0.0.0 Mobile",
      openWindow: (url) => {
        urls.push(url)
        return { ok: true }
      }
    })
    assert.equal(result.attempted, true)
    assert.equal(result.opened, true)
    // Intent may not reach site settings — fallback always shown on Android path.
    assert.equal(result.fallbackInstruction, PUSH_SETTINGS_FALLBACK)
    assert.equal(urls.length, 1)
    assert.match(urls[0], /intent:\/\/|android\.settings/i)
  })
})

describe("#92 recovery CTA copy", () => {
  it("exports Открыть настройки and Смотреть готовность labels", () => {
    assert.equal(PUSH_OPEN_SETTINGS_CTA, "Открыть настройки")
    assert.equal(PUSH_WATCH_READINESS_CTA, "Смотреть готовность")
    assert.match(PUSH_SETTINGS_FALLBACK, /уведомлен/i)
    assert.match(PUSH_DENIED_TOAST, /запрещены/i)
  })
})

describe("ActiveOrdersAccordion wires push + denied settings (#81 / #92)", () => {
  it("imports subscribeOrderPush and handles push kind in onAction", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /subscribeOrderPush/)
    assert.match(src, /kind === ["']push["']|kind === 'push'/)
    assert.match(src, /onAction/)
  })

  it("wires openNotificationSettings on denied recovery", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /openNotificationSettings/)
    assert.match(src, /result\?\.openSettings|result\.openSettings/)
  })

  it("#92: recovery UI — Открыть настройки + Смотреть готовность", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /active-order-push-recovery/)
    assert.match(src, /active-order-open-settings/)
    assert.match(src, /active-order-watch-readiness/)
    assert.match(src, /PUSH_OPEN_SETTINGS_CTA|Открыть настройки/)
    assert.match(src, /PUSH_WATCH_READINESS_CTA|Смотреть готовность/)
    assert.match(src, /PUSH_DENIED_TOAST/)
  })

  it("#92: Смотреть готовность clears recovery without new state machine", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /active-order-watch-readiness/)
    assert.match(src, /pushRecovery\s*=\s*false|dismissPushRecovery|clearPushRecovery/)
    assert.doesNotMatch(src, /orderStatusCtaMachine/)
  })

  it("#92: fallback instruction shown when settings not opened", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /active-order-settings-fallback/)
    assert.match(src, /fallbackInstruction|PUSH_SETTINGS_FALLBACK|settingsFallback/)
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
