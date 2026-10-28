/**
 * TASK_112 — снимок окружения при открытии витрины (session_open).
 * node --test test/javascript/push_environment_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach, afterEach } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  ENV_PROBE_KEY,
  ENVIRONMENT_EVENTS_URL,
  SESSION_OPEN_GUARD_KEY,
  collectPushEnvironment,
  inAppLabel,
  reportSessionOpenOnce,
  resetSessionOpenGuardForTests,
  storageAvailable,
  uaSnippet
} from "../../app/frontend/lib/pushEnvironment.js"
import {
  navigateToTenant,
  shopTenantRedirectPending
} from "../../app/frontend/lib/shopTenantHeader.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")

const UA = {
  iphoneSafari:
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
  iphoneWebView:
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
  iphoneInstagram:
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 330.0.0.0",
  iphoneFacebook:
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/450.0]",
  androidChrome:
    "Mozilla/5.0 (Linux; Android 14; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36",
  androidWebView:
    "Mozilla/5.0 (Linux; Android 14; Pixel 6; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/126.0.0.0 Mobile Safari/537.36",
  androidTelegram:
    "Mozilla/5.0 (Linux; Android 14; Pixel 6; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/126.0.0.0 Mobile Safari/537.36 Telegram-Android/11.0.0",
  desktopChrome:
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
}

function memoryStorage(initial = {}) {
  const map = new Map(Object.entries(initial))
  return {
    map,
    getItem: (k) => (map.has(k) ? map.get(k) : null),
    setItem: (k, v) => map.set(k, String(v)),
    removeItem: (k) => map.delete(k)
  }
}

function throwingStorage(on = "setItem") {
  const s = memoryStorage()
  s[on] = () => {
    const err = new Error("blocked")
    err.name = on === "setItem" ? "QuotaExceededError" : "SecurityError"
    throw err
  }
  return s
}

/** Окружение «Android Chrome, всё доступно, вкладка браузера». */
function makeEnv(overrides = {}) {
  const env = {
    navigator: {
      userAgent: UA.androidChrome,
      platform: "Linux armv8l",
      maxTouchPoints: 5,
      serviceWorker: {}
    },
    matchMedia: () => ({ matches: false }),
    Notification: { permission: "default" },
    PushManager: function PushManager() {},
    localStorage: memoryStorage(),
    sessionStorage: memoryStorage(),
    ...overrides
  }
  return env
}

describe("TASK_112 Subtask 1 — collectPushEnvironment flags", () => {
  it("Android Chrome tab: all APIs present", () => {
    const out = collectPushEnvironment(makeEnv())
    assert.deepEqual(out, {
      event_kind: "session_open",
      os_family: "android",
      standalone: "browser",
      notification_state: "default",
      push_manager: "available",
      service_worker: "available",
      storage_local: "available",
      storage_session: "available",
      inapp_label: "none",
      ua_snippet: null
    })
  })

  it("standalone via display-mode media query", () => {
    const env = makeEnv({ matchMedia: (q) => ({ matches: q === "(display-mode: standalone)" }) })
    assert.equal(collectPushEnvironment(env).standalone, "standalone")
  })

  it("standalone via iOS navigator.standalone", () => {
    const env = makeEnv()
    env.navigator = { ...env.navigator, userAgent: UA.iphoneSafari, standalone: true }
    env.matchMedia = () => ({ matches: false })
    const out = collectPushEnvironment(env)
    assert.equal(out.standalone, "standalone")
    assert.equal(out.os_family, "ios")
  })

  it("notification permission granted / denied passes through", () => {
    assert.equal(collectPushEnvironment(makeEnv({ Notification: { permission: "granted" } })).notification_state, "granted")
    assert.equal(collectPushEnvironment(makeEnv({ Notification: { permission: "denied" } })).notification_state, "denied")
  })

  it("desktop OS → other", () => {
    const env = makeEnv()
    env.navigator = { ...env.navigator, userAgent: UA.desktopChrome, platform: "Win32", maxTouchPoints: 0 }
    assert.equal(collectPushEnvironment(env).os_family, "other")
  })
})

describe("TASK_112 Subtask 5 — missing or throwing browser APIs → unavailable", () => {
  it("no Notification / PushManager / serviceWorker / matchMedia", () => {
    const env = makeEnv({ Notification: undefined, PushManager: undefined, matchMedia: undefined })
    delete env.Notification
    delete env.PushManager
    delete env.matchMedia
    env.navigator = { userAgent: UA.iphoneSafari, platform: "iPhone", maxTouchPoints: 5 }
    const out = collectPushEnvironment(env)
    assert.equal(out.notification_state, "unavailable")
    assert.equal(out.push_manager, "unavailable")
    assert.equal(out.service_worker, "unavailable")
    assert.equal(out.standalone, "unavailable")
  })

  it("no matchMedia but iOS navigator.standalone=false → browser", () => {
    const env = makeEnv()
    delete env.matchMedia
    env.navigator = { userAgent: UA.iphoneSafari, platform: "iPhone", maxTouchPoints: 5, standalone: false }
    assert.equal(collectPushEnvironment(env).standalone, "browser")
  })

  it("throwing matchMedia and Notification.permission getter do not escape", () => {
    const env = makeEnv({
      matchMedia: () => {
        throw new Error("matchMedia boom")
      }
    })
    Object.defineProperty(env, "Notification", {
      get() {
        throw new Error("Notification boom")
      }
    })
    let out
    assert.doesNotThrow(() => {
      out = collectPushEnvironment(env)
    })
    assert.equal(out.standalone, "unavailable")
    assert.equal(out.notification_state, "unavailable")
  })

  it("unknown permission string → unavailable", () => {
    assert.equal(
      collectPushEnvironment(makeEnv({ Notification: { permission: "prompt" } })).notification_state,
      "unavailable"
    )
  })

  it("collect never calls requestPermission or serviceWorker.register", () => {
    let calls = 0
    const env = makeEnv({
      Notification: {
        permission: "default",
        requestPermission: () => {
          calls += 1
        }
      }
    })
    env.navigator.serviceWorker = {
      register: () => {
        calls += 1
      }
    }
    collectPushEnvironment(env)
    assert.equal(calls, 0)
  })
})

describe("TASK_112 Subtask 4, 11 — storage probe", () => {
  it("working storage → available, probe key removed, existing keys untouched", () => {
    const s = memoryStorage({ shop_selected_tenant: "x", other: "y" })
    assert.equal(storageAvailable(() => s), "available")
    assert.deepEqual([...s.map.keys()].sort(), ["other", "shop_selected_tenant"])
    assert.equal(s.getItem("shop_selected_tenant"), "x")
  })

  it("probe key differs from existing shop keys and the WebView probe", () => {
    assert.notEqual(ENV_PROBE_KEY, "__coffeeos_wv_probe__")
    assert.notEqual(ENV_PROBE_KEY, SESSION_OPEN_GUARD_KEY)
    assert.match(ENV_PROBE_KEY, /env/)
  })

  it("getter throws (SecurityError) → unavailable", () => {
    assert.equal(
      storageAvailable(() => {
        throw new Error("SecurityError")
      }),
      "unavailable"
    )
  })

  it("setItem throws (QuotaExceeded) → unavailable", () => {
    assert.equal(storageAvailable(() => throwingStorage("setItem")), "unavailable")
  })

  it("null storage → unavailable", () => {
    assert.equal(storageAvailable(() => null), "unavailable")
  })

  it("collect: localStorage getter throws → storage_local unavailable, session still available", () => {
    const env = makeEnv()
    Object.defineProperty(env, "localStorage", {
      get() {
        throw new Error("SecurityError")
      }
    })
    const out = collectPushEnvironment(env)
    assert.equal(out.storage_local, "unavailable")
    assert.equal(out.storage_session, "available")
  })

  it("collect leaves no records in working storages", () => {
    const env = makeEnv()
    collectPushEnvironment(env)
    assert.equal(env.localStorage.map.size, 0)
    assert.equal(env.sessionStorage.map.size, 0)
  })
})

describe("TASK_112 Subtask 1, 8 — in-app browser label heuristic", () => {
  it("labels", () => {
    assert.equal(inAppLabel(UA.androidTelegram), "telegram")
    assert.equal(inAppLabel(UA.iphoneInstagram), "instagram")
    assert.equal(inAppLabel(UA.iphoneFacebook), "facebook")
    assert.equal(inAppLabel(UA.androidWebView), "other_inapp")
    assert.equal(inAppLabel(UA.iphoneWebView), "other_inapp")
    assert.equal(inAppLabel(UA.iphoneSafari), "none")
    assert.equal(inAppLabel(UA.androidChrome), "none")
    assert.equal(inAppLabel(UA.desktopChrome), "none")
    assert.equal(inAppLabel(""), "none")
    assert.equal(inAppLabel(undefined), "none")
  })

  it("ua_snippet only for other_inapp, last 300 chars", () => {
    assert.equal(uaSnippet(UA.androidChrome, "none"), null)
    assert.equal(uaSnippet(UA.androidTelegram, "telegram"), null)
    assert.equal(uaSnippet(UA.androidWebView, "other_inapp"), UA.androidWebView)
    const long = `${"a".repeat(400)}TAIL`
    const snip = uaSnippet(long, "other_inapp")
    assert.equal(snip.length, 300)
    assert.ok(snip.endsWith("TAIL"))
  })

  it("collect includes snippet for other_inapp only", () => {
    const env = makeEnv()
    env.navigator = { ...env.navigator, userAgent: UA.androidWebView }
    const out = collectPushEnvironment(env)
    assert.equal(out.inapp_label, "other_inapp")
    assert.equal(out.ua_snippet, UA.androidWebView)
  })
})

describe("TASK_112 Subtask 2, 3, 4 — reportSessionOpenOnce", () => {
  beforeEach(() => resetSessionOpenGuardForTests())
  afterEach(() => resetSessionOpenGuardForTests())

  function sender() {
    const sent = []
    return {
      sent,
      beacon: (url, blob) => {
        sent.push({ via: "beacon", url, blob })
        return true
      }
    }
  }

  it("sends one session_open via beacon to tenant-scoped URL", async () => {
    const env = makeEnv()
    const s = sender()
    const ok = reportSessionOpenOnce({ env, beacon: s.beacon, resolveUrl: (u) => `${u}?tenant_id=T1` })
    assert.equal(ok, true)
    assert.equal(s.sent.length, 1)
    assert.equal(s.sent[0].url, `${ENVIRONMENT_EVENTS_URL}?tenant_id=T1`)
    const body = JSON.parse(await s.sent[0].blob.text())
    assert.equal(body.event_kind, "session_open")
    assert.equal(body.os_family, "android")
    assert.equal("point_id" in body, false)
    assert.equal("tenant_id" in body, false)
  })

  it("second call in same tab (sessionStorage guard) does not send", () => {
    const env = makeEnv()
    const s = sender()
    reportSessionOpenOnce({ env, beacon: s.beacon, resolveUrl: (u) => u })
    resetSessionOpenGuardForTests()
    const again = reportSessionOpenOnce({ env, beacon: s.beacon, resolveUrl: (u) => u })
    assert.equal(again, false)
    assert.equal(s.sent.length, 1)
    assert.equal(env.sessionStorage.getItem(SESSION_OPEN_GUARD_KEY), "1")
  })

  it("storage unavailable → guard in page memory", () => {
    const env = makeEnv()
    Object.defineProperty(env, "sessionStorage", {
      get() {
        throw new Error("SecurityError")
      }
    })
    const s = sender()
    assert.doesNotThrow(() => reportSessionOpenOnce({ env, beacon: s.beacon, resolveUrl: (u) => u }))
    reportSessionOpenOnce({ env, beacon: s.beacon, resolveUrl: (u) => u })
    assert.equal(s.sent.length, 1)
  })

  it("beacon refused → fetch keepalive without await; rejection swallowed, no retry", async () => {
    const env = makeEnv()
    const calls = []
    const fetchFn = (url, init) => {
      calls.push({ url, init })
      return Promise.reject(new Error("offline"))
    }
    const ok = reportSessionOpenOnce({ env, beacon: () => false, fetchFn, resolveUrl: (u) => u })
    assert.equal(ok, true)
    assert.equal(calls.length, 1)
    assert.equal(calls[0].init.method, "POST")
    assert.equal(calls[0].init.keepalive, true)
    await new Promise((r) => setTimeout(r, 0))
    reportSessionOpenOnce({ env, beacon: () => false, fetchFn, resolveUrl: (u) => u })
    assert.equal(calls.length, 1)
  })

  it("beacon and fetch throw synchronously → no exception", () => {
    const env = makeEnv()
    assert.doesNotThrow(() =>
      reportSessionOpenOnce({
        env,
        beacon: () => {
          throw new Error("beacon boom")
        },
        fetchFn: () => {
          throw new Error("fetch boom")
        },
        resolveUrl: () => {
          throw new Error("no window")
        }
      })
    )
  })

  it("never touches push registration APIs", () => {
    let calls = 0
    const env = makeEnv({
      Notification: {
        permission: "default",
        requestPermission: () => {
          calls += 1
        }
      }
    })
    env.navigator.serviceWorker = {
      register: () => {
        calls += 1
      }
    }
    reportSessionOpenOnce({ env, beacon: () => true, resolveUrl: (u) => u })
    assert.equal(calls, 0)
  })
})

describe("TASK_112 Subtask 2 — redirect to another point is visible to App", () => {
  it("navigateToTenant marks redirect pending", () => {
    const assigned = []
    globalThis.window = {
      location: {
        href: "https://codeblack.coffee/shop?tenant_id=A#/",
        hash: "#/",
        assign: (u) => assigned.push(u)
      }
    }
    try {
      assert.equal(shopTenantRedirectPending(), false)
      navigateToTenant("B", { remember: false })
      assert.equal(assigned.length, 1)
      assert.equal(shopTenantRedirectPending(), true)
    } finally {
      delete globalThis.window
    }
  })
})

describe("TASK_112 — App.svelte contract (one non-blocking call after bootstrap)", () => {
  const src = readFileSync(join(root, "app/frontend/App.svelte"), "utf8")

  it("imports reporter and redirect flag", () => {
    assert.match(src, /import \{ reportSessionOpenOnce \} from "\.\/lib\/pushEnvironment\.js"/)
    assert.match(src, /shopTenantRedirectPending/)
  })

  it("reports only after bootstrapShopTenant, skipped on redirect, inside try/catch", () => {
    const boot = src.indexOf(".then(() => bootstrapShopTenant(api))")
    const call = src.indexOf("reportSessionOpenOnce()")
    assert.ok(boot > 0, "bootstrap chain present")
    assert.ok(call > boot, "report after bootstrap")
    assert.match(src, /if \(!shopTenantRedirectPending\(\)\) reportSessionOpenOnce\(\)/)
    const before = src.slice(Math.max(0, call - 200), call)
    assert.match(before, /try \{/)
  })

  it("does not import push registration into App", () => {
    assert.doesNotMatch(src, /registerShopPush|requestPermission|safeWebStorage|probeStorage/)
  })
})
