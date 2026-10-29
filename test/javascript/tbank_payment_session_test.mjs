/**
 * tbankPayment session — недоступный sessionStorage (Safari «Блокировать все cookie»).
 * node --test test/javascript/tbank_payment_session_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import {
  savePaymentSession,
  loadPaymentSession,
  clearPaymentSession
} from "../../app/frontend/lib/tbankPayment.js"

function memoryStorage() {
  const map = new Map()
  return {
    getItem(k) {
      return map.has(k) ? map.get(k) : null
    },
    setItem(k, v) {
      map.set(k, String(v))
    },
    removeItem(k) {
      map.delete(k)
    }
  }
}

function withSessionStorage(descriptor, fn) {
  const original = Object.getOwnPropertyDescriptor(globalThis, "sessionStorage")
  Object.defineProperty(globalThis, "sessionStorage", { configurable: true, ...descriptor })
  try {
    return fn()
  } finally {
    if (original) Object.defineProperty(globalThis, "sessionStorage", original)
    else delete globalThis.sessionStorage
  }
}

describe("tbankPayment — payment session", () => {
  it("save → load → clear round trip", () => {
    withSessionStorage({ value: memoryStorage() }, () => {
      savePaymentSession({ order_id: "ord-1", payment_started: true })
      assert.deepEqual(loadPaymentSession(), { order_id: "ord-1", payment_started: true })
      clearPaymentSession()
      assert.equal(loadPaymentSession(), null)
    })
  })

  it("blocked sessionStorage: save/load/clear do not throw", () => {
    withSessionStorage(
      {
        get() {
          throw new DOMException("The operation is insecure.", "SecurityError")
        }
      },
      () => {
        assert.doesNotThrow(() => savePaymentSession({ order_id: "ord-2" }))
        assert.equal(loadPaymentSession(), null)
        assert.doesNotThrow(() => clearPaymentSession())
      }
    )
  })
})
