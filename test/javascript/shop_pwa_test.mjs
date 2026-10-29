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

const { initShopPwa, installPromptAvailable, promptPwaInstall } = await import(
  "../../app/frontend/lib/shopPwa.js"
)

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
