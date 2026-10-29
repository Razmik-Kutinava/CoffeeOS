/**
 * TASK_113 — push-код устойчив к недоступному хранилищу [RED / TDD].
 *
 * node --test test/javascript/order_status_push_storage_safe_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import {
  downloadWalletPass,
  resolveNotifyPrimaryInit,
  subscribeOrderPush,
  pushRegisteredStorageKey,
  walletAddedStorageKey
} from "../../app/frontend/lib/orderStatusNotifyActions.js"

function withThrowingLocalStorage(fn) {
  const original = Object.getOwnPropertyDescriptor(globalThis, "localStorage")
  Object.defineProperty(globalThis, "localStorage", {
    configurable: true,
    get() {
      throw new Error("SecurityError: localStorage blocked")
    }
  })
  const restore = () => {
    if (original) Object.defineProperty(globalThis, "localStorage", original)
    else delete globalThis.localStorage
  }
  let out
  try {
    out = fn()
  } catch (err) {
    restore()
    throw err
  }
  if (out && typeof out.then === "function") return out.finally(restore)
  restore()
  return out
}

function throwingGetStorage() {
  return {
    getItem() {
      throw new Error("SecurityError: getItem")
    },
    setItem() {}
  }
}

function throwingSetStorage() {
  const map = new Map()
  return {
    getItem: (k) => (map.has(k) ? map.get(k) : null),
    setItem() {
      throw new Error("QuotaExceededError: setItem")
    }
  }
}

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

function fakeDeps(calls) {
  return {
    isSupported: async () => {
      calls.push("isSupported")
      return true
    },
    firebaseClientConfigured: () => {
      calls.push("firebaseClientConfigured")
      return true
    },
    getToken: async () => {
      calls.push("getToken")
      return "tok-113"
    },
    registerToken: async (token) => {
      calls.push(`registerToken:${token}`)
    }
  }
}

function okWalletFetch() {
  return async () => ({
    ok: true,
    status: 200,
    blob: async () => new Blob(["PKPASS"], { type: "application/vnd.apple.pkpass" })
  })
}

describe("TASK_113 Subtask 1 — геттер localStorage бросает при рендере панели", () => {
  for (const os of ["android", "desktop", "ios"]) {
    it(`${os}: resolveNotifyPrimaryInit без storage (как в аккордеоне) не бросает, restored = false`, () => {
      const init = withThrowingLocalStorage(() =>
        resolveNotifyPrimaryInit({ os, orderId: "113", notificationPermission: "granted" })
      )
      assert.equal(init.restored, false)
      assert.equal(init.disabled, false)
      assert.equal(init.primaryLabel, null)
    })
  }
})

describe("TASK_113 Subtask 2 — getItem бросает", () => {
  for (const os of ["android", "desktop", "ios"]) {
    it(`${os}: resolveNotifyPrimaryInit с бросающим getItem → restored = false`, () => {
      const init = resolveNotifyPrimaryInit({
        os,
        orderId: "113",
        storage: throwingGetStorage(),
        notificationPermission: "granted"
      })
      assert.equal(init.restored, false)
      assert.equal(init.disabled, false)
      assert.equal(init.primaryLabel, null)
    })
  }
})

describe("TASK_113 Subtask 3 — push-CTA при недоступном хранилище", () => {
  it("геттер бросает: subscribeOrderPush синхронно доходит до requestPermission, ok = true", async () => {
    const calls = []
    installNotification("granted", calls)
    try {
      const result = await withThrowingLocalStorage(() => {
        const pending = subscribeOrderPush({ onToast: () => {}, deps: fakeDeps(calls) })
        assert.deepEqual(calls, ["requestPermission"])
        return pending
      })
      assert.equal(result.ok, true)
      assert.ok(calls.includes("registerToken:tok-113"))
    } finally {
      removeNotification()
    }
  })

  it("setItem бросает: неудачная запись флага на результат не влияет (охранный)", async () => {
    const result = await subscribeOrderPush({
      registerShopPushImpl: async () => ({ ok: true }),
      onToast: () => {},
      storage: throwingSetStorage()
    })
    assert.equal(result.ok, true)
    assert.match(result.primaryLabel, /Уведомления включены/)
  })
})

describe("TASK_113 Subtask 4 — Wallet pass при недоступном хранилище", () => {
  it("setItem бросает: pass добавлен, тоста ошибки нет", async () => {
    const toasts = []
    let href = ""
    const result = await downloadWalletPass({
      orderId: "113",
      fetchImpl: okWalletFetch(),
      createObjectURL: () => "blob:wallet-113",
      locationAssign: (url) => {
        href = url
      },
      storage: throwingSetStorage(),
      onToast: (msg) => toasts.push(msg)
    })
    assert.equal(href, "blob:wallet-113")
    assert.equal(result.ok, true)
    assert.match(result.primaryLabel, /Карта добавлена/)
    assert.deepEqual(toasts, [])
  })

  it("геттер бросает (storage не передан): pass добавлен, тоста ошибки нет", async () => {
    const toasts = []
    let href = ""
    const result = await withThrowingLocalStorage(() =>
      downloadWalletPass({
        orderId: "113",
        fetchImpl: okWalletFetch(),
        createObjectURL: () => "blob:wallet-113",
        locationAssign: (url) => {
          href = url
        },
        onToast: (msg) => toasts.push(msg)
      })
    )
    assert.equal(href, "blob:wallet-113")
    assert.equal(result.ok, true)
    assert.match(result.primaryLabel, /Карта добавлена/)
    assert.deepEqual(toasts, [])
  })
})

describe("TASK_113 Subtask 6 — флаг не записался, кнопка может показаться снова", () => {
  it("после неудачной записи push-флага restored = false", async () => {
    const storage = throwingSetStorage()
    await subscribeOrderPush({
      registerShopPushImpl: async () => ({ ok: true }),
      onToast: () => {},
      storage
    })
    assert.equal(storage.getItem(pushRegisteredStorageKey()), null)
    const init = resolveNotifyPrimaryInit({
      os: "android",
      orderId: "113",
      storage,
      notificationPermission: "granted"
    })
    assert.equal(init.restored, false)
  })

  it("после неудачной записи wallet-флага restored = false", async () => {
    const storage = throwingSetStorage()
    await downloadWalletPass({
      orderId: "113",
      fetchImpl: okWalletFetch(),
      createObjectURL: () => "blob:wallet-113",
      locationAssign: () => {},
      storage,
      onToast: () => {}
    })
    assert.equal(storage.getItem(walletAddedStorageKey("113")), null)
    const init = resolveNotifyPrimaryInit({ os: "ios", orderId: "113", storage })
    assert.equal(init.restored, false)
  })
})
