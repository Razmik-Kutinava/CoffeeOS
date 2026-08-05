/**
 * #41 Шаг 6 [TDD-RED] — Cancel flow в sticky-панели (Confirm Sheet + API).
 *
 * node --test test/javascript/order_action_buttons_cancel_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  shouldShowAcceptedCancelModal,
  resolveCancelSuccessResult,
  resolveCancelErrorResult,
  CANCEL_SUCCESS_TOAST
} from "../../app/frontend/lib/orderCancelFlow.js"
import {
  createOrderStatusSheetState,
  applyCableEvent
} from "../../app/frontend/lib/orderStatusSheet.js"
import { orderStatusCtas } from "../../app/frontend/lib/orderStatusCtaMachine.js"
import { applyStickyCancelSuccess } from "../../app/frontend/lib/stickyOrderCancel.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const sheetComponentPath = join(
  root,
  "app/frontend/components/OrderStatusSheet.svelte"
)
const accordionPath = join(
  root,
  "app/frontend/components/ActiveOrdersAccordion.svelte"
)

describe("sticky cancel modal gate (#41 step 6) [TDD-RED]", () => {
  it("paid ≡ accepted for Confirm Sheet", () => {
    assert.equal(shouldShowAcceptedCancelModal("accepted"), true)
    assert.equal(
      shouldShowAcceptedCancelModal("paid"),
      true,
      "paid alias must open the same confirm sheet as accepted"
    )
  })
})

describe("applyStickyCancelSuccess (#41 step 6) [TDD-RED]", () => {
  it("200: removes/hides order CTAs (cancelled → no buttons)", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([
      {
        id: "ord-1",
        status: "accepted",
        can_cancel: true,
        order_number: "202608-0001",
        total_amount: 179
      }
    ])

    const outcome = applyStickyCancelSuccess(state, {
      id: "ord-1",
      status: "cancelled"
    })

    assert.equal(outcome.toast, CANCEL_SUCCESS_TOAST)
    assert.equal(state.orders.length, 0, "cancelled order leaves sticky list")
    const ctas = orderStatusCtas({
      status: "cancelled",
      os: "android",
      canCancel: false
    })
    assert.equal(ctas.buttons.length, 0)
  })

  it("400/network: keeps order + can_cancel, no force preparing", () => {
    const err = resolveCancelErrorResult({ httpStatus: 400, message: "bad request" })
    assert.equal(err.canCancel, true)
    assert.equal(err.forceStatus, null)
    assert.ok(err.toast)
  })

  it("422/500: force preparing + can_cancel false (buttons stay as chat matrix)", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([
      { id: "ord-2", status: "accepted", can_cancel: true, order_number: "X" }
    ])
    const err = resolveCancelErrorResult({ httpStatus: 422 })
    assert.equal(err.forceStatus, "preparing")
    assert.equal(err.canCancel, false)

    applyCableEvent(state, {
      type: "status_changed",
      order_id: "ord-2",
      status: err.forceStatus,
      can_cancel: err.canCancel
    })
    assert.equal(state.orders[0].status, "preparing")
    assert.equal(state.orders[0].can_cancel, false)
    const ctas = orderStatusCtas({
      status: state.orders[0].status,
      os: "android",
      canCancel: state.orders[0].can_cancel,
      hasPushSubscription: true
    })
    assert.deepEqual(
      ctas.buttons.map((b) => b.kind),
      ["chat", "tips"]
    )
  })
})

describe("sticky panel cancel wiring (#41 step 6) [TDD-RED]", () => {
  it("OrderStatusSheet wires modal + cancel API + onCancelRequest", () => {
    const src = readFileSync(sheetComponentPath, "utf8")
    assert.match(src, /OrderCancelModal/)
    assert.match(src, /orderCancelFlow|buildAcceptedCancelModalCopy|shouldShowAcceptedCancelModal/)
    assert.match(src, /onCancelRequest/)
    assert.match(src, /orders\/\$\{.*\}\/cancel|\/orders\/.*\/cancel/)
    assert.match(src, /resolveCancelSuccessResult|applyStickyCancelSuccess/)
    assert.match(src, /resolveCancelErrorResult/)
    assert.match(src, /isLoading|cancelLoading|cancelling/)
  })

  it("ActiveOrdersAccordion forwards cancel kind via onCancelRequest", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /onCancelRequest/)
    assert.match(src, /kind === ["']cancel["']/)
  })

  it("success path uses resolveCancelSuccessResult toast copy", () => {
    const result = resolveCancelSuccessResult({ id: "o1", status: "cancelled" })
    assert.equal(result.toast, CANCEL_SUCCESS_TOAST)
  })
})
