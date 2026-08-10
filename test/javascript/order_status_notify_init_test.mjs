/**
 * #37 Шаг 6 — init restored CTA state [RED / TDD].
 *
 * node --test test/javascript/order_status_notify_init_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  resolveNotifyPrimaryInit,
  walletAddedStorageKey,
  pushRegisteredStorageKey
} from "../../app/frontend/lib/orderStatusNotifyActions.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const accordionPath = join(
  root,
  "app/frontend/components/ActiveOrdersAccordion.svelte"
)

function mockStorage(map = {}) {
  const store = new Map(Object.entries(map))
  return {
    getItem: (k) => (store.has(k) ? store.get(k) : null),
    setItem: (k, v) => store.set(k, String(v))
  }
}

describe("resolveNotifyPrimaryInit (#37 step 6)", () => {
  it("ios + wallet_added in LS → success label disabled", () => {
    const orderId = "42"
    const storage = mockStorage({
      [walletAddedStorageKey(orderId)]: "true"
    })
    const init = resolveNotifyPrimaryInit({
      os: "ios",
      orderId,
      storage,
      notificationPermission: "default"
    })

    assert.equal(init.restored, true)
    assert.equal(init.disabled, true)
    assert.match(init.primaryLabel, /Карта добавлена/)
  })

  it("android + permission granted alone → not restored (need FCM register LS)", () => {
    const init = resolveNotifyPrimaryInit({
      os: "android",
      orderId: "7",
      storage: mockStorage(),
      notificationPermission: "granted"
    })

    assert.equal(init.restored, false)
    assert.equal(init.disabled, false)
    assert.equal(init.primaryLabel, null)
  })

  it("android + permission + push registered LS → push success disabled", () => {
    const storage = mockStorage({
      [pushRegisteredStorageKey()]: "true"
    })
    const init = resolveNotifyPrimaryInit({
      os: "android",
      orderId: "7",
      storage,
      notificationPermission: "granted"
    })

    assert.equal(init.restored, true)
    assert.equal(init.disabled, true)
    assert.match(init.primaryLabel, /Уведомления включены/)
  })

  it("desktop without grant/LS → idle, not disabled", () => {
    const init = resolveNotifyPrimaryInit({
      os: "desktop",
      orderId: "9",
      storage: mockStorage(),
      notificationPermission: "default"
    })

    assert.equal(init.restored, false)
    assert.equal(init.disabled, false)
    assert.equal(init.primaryLabel, null)
  })

  it("ios without wallet LS ignores notification grant for wallet CTA", () => {
    const init = resolveNotifyPrimaryInit({
      os: "ios",
      orderId: "3",
      storage: mockStorage(),
      notificationPermission: "granted"
    })

    assert.equal(init.restored, false)
    assert.equal(init.disabled, false)
    assert.equal(init.primaryLabel, null)
  })
})

describe("ActiveOrdersAccordion applies notify init (#37 step 6)", () => {
  it("calls resolveNotifyPrimaryInit on mount path", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /resolveNotifyPrimaryInit/)
  })
})
