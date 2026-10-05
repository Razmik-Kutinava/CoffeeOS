/**
 * TASK_86 Патч 1: смонтированный WAITING_FOR_BANK переходит в результат без remount.
 * node --test test/javascript/sbp_waiting_screen_transition_test.mjs
 */
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { describe, it } from "node:test"
import { resolveWaitingScreenTransition } from "../../app/frontend/lib/shopSbpPay.js"

const RESULT_SRC = readFileSync(new URL("../../app/frontend/routes/PaymentResult.svelte", import.meta.url), "utf8")

describe("resolveWaitingScreenTransition — Subtask 4 (patch v2)", () => {
  for (const nextStatus of ["ok", "ok_sbp", "success"]) {
    it(`waiting → ${nextStatus} того же заказа → success`, () => {
      assert.equal(
        resolveWaitingScreenTransition({
          currentStatus: "waiting",
          nextStatus,
          currentOrderId: "ord-1",
          nextOrderId: "ord-1"
        }),
        "success"
      )
    })
  }
})

describe("resolveWaitingScreenTransition — Subtask 5 (patch v2)", () => {
  for (const nextStatus of ["fail", "cancel"]) {
    it(`waiting → ${nextStatus} того же заказа → incomplete`, () => {
      assert.equal(
        resolveWaitingScreenTransition({
          currentStatus: "waiting",
          nextStatus,
          currentOrderId: "ord-1",
          nextOrderId: "ord-1"
        }),
        "incomplete"
      )
    })
  }
})

describe("resolveWaitingScreenTransition — границы", () => {
  it("waiting → waiting (PENDING) → none", () => {
    assert.equal(
      resolveWaitingScreenTransition({
        currentStatus: "waiting",
        nextStatus: "waiting",
        currentOrderId: "ord-1",
        nextOrderId: "ord-1"
      }),
      "none"
    )
  })

  it("чужой order_id не перезаписывает экран текущего заказа", () => {
    assert.equal(
      resolveWaitingScreenTransition({
        currentStatus: "waiting",
        nextStatus: "ok",
        currentOrderId: "ord-1",
        nextOrderId: "ord-2"
      }),
      "none"
    )
  })

  it("экран не в waiting (уже terminal) → none", () => {
    for (const currentStatus of ["ok", "fail", "cancel"]) {
      assert.equal(
        resolveWaitingScreenTransition({
          currentStatus,
          nextStatus: "ok",
          currentOrderId: "ord-1",
          nextOrderId: "ord-1"
        }),
        "none"
      )
    }
  })

  it("пустой orderId → none", () => {
    assert.equal(
      resolveWaitingScreenTransition({
        currentStatus: "waiting",
        nextStatus: "ok",
        currentOrderId: "",
        nextOrderId: ""
      }),
      "none"
    )
  })
})

describe("PaymentResult — реакция смонтированного экрана на смену status", () => {
  it("слушает hashchange и снимает слушатель", () => {
    assert.match(RESULT_SRC, /window\.addEventListener\("hashchange",/)
    assert.match(RESULT_SRC, /window\.removeEventListener\("hashchange",/)
  })

  it("решает переход через resolveWaitingScreenTransition", () => {
    assert.match(RESULT_SRC, /resolveWaitingScreenTransition\(/)
  })

  it("success → существующий prepareSuccessScreen, incomplete → clearPendingOrder + SBP_INCOMPLETE_MESSAGE", () => {
    const fn = RESULT_SRC.match(/async function applyWaitingTransition\([\s\S]*?\n  \}\n/)
    assert.ok(fn, "applyWaitingTransition missing")
    assert.match(fn[0], /prepareSuccessScreen\(\)/)
    assert.match(fn[0], /clearPendingOrder\(\)/)
    assert.match(fn[0], /SBP_INCOMPLETE_MESSAGE/)
    assert.match(fn[0], /waitingForBank = false/)
  })

  it("без нового polling/таймеров (scope патча)", () => {
    assert.doesNotMatch(RESULT_SRC, /setInterval\(/)
  })
})
