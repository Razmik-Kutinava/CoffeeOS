/**
 * #37 Шаг 4 — iOS Apple Wallet download [RED / TDD].
 *
 * node --test test/javascript/order_status_wallet_pass_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  downloadWalletPass,
  walletAddedStorageKey
} from "../../app/frontend/lib/orderStatusNotifyActions.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const accordionPath = join(
  root,
  "app/frontend/components/ActiveOrdersAccordion.svelte"
)

function mockStorage() {
  const map = new Map()
  return {
    getItem: (k) => (map.has(k) ? map.get(k) : null),
    setItem: (k, v) => map.set(k, String(v)),
    removeItem: (k) => map.delete(k)
  }
}

describe("walletAddedStorageKey (#37 step 4)", () => {
  it("uses order_{id}_wallet_added", () => {
    assert.equal(walletAddedStorageKey("42"), "order_42_wallet_added")
  })
})

describe("downloadWalletPass (#37 step 4)", () => {
  it("on 200: blob navigate, localStorage, success label, isLoading false", async () => {
    const storage = mockStorage()
    const calls = []
    let href = ""
    const blob = new Blob(["PKPASS"], { type: "application/vnd.apple.pkpass" })

    const result = await downloadWalletPass({
      orderId: "42",
      fetchImpl: async (url, opts) => {
        calls.push({ url, opts })
        return {
          ok: true,
          status: 200,
          blob: async () => blob
        }
      },
      createObjectURL: () => "blob:mock-wallet-pass",
      locationAssign: (url) => {
        href = url
      },
      storage
    })

    assert.equal(calls.length, 1)
    assert.match(String(calls[0].url), /\/orders\/42\/wallet_pass/)
    assert.equal(calls[0].opts?.method || "GET", "GET")
    assert.equal(href, "blob:mock-wallet-pass")
    assert.equal(storage.getItem("order_42_wallet_added"), "true")
    assert.equal(result.ok, true)
    assert.equal(result.isLoading, false)
    assert.match(result.primaryLabel, /Карта добавлена/)
  })

  it("on 500: isLoading false, toast, label unchanged", async () => {
    const storage = mockStorage()
    const toasts = []
    let href = ""

    const result = await downloadWalletPass({
      orderId: "99",
      fetchImpl: async () => ({
        ok: false,
        status: 500,
        blob: async () => new Blob([])
      }),
      createObjectURL: () => "blob:should-not",
      locationAssign: (url) => {
        href = url
      },
      storage,
      onToast: (msg) => toasts.push(msg)
    })

    assert.equal(href, "")
    assert.equal(storage.getItem("order_99_wallet_added"), null)
    assert.equal(result.ok, false)
    assert.equal(result.isLoading, false)
    assert.equal(result.primaryLabel, "Карта в Apple Wallet")
    assert.ok(toasts.length >= 1)
  })
})

describe("ActiveOrdersAccordion wires wallet download (#37 step 4 / #41)", () => {
  it("imports downloadWalletPass and handles wallet kind in onAction", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /downloadWalletPass/)
    assert.match(src, /kind === ["']wallet["']|kind === 'wallet'/)
    assert.match(src, /onAction/)
  })
})
