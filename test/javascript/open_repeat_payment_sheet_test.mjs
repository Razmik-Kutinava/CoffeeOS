/**
 * openRepeatPaymentSheet — канон после One-Click fail / invalid token.
 * node --test test/javascript/open_repeat_payment_sheet_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach, afterEach } from "node:test"
import { readFileSync } from "node:fs"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")

describe("openRepeatPaymentSheet source contract", () => {
  it("helper marks OPEN_PAYMENT_SHEET and navigates to checkout", () => {
    const src = readFileSync(join(root, "app/frontend/lib/openRepeatPaymentSheet.js"), "utf8")
    assert.match(src, /markOpenPaymentSheet/)
    assert.match(src, /persistPaymentSelection/)
    assert.match(src, /preferNewCard/)
    assert.match(src, /push\("\/checkout"\)/)
    assert.match(src, /requestCheckoutPay/)
    assert.match(src, /lines\.length === 0/, "addToCart only when cart empty")
  })

  it("RepeatSection wires card+ to openRepeatPaymentSheet not peek expand", () => {
    const src = readFileSync(join(root, "app/frontend/components/RepeatSection.svelte"), "utf8")
    assert.match(src, /openRepeatPaymentSheet/)
    assert.match(src, /onFallbackCardPlus/)
    assert.match(src, /setTokenInvalid/)
    assert.match(src, /isInvalidRebillPaymentError/)
    assert.doesNotMatch(src, /resolveCardPlusExpandedUi/)
    assert.doesNotMatch(src, /showNewCardForm:\s*true/)
  })
})

describe("repeatInvalidTokenStore OPEN_PAYMENT_SHEET", () => {
  const key = "shop_open_payment_sheet"
  let store

  beforeEach(async () => {
    globalThis.sessionStorage = (() => {
      const m = new Map()
      return {
        getItem: (k) => (m.has(k) ? m.get(k) : null),
        setItem: (k, v) => m.set(k, String(v)),
        removeItem: (k) => m.delete(k),
        clear: () => m.clear(),
        key: (i) => [...m.keys()][i] ?? null,
        get length() {
          return m.size
        }
      }
    })()
    store = await import("../../app/frontend/lib/repeatInvalidTokenStore.js")
  })

  afterEach(() => {
    delete globalThis.sessionStorage
  })

  it("mark/consume open payment sheet flag", () => {
    store.markOpenPaymentSheet()
    assert.equal(sessionStorage.getItem(key), "1")
    assert.equal(store.consumeOpenPaymentSheet(), true)
    assert.equal(store.consumeOpenPaymentSheet(), false)
  })
})
