/**
 * CODE:BLACK pending order LS — Шаги 4.1–4.3 (RED→GREEN).
 * node --test test/javascript/codeblack_pending_order_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach } from "node:test"
import {
  CODEBLACK_PENDING_KEY,
  PENDING_TTL_MS,
  savePendingOrder,
  loadPendingOrder,
  clearPendingOrder,
  isPendingFresh,
  createVisibilityStatusGuard
} from "../../app/frontend/lib/codeblackPendingOrder.js"
import {
  SBP_WAITING_FOR_BANK_MESSAGE,
  SBP_I_PAID_LABEL,
  mapPaymentStatusPayload,
  checkOrderStatus
} from "../../app/frontend/lib/shopSbpPay.js"

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

describe("codeblackPendingOrder — LS lifecycle", () => {
  let storage

  beforeEach(() => {
    storage = memoryStorage()
  })

  it("exports storage key codeblack_pending_order", () => {
    assert.equal(CODEBLACK_PENDING_KEY, "codeblack_pending_order")
  })

  it("TTL is 15 minutes", () => {
    assert.equal(PENDING_TTL_MS, 15 * 60 * 1000)
  })

  it("savePendingOrder writes { orderId, timestamp }", () => {
    const now = 1_700_000_000_000
    savePendingOrder("ord-42", { storage, now })
    const raw = JSON.parse(storage.getItem(CODEBLACK_PENDING_KEY))
    assert.equal(raw.orderId, "ord-42")
    assert.equal(raw.timestamp, now)
  })

  it("loadPendingOrder returns payload when fresh", () => {
    const now = 1_700_000_000_000
    savePendingOrder("ord-1", { storage, now })
    const loaded = loadPendingOrder({ storage, now: now + 60_000 })
    assert.deepEqual(loaded, { orderId: "ord-1", timestamp: now })
  })

  it("loadPendingOrder returns null and clears when older than 15 min", () => {
    const now = 1_700_000_000_000
    savePendingOrder("ord-old", { storage, now })
    const loaded = loadPendingOrder({ storage, now: now + PENDING_TTL_MS + 1 })
    assert.equal(loaded, null)
    assert.equal(storage.getItem(CODEBLACK_PENDING_KEY), null)
  })

  it("isPendingFresh respects TTL boundary", () => {
    const ts = 1000
    assert.equal(isPendingFresh({ orderId: "x", timestamp: ts }, ts + PENDING_TTL_MS - 1), true)
    assert.equal(isPendingFresh({ orderId: "x", timestamp: ts }, ts + PENDING_TTL_MS), false)
  })

  it("clearPendingOrder removes key", () => {
    savePendingOrder("ord-x", { storage, now: 1 })
    clearPendingOrder({ storage })
    assert.equal(storage.getItem(CODEBLACK_PENDING_KEY), null)
  })
})

describe("codeblackPendingOrder — visibility race guard", () => {
  it("createVisibilityStatusGuard serializes overlapping runs", async () => {
    const guard = createVisibilityStatusGuard()
    let concurrent = 0
    let maxConcurrent = 0
    const run = async () => {
      concurrent += 1
      maxConcurrent = Math.max(maxConcurrent, concurrent)
      await new Promise((r) => setTimeout(r, 20))
      concurrent -= 1
      return "ok"
    }

    const a = guard.run(run)
    const b = guard.run(run)
    const results = await Promise.all([a, b])
    assert.deepEqual(results, ["ok", "ok"])
    assert.equal(maxConcurrent, 1)
  })
})

describe("shopSbpPay — WAITING_FOR_BANK + checkOrderStatus", () => {
  it("exports waiting copy and «Я оплатил»", () => {
    assert.match(SBP_WAITING_FOR_BANK_MESSAGE, /завершите оплату|приложении банка/i)
    assert.match(SBP_I_PAID_LABEL, /я оплатил/i)
  })

  it("mapPaymentStatusPayload normalizes API status", () => {
    assert.equal(mapPaymentStatusPayload({ status: "CONFIRMED" }), "CONFIRMED")
    assert.equal(mapPaymentStatusPayload({ status: "pending" }), "PENDING")
    assert.equal(mapPaymentStatusPayload({ status: "REJECTED" }), "REJECTED")
    assert.equal(mapPaymentStatusPayload({ status: "CANCELED" }), "CANCELED")
    assert.equal(mapPaymentStatusPayload({ status: "cancelled" }), "CANCELED")
  })

  it("checkOrderStatus GETs /payments/status/:orderId and clears pending on terminal", async () => {
    const storage = memoryStorage()
    savePendingOrder("ord-9", { storage, now: Date.now() })
    const calls = []
    const api = async (path) => {
      calls.push(path)
      return { status: "CONFIRMED" }
    }
    const result = await checkOrderStatus(api, { orderId: "ord-9", storage })
    assert.equal(result, "CONFIRMED")
    assert.equal(calls[0], "/payments/status/ord-9")
    assert.equal(storage.getItem(CODEBLACK_PENDING_KEY), null)
  })

  it("checkOrderStatus keeps pending on PENDING", async () => {
    const storage = memoryStorage()
    const now = Date.now()
    savePendingOrder("ord-p", { storage, now })
    const api = async () => ({ status: "PENDING" })
    const result = await checkOrderStatus(api, { orderId: "ord-p", storage })
    assert.equal(result, "PENDING")
    assert.ok(storage.getItem(CODEBLACK_PENDING_KEY))
  })
})
