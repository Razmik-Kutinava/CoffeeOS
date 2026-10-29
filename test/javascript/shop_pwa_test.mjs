/**
 * TASK_111 — плашка установки и `shopPwa.js` [TDD].
 *
 * Subtask 0: поведение Android до правки (показ по beforeinstallprompt, установка,
 * appinstalled → /pwa_install) закреплено вызовами модуля в Node без браузера.
 *
 * node --test test/javascript/shop_pwa_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, before, beforeEach } from "node:test"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import { renderSvelte } from "./svelte_ssr_helper.mjs"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const bannerPath = join(root, "app/frontend/components/ShopPwaBanner.svelte")

const UA_ANDROID =
  "Mozilla/5.0 (Linux; Android 14; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36"

const win = new EventTarget()
win.location = { search: "?tenant_id=t-1", hash: "" }
globalThis.window = win
globalThis.document = {
  readyState: "complete",
  querySelector: () => null,
  addEventListener() {},
  removeEventListener() {}
}

const fetchCalls = []
let fetchImpl = async () => ({ ok: true, status: 200, statusText: "OK", json: async () => ({ ok: true }) })
globalThis.fetch = (url, init) => {
  fetchCalls.push({ url, init })
  return fetchImpl(url, init)
}

const swRegistered = []
Object.defineProperty(globalThis, "navigator", {
  value: {
    userAgent: UA_ANDROID,
    onLine: true,
    serviceWorker: {
      register: (url, opts) => {
        swRegistered.push({ url, opts })
        return Promise.resolve()
      }
    }
  },
  configurable: true,
  writable: true
})

const pwa = await import("../../app/frontend/lib/shopPwa.js")
const { initShopPwa, installPromptAvailable, promptPwaInstall } = pwa

function installPromptEvent(outcome) {
  const event = new Event("beforeinstallprompt", { cancelable: true })
  event.prompted = 0
  event.prompt = () => {
    event.prompted += 1
  }
  event.userChoice = Promise.resolve({ outcome })
  return event
}

const tick = () => new Promise((r) => setTimeout(r, 0))

describe("Subtask 0 — shopPwa.js на Android до правки", () => {
  before(() => {
    initShopPwa()
  })

  beforeEach(() => {
    fetchCalls.length = 0
    fetchImpl = async () => ({ ok: true, status: 200, statusText: "OK", json: async () => ({ ok: true }) })
  })

  it("регистрирует Service Worker витрины", () => {
    assert.deepEqual(swRegistered, [{ url: "/shop/service-worker.js", opts: { scope: "/shop/" } }])
  })

  it("без beforeinstallprompt установки нет: installPromptAvailable false, promptPwaInstall → false", async () => {
    assert.equal(installPromptAvailable(), false)
    assert.equal(await promptPwaInstall(), false)
  })

  it("beforeinstallprompt → preventDefault, промпт доступен, событие shop:pwa-installable", () => {
    let installable = 0
    const onInstallable = () => {
      installable += 1
    }
    window.addEventListener("shop:pwa-installable", onInstallable)
    const event = installPromptEvent("accepted")
    window.dispatchEvent(event)
    window.removeEventListener("shop:pwa-installable", onInstallable)

    assert.equal(event.defaultPrevented, true)
    assert.equal(installPromptAvailable(), true)
    assert.equal(installable, 1)
  })

  it("«Установить» → системное окно; accepted → true, промпт сброшен", async () => {
    const event = installPromptEvent("accepted")
    window.dispatchEvent(event)
    assert.equal(await promptPwaInstall(), true)
    assert.equal(event.prompted, 1)
    assert.equal(installPromptAvailable(), false)
  })

  it("отказ в системном окне → false, промпт сброшен", async () => {
    const event = installPromptEvent("dismissed")
    window.dispatchEvent(event)
    assert.equal(await promptPwaInstall(), false)
    assert.equal(event.prompted, 1)
    assert.equal(installPromptAvailable(), false)
  })

  it("appinstalled → POST /shop/api/pwa_install с точкой, промпт сброшен", async () => {
    window.dispatchEvent(installPromptEvent("accepted"))
    window.dispatchEvent(new Event("appinstalled"))
    await tick()
    assert.equal(installPromptAvailable(), false)
    assert.equal(fetchCalls.length, 1)
    assert.equal(fetchCalls[0].url, "/shop/api/pwa_install?tenant_id=t-1")
    assert.equal(fetchCalls[0].init.method, "POST")
  })

  it("appinstalled: ошибка сервера не бросает в UI", async () => {
    const warn = console.warn
    const warned = []
    console.warn = (...args) => warned.push(args)
    fetchImpl = async () => ({
      ok: false,
      status: 401,
      statusText: "Unauthorized",
      json: async () => ({ error: "Требуется авторизация" })
    })
    try {
      window.dispatchEvent(new Event("appinstalled"))
      await tick()
      await tick()
    } finally {
      console.warn = warn
    }
    assert.equal(fetchCalls.length, 1)
    assert.equal(warned.length, 1)
  })

  it("SSR плашки: до beforeinstallprompt плашки установки нет", async () => {
    const html = await renderSvelte(bannerPath, {})
    assert.ok(!html.includes("Установить CoffeeOS на главный экран"))
  })
})

const UA_IPHONE =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"

function memoryStorage(initial = {}) {
  const data = { ...initial }
  return {
    data,
    getItem: (k) => (k in data ? data[k] : null),
    setItem: (k, v) => {
      data[k] = String(v)
    },
    removeItem: (k) => {
      delete data[k]
    }
  }
}

const throwingStorage = {
  getItem() {
    throw new Error("SecurityError")
  },
  setItem() {
    throw new Error("SecurityError")
  },
  removeItem() {
    throw new Error("SecurityError")
  }
}

function launchEnv({ standalone = true, local = memoryStorage(), session = memoryStorage() } = {}) {
  return {
    navigator: { userAgent: UA_IPHONE, platform: "iPhone", maxTouchPoints: 5, standalone },
    matchMedia: () => ({ matches: false }),
    localStorage: local,
    sessionStorage: session
  }
}

function launchSpy({ status = 200 } = {}) {
  const sent = []
  const apiCalls = []
  return {
    sent,
    apiCalls,
    opts: {
      resolveUrl: (u) => u,
      beacon: (url, blob) => {
        sent.push(blob)
        return true
      },
      apiFn: (path, init) => {
        apiCalls.push({ path, init })
        if (status >= 400) {
          const err = new Error("Требуется авторизация")
          err.httpStatus = status
          return Promise.reject(err)
        }
        return Promise.resolve({ ok: true })
      }
    },
    async kinds() {
      return Promise.all(sent.map(async (b) => JSON.parse(await b.text()).event_kind))
    }
  }
}

function launch(env, spy) {
  pwa.__resetShopPwaForTests()
  return pwa.reportStandaloneLaunch({ env, ...spy.opts })
}

describe("Subtask 6, 7 — запуск с иконки (standalone)", () => {
  it("ключи метки первого запуска и отправленной отметки — константы", () => {
    assert.equal(pwa.PWA_FIRST_LAUNCH_KEY, "coffeeos_pwa_first_launch_v1")
    assert.equal(pwa.PWA_INSTALL_REPORTED_KEY, "coffeeos_pwa_install_reported_v1")
  })

  it("не standalone → ни события, ни /pwa_install", async () => {
    const spy = launchSpy()
    assert.equal(launch(launchEnv({ standalone: false }), spy), false)
    await tick()
    assert.deepEqual(await spy.kinds(), [])
    assert.equal(spy.apiCalls.length, 0)
  })

  it("Subtask 6: pwa_first_launch — один раз на устройство (метка в localStorage)", async () => {
    const local = memoryStorage()
    const spy = launchSpy()
    assert.equal(launch(launchEnv({ local }), spy), true)
    launch(launchEnv({ local }), spy)
    await tick()
    assert.deepEqual(await spy.kinds(), ["pwa_first_launch"])
    assert.equal(local.data[pwa.PWA_FIRST_LAUNCH_KEY], "1")
  })

  it("Subtask 6: событие несёт снимок окружения без идентификатора гостя", async () => {
    const spy = launchSpy()
    launch(launchEnv(), spy)
    await tick()
    const body = JSON.parse(await spy.sent[0].text())
    assert.equal(body.event_kind, "pwa_first_launch")
    assert.equal(body.os_family, "ios")
    assert.equal(body.standalone, "standalone")
    for (const key of ["customer_id", "phone", "email", "user_agent"]) assert.ok(!(key in body), key)
  })

  it("Subtask 6: без localStorage — pwa_first_launch раз за сессию", async () => {
    const session = memoryStorage()
    const spy = launchSpy()
    launch(launchEnv({ local: throwingStorage, session }), spy)
    launch(launchEnv({ local: throwingStorage, session }), spy)
    launch(launchEnv({ local: throwingStorage, session: memoryStorage() }), spy)
    await tick()
    assert.deepEqual(await spy.kinds(), ["pwa_first_launch", "pwa_first_launch"])
  })

  it("Subtask 7: вошедший гость — POST /pwa_install, успех → больше не отправляется", async () => {
    const local = memoryStorage()
    const spy = launchSpy()
    launch(launchEnv({ local }), spy)
    await tick()
    assert.deepEqual(spy.apiCalls, [{ path: "/pwa_install", init: { method: "POST" } }])
    assert.equal(local.data[pwa.PWA_INSTALL_REPORTED_KEY], "1")

    launch(launchEnv({ local, session: memoryStorage() }), spy)
    await tick()
    assert.equal(spy.apiCalls.length, 1)
  })

  it("Subtask 7: 401 (гость не вошёл) — без метки, в этой сессии не повторяем, в следующей — снова", async () => {
    const local = memoryStorage()
    const session = memoryStorage()
    const spy = launchSpy({ status: 401 })
    launch(launchEnv({ local, session }), spy)
    await tick()
    launch(launchEnv({ local, session }), spy)
    await tick()
    assert.equal(spy.apiCalls.length, 1)
    assert.equal(local.data[pwa.PWA_INSTALL_REPORTED_KEY], undefined)

    launch(launchEnv({ local, session: memoryStorage() }), spy)
    await tick()
    assert.equal(spy.apiCalls.length, 2)
  })

  it("Subtask 7: ошибка запроса или хранилища не ломает запуск", async () => {
    const spy = launchSpy()
    spy.opts.apiFn = () => {
      throw new Error("boom")
    }
    assert.doesNotThrow(() => launch(launchEnv({ local: throwingStorage, session: throwingStorage }), spy))
    await tick()
  })

  it("плашка вызывает запуск при монтировании, application.js не меняется", async () => {
    const { readFileSync } = await import("node:fs")
    const banner = readFileSync(bannerPath, "utf8")
    assert.match(banner, /reportStandaloneLaunch\(\)/)
    const app = readFileSync(join(root, "app/frontend/entrypoints/application.js"), "utf8")
    assert.doesNotMatch(app, /reportStandaloneLaunch/)
  })
})
