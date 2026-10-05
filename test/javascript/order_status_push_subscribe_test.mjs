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
  resumePushAfterSettings,
  pushRegisteredStorageKey,
  openNotificationSettings,
  PUSH_DENIED_TOAST,
  PUSH_OPEN_SETTINGS_CTA,
  PUSH_WATCH_READINESS_CTA,
  PUSH_SETTINGS_FALLBACK
} from "../../app/frontend/lib/orderStatusNotifyActions.js"
import { registerShopPush } from "../../app/frontend/lib/firebasePush.js"

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

  it("#94: OrderStatus chat CTA uses openSupportChat (not dead deep link only)", () => {
    const orderStatusPath = new URL(
      "../../app/frontend/routes/OrderStatus.svelte",
      import.meta.url
    )
    const src = readFileSync(orderStatusPath, "utf8")
    assert.match(src, /openSupportChat/)
    assert.match(src, /kind === ["']chat["']/)
    assert.match(src, /SUPPORT_TELEGRAM_URL/)
  })

  it("#94: application.js listens for coffeeos_navigate from FCM SW", () => {
    const appPath = new URL(
      "../../app/frontend/entrypoints/application.js",
      import.meta.url
    )
    const src = readFileSync(appPath, "utf8")
    assert.match(src, /coffeeos_navigate/)
    assert.match(src, /handleCoffeeosNavigateMessage|serviceWorker\.addEventListener/)
    assert.match(src, /handleCoffeeosHashBoot/)
  })

  it("#94: firebase SW openWindow still posts coffeeos_navigate when possible", () => {
    const swPath = new URL(
      "../../app/views/shop/firebase_sw/show.js.erb",
      import.meta.url
    )
    const src = readFileSync(swPath, "utf8")
    assert.match(src, /openWindow/)
    assert.match(src, /postMessage\(\s*\{\s*type:\s*"coffeeos_navigate"/)
  })

  it("#99: firebasePush.js imported statically (no async import before permission)", () => {
    const src = readFileSync(
      join(root, "app/frontend/lib/orderStatusNotifyActions.js"),
      "utf8"
    )
    assert.doesNotMatch(src, /import\(\s*["']\.\/firebasePush\.js["']\s*\)/)
    assert.match(src, /^import\s+\{[^}]*registerShopPush[^}]*\}\s+from\s+["']\.\/firebasePush\.js["']/m)
  })

  it("#94: firebase SW reads title/body from data when notification absent", () => {
    const swPath = new URL(
      "../../app/views/shop/firebase_sw/show.js.erb",
      import.meta.url
    )
    const src = readFileSync(swPath, "utf8")
    assert.match(src, /payload\.data\s*&&\s*payload\.data\.title|data\.title/)
    assert.match(src, /payload\.data\s*&&\s*payload\.data\.body|data\.body/)
  })
})

describe("TASK_90 Patch 1 — resume push after settings (Subtask 7 patch v1)", () => {
  function memStorage() {
    const data = {}
    return {
      data,
      getItem: (k) => (k in data ? data[k] : null),
      setItem: (k, v) => {
        data[k] = String(v)
      }
    }
  }

  for (const permission of ["denied", "default"]) {
    it(`armed + permission ${permission}: registerShopPush not called`, async () => {
      let calls = 0
      const result = await resumePushAfterSettings({
        armed: true,
        permission,
        registerShopPushImpl: async () => {
          calls += 1
          return { ok: true }
        }
      })
      assert.equal(calls, 0)
      assert.equal(result.resumed, false)
    })
  }

  it("not armed (no prior denied): granted does not auto-register", async () => {
    let calls = 0
    const result = await resumePushAfterSettings({
      armed: false,
      permission: "granted",
      registerShopPushImpl: async () => {
        calls += 1
        return { ok: true }
      }
    })
    assert.equal(calls, 0)
    assert.equal(result.resumed, false)
  })

  it("full chain: denied → settings → granted → return → registerShopPush once", async () => {
    const storage = memStorage()
    let permission = "denied"
    let registerCalls = 0
    const registerShopPushImpl = async () => {
      registerCalls += 1
      return permission === "granted"
        ? { ok: true, registered: true }
        : { ok: false, reason: "denied", permission }
    }

    const first = await subscribeOrderPush({ registerShopPushImpl, onToast: () => {}, storage })
    assert.equal(first.openSettings, true)
    assert.equal(registerCalls, 1)

    const settings = openNotificationSettings({ openSettings: () => false })
    assert.equal(settings.fallbackInstruction, PUSH_SETTINGS_FALLBACK)

    permission = "granted"
    const resumed = await resumePushAfterSettings({
      armed: first.openSettings === true,
      permission,
      registerShopPushImpl,
      onToast: () => {},
      storage
    })
    assert.equal(registerCalls, 2)
    assert.equal(resumed.resumed, true)
    assert.equal(resumed.ok, true)
    assert.match(resumed.primaryLabel, /Уведомления включены/)
    assert.equal(storage.getItem(pushRegisteredStorageKey()), "true")
  })

  it("granted but register fails: resumed, not ok, no throw", async () => {
    const result = await resumePushAfterSettings({
      armed: true,
      permission: "granted",
      registerShopPushImpl: async () => {
        throw new Error("network boom")
      },
      onToast: () => {}
    })
    assert.equal(result.resumed, true)
    assert.equal(result.ok, false)
  })

  it("reads Notification.permission when permission not injected", async () => {
    globalThis.Notification = { permission: "granted" }
    let calls = 0
    try {
      const result = await resumePushAfterSettings({
        armed: true,
        registerShopPushImpl: async () => {
          calls += 1
          return { ok: true }
        },
        storage: null
      })
      assert.equal(calls, 1)
      assert.equal(result.ok, true)
    } finally {
      delete globalThis.Notification
    }
  })

  it("accordion: visibilitychange + pageshow re-check while recovery is shown", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /resumePushAfterSettings/)
    assert.match(src, /addEventListener\(\s*["']visibilitychange["']/)
    assert.match(src, /addEventListener\(\s*["']pageshow["']/)
    assert.match(src, /removeEventListener\(\s*["']visibilitychange["']/)
    assert.match(src, /removeEventListener\(\s*["']pageshow["']/)
    assert.match(src, /armed:\s*pushRecovery/)
    assert.doesNotMatch(src, /orderStatusCtaMachine/)
  })
})

describe("registerShopPush — iOS user gesture (#99)", () => {
  function installNotification(permission, calls) {
    const Notification = {
      requestPermission: () => {
        calls.push("requestPermission")
        return Promise.resolve(permission)
      }
    }
    globalThis.window = { Notification }
    globalThis.Notification = Notification
  }

  function removeNotification() {
    delete globalThis.window
    delete globalThis.Notification
  }

  function fakeDeps(calls, { supported = true, configured = true } = {}) {
    return {
      isSupported: async () => {
        calls.push("isSupported")
        return supported
      },
      firebaseClientConfigured: () => {
        calls.push("firebaseClientConfigured")
        return configured
      },
      getToken: async () => {
        calls.push("getToken")
        return "tok-99"
      },
      registerToken: async (token) => {
        calls.push(`registerToken:${token}`)
      }
    }
  }

  it("calls requestPermission synchronously, before any await", async () => {
    const calls = []
    installNotification("granted", calls)
    try {
      const pending = registerShopPush({ deps: fakeDeps(calls) })
      assert.deepEqual(calls, ["requestPermission"])
      await pending
    } finally {
      removeNotification()
    }
  })

  it("granted: requestPermission → isSupported → firebaseClientConfigured → getToken → register", async () => {
    const calls = []
    installNotification("granted", calls)
    try {
      const result = await registerShopPush({ deps: fakeDeps(calls) })
      assert.deepEqual(calls, [
        "requestPermission",
        "isSupported",
        "firebaseClientConfigured",
        "getToken",
        "registerToken:tok-99"
      ])
      assert.equal(result.ok, true)
      assert.equal(result.token, "tok-99")
    } finally {
      removeNotification()
    }
  })

  for (const permission of ["denied", "default"]) {
    it(`${permission}: no Firebase calls, resolves without throwing`, async () => {
      const calls = []
      installNotification(permission, calls)
      try {
        const result = await registerShopPush({ deps: fakeDeps(calls) })
        assert.deepEqual(calls, ["requestPermission"])
        assert.equal(result.ok, false)
        assert.equal(result.reason, "denied")
        assert.equal(result.permission, permission)
      } finally {
        removeNotification()
      }
    })
  }

  it("granted but Firebase unsupported: stops before config/getToken", async () => {
    const calls = []
    installNotification("granted", calls)
    try {
      const result = await registerShopPush({ deps: fakeDeps(calls, { supported: false }) })
      assert.deepEqual(calls, ["requestPermission", "isSupported"])
      assert.equal(result.reason, "unsupported")
    } finally {
      removeNotification()
    }
  })

  it("granted but no Firebase config: stops before getToken", async () => {
    const calls = []
    installNotification("granted", calls)
    try {
      const result = await registerShopPush({ deps: fakeDeps(calls, { configured: false }) })
      assert.deepEqual(calls, ["requestPermission", "isSupported", "firebaseClientConfigured"])
      assert.equal(result.reason, "no_config")
    } finally {
      removeNotification()
    }
  })

  it("no Notification API: requestPermission not called, no Firebase calls", async () => {
    const calls = []
    globalThis.window = {}
    try {
      const result = await registerShopPush({ deps: fakeDeps(calls) })
      assert.deepEqual(calls, [])
      assert.equal(result.ok, false)
      assert.equal(result.reason, "no_notification_api")
    } finally {
      removeNotification()
    }
  })

  it("accordion path: subscribeOrderPush reaches requestPermission synchronously", async () => {
    const calls = []
    installNotification("denied", calls)
    try {
      const pending = subscribeOrderPush({ onToast: () => {}, storage: null })
      assert.deepEqual(calls, ["requestPermission"])
      const result = await pending
      assert.equal(result.ok, false)
      assert.equal(result.error, "denied")
    } finally {
      removeNotification()
    }
  })
})
