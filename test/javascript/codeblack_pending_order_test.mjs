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
  checkOrderStatus,
  beginSbpBankRedirect,
  recoverPendingPayment,
  resetPendingRecoverySession
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

describe("#79 beginSbpBankRedirect — waiting screen before bank", () => {
  it("saves pending, navigates to waiting, then redirects to nspk", () => {
    const storage = memoryStorage()
    const nav = []
    const redirects = []
    const loc = { hash: "" }
    beginSbpBankRedirect({
      orderId: "ord-79",
      paymentUrl: "https://qr.nspk.ru/AS79",
      storage,
      now: 1_700_000_000_000,
      navigate: (hash) => nav.push(hash),
      redirect: (url) => redirects.push(url),
      location: loc
    })
    assert.equal(JSON.parse(storage.getItem(CODEBLACK_PENDING_KEY)).orderId, "ord-79")
    assert.equal(nav[0], "/payment-result?status=waiting&order_id=ord-79")
    assert.equal(loc.hash, "#/payment-result?status=waiting&order_id=ord-79")
    assert.deepEqual(redirects, ["https://qr.nspk.ru/AS79"])
    assert.equal(nav.length, 1)
    assert.ok(nav[0].includes("waiting"), "waiting route must run before bank leave")
  })
})

describe("#86 recoverPendingPayment — SBP PWA recovery", () => {
  beforeEach(() => {
    resetPendingRecoverySession()
  })

  it("CONFIRMED → ui ok and clears pending", async () => {
    const storage = memoryStorage()
    savePendingOrder("ord-ok", { storage, now: Date.now() })
    const api = async () => ({ status: "CONFIRMED" })
    const out = await recoverPendingPayment(api, { storage })
    assert.equal(out.ui, "ok")
    assert.equal(out.orderId, "ord-ok")
    assert.equal(out.status, "CONFIRMED")
    assert.equal(storage.getItem(CODEBLACK_PENDING_KEY), null)
  })

  it("REJECTED → ui fail and clears pending", async () => {
    const storage = memoryStorage()
    savePendingOrder("ord-rej", { storage, now: Date.now() })
    const api = async () => ({ status: "REJECTED" })
    const out = await recoverPendingPayment(api, { storage })
    assert.equal(out.ui, "fail")
    assert.equal(out.status, "REJECTED")
    assert.equal(storage.getItem(CODEBLACK_PENDING_KEY), null)
  })

  it("CANCELED → ui fail and clears pending", async () => {
    const storage = memoryStorage()
    savePendingOrder("ord-can", { storage, now: Date.now() })
    const api = async () => ({ status: "CANCELED" })
    const out = await recoverPendingPayment(api, { storage })
    assert.equal(out.ui, "fail")
    assert.equal(out.status, "CANCELED")
    assert.equal(storage.getItem(CODEBLACK_PENDING_KEY), null)
  })

  it("PENDING → ui waiting and keeps pending", async () => {
    const storage = memoryStorage()
    const now = Date.now()
    savePendingOrder("ord-p", { storage, now })
    const api = async () => ({ status: "PENDING" })
    const out = await recoverPendingPayment(api, { storage })
    assert.equal(out.ui, "waiting")
    assert.equal(out.status, "PENDING")
    assert.ok(storage.getItem(CODEBLACK_PENDING_KEY))
  })

  it("network error → ui waiting, pending kept, not REJECTED", async () => {
    const storage = memoryStorage()
    savePendingOrder("ord-net", { storage, now: Date.now() })
    const api = async () => {
      throw Object.assign(new Error("network"), { kind: "network" })
    }
    const out = await recoverPendingPayment(api, { storage })
    assert.equal(out.ui, "waiting")
    assert.notEqual(out.status, "REJECTED")
    assert.notEqual(out.status, "CANCELED")
    assert.ok(storage.getItem(CODEBLACK_PENDING_KEY))
  })

  it("no pending → ui none", async () => {
    const storage = memoryStorage()
    const api = async () => ({ status: "CONFIRMED" })
    const out = await recoverPendingPayment(api, { storage })
    assert.equal(out.ui, "none")
  })

  it("expired TTL → ui none and does not call status API", async () => {
    const storage = memoryStorage()
    const now = 1_700_000_000_000
    savePendingOrder("ord-exp", { storage, now })
    let calls = 0
    const api = async () => {
      calls += 1
      return { status: "CONFIRMED" }
    }
    const out = await recoverPendingPayment(api, {
      storage,
      now: now + PENDING_TTL_MS + 1
    })
    assert.equal(out.ui, "none")
    assert.equal(calls, 0)
    assert.equal(storage.getItem(CODEBLACK_PENDING_KEY), null)
  })

  it("duplicate terminal for same order → second recover is skip", async () => {
    const storage = memoryStorage()
    savePendingOrder("ord-dup", { storage, now: Date.now() })
    const api = async () => ({ status: "CONFIRMED" })
    const first = await recoverPendingPayment(api, { storage })
    assert.equal(first.ui, "ok")
    // Simulate leftover pending from race / second lifecycle after clear failed
    savePendingOrder("ord-dup", { storage, now: Date.now() })
    const second = await recoverPendingPayment(api, { storage })
    assert.equal(second.ui, "skip")
    assert.equal(second.reason, "terminal_already_shown")
  })

  it("overlapping recoveries serialize — one active status check", async () => {
    const storage = memoryStorage()
    savePendingOrder("ord-race", { storage, now: Date.now() })
    let concurrent = 0
    let maxConcurrent = 0
    const api = async () => {
      concurrent += 1
      maxConcurrent = Math.max(maxConcurrent, concurrent)
      await new Promise((r) => setTimeout(r, 30))
      concurrent -= 1
      return { status: "PENDING" }
    }
    const a = recoverPendingPayment(api, { storage })
    const b = recoverPendingPayment(api, { storage })
    await Promise.all([a, b])
    assert.equal(maxConcurrent, 1)
  })
})

describe("#86 checkOrderStatus — network does not clear pending", () => {
  it("keeps pending when status request throws", async () => {
    const storage = memoryStorage()
    savePendingOrder("ord-e", { storage, now: Date.now() })
    const api = async () => {
      throw new Error("offline")
    }
    await assert.rejects(() => checkOrderStatus(api, { orderId: "ord-e", storage }))
    assert.ok(storage.getItem(CODEBLACK_PENDING_KEY))
  })
})
