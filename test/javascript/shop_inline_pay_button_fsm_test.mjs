/**
 * Inline T-Bank payment button FSM — Шаг 4 (RED→GREEN).
 *
 * node --test test/javascript/shop_inline_pay_button_fsm_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import {
  TBANK_INLINE_POLL_MS,
  TBANK_INLINE_ROTATION_MS,
  TBANK_INLINE_TIMEOUT_MS,
  mapTbankInlineError,
  runTbankInlineButtonCycle
} from "../../app/frontend/lib/shopInlinePayFsm.js"

describe("shopInlinePayFsm — exported intervals", () => {
  it("uses strict poll/rotation/timeout values from ТЗ", () => {
    assert.equal(TBANK_INLINE_POLL_MS, 1500)
    assert.equal(TBANK_INLINE_ROTATION_MS, 1800)
    assert.equal(TBANK_INLINE_TIMEOUT_MS, 15000)
  })
})

describe("mapTbankInlineError — 1051 → insufficient funds", () => {
  it("maps ErrorCode=1051 to «Недостаточно средств»", () => {
    assert.equal(
      mapTbankInlineError({ status: "REJECTED", error_code: "1051" }),
      "Недостаточно средств"
    )
  })

  it("maps other terminal errors to a generic message", () => {
    assert.equal(
      mapTbankInlineError({ status: "REJECTED", error_code: "9999" }),
      "Ошибка оплаты, попробуйте снова"
    )
  })
})

describe("runTbankInlineButtonCycle — scheduling + terminal outcomes", () => {
  it("polls every 1500ms and rotates every 1800ms until CONFIRMED", async () => {
    const pollCalls = []

    const pollStatusFn = async ({ attempt, elapsedMs }) => {
      pollCalls.push({ attempt, elapsedMs })
      if (attempt === 3) return { status: "CONFIRMED" }
      return { status: "PENDING" }
    }

    const sleeps = []
    const sleep = async (ms) => {
      sleeps.push(ms)
    }

    const res = await runTbankInlineButtonCycle(pollStatusFn, { sleep })

    assert.equal(res.kind, "confirmed")
    assert.equal(res.terminalStatus, "CONFIRMED")
    assert.equal(res.errorLabel, null)

    assert.deepEqual(
      res.pollTimes,
      [1500, 3000, 4500]
    )
    assert.deepEqual(
      res.rotationTimes,
      [1800, 3600]
    )
    assert.deepEqual(
      res.rotationLabels,
      ["Ещё чуть-чуть...", "Связываемся с банком...", "Платеж принимается банком..."]
    )
    assert.equal(res.labelAtTerminal, "Платеж принимается банком...")

    // 0→1500 poll, 1500→1800 rotate, 1800→3000 poll, 3000→3600 rotate, 3600→4500 poll
    assert.deepEqual(sleeps, [1500, 300, 1200, 600, 900])
    assert.deepEqual(
      pollCalls.map((c) => c.attempt),
      [1, 2, 3]
    )
  })

  it("times out after 15000ms without terminal status", async () => {
    const pollStatusFn = async () => ({ status: "PENDING" })
    const sleeps = []
    const sleep = async (ms) => {
      sleeps.push(ms)
    }

    const res = await runTbankInlineButtonCycle(pollStatusFn, { sleep })

    assert.equal(res.kind, "timeout")
    assert.equal(res.terminalStatus, "TIMEOUT")
    assert.equal(res.errorLabel, "Время ожидания истекло")

    assert.equal(res.pollTimes.length, 10) // 15000 / 1500
    assert.equal(res.pollTimes[0], 1500)
    assert.equal(res.pollTimes.at(-1), 15000)

    assert.equal(res.rotationTimes.length, 8) // 1800..14400
    assert.equal(res.rotationTimes.at(-1), 14400)
    assert.equal(res.labelAtTerminal, "Платеж принимается банком...")

    assert.ok(sleeps.length > 0)
  })

  it("maps REJECTED with ErrorCode=1051 into «Недостаточно средств»", async () => {
    const pollStatusFn = async ({ attempt }) => {
      if (attempt === 1) {
        return { status: "REJECTED", error_code: "1051" }
      }
      return { status: "PENDING" }
    }

    const res = await runTbankInlineButtonCycle(pollStatusFn, {
      sleep: async (_ms) => {}
    })

    assert.equal(res.kind, "rejected")
    assert.equal(res.terminalStatus, "REJECTED")
    assert.equal(res.errorCode, "1051")
    assert.equal(res.errorLabel, "Недостаточно средств")
    assert.equal(res.labelAtTerminal, "Ещё чуть-чуть...")
    assert.deepEqual(res.pollTimes, [1500])
    assert.deepEqual(res.rotationTimes, [])
  })
})

