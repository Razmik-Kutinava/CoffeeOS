/**
 * #34 SBP Autopay AccountToken FSM — RED [TDD].
 *
 * node --test test/javascript/shop_sbp_autopay_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import {
  SBP_AUTOPAY_STATES,
  createSbpAutopayFsm,
  mapSbpAutopayError,
  SBP_AUTOPAY_TOASTS
} from "../../app/frontend/lib/shopSbpAutopay.js"

describe("shopSbpAutopay — states", () => {
  it("exports idle, loading, success, declined, manual_payment_redirect, error", () => {
    assert.equal(SBP_AUTOPAY_STATES.IDLE, "idle")
    assert.equal(SBP_AUTOPAY_STATES.LOADING, "loading")
    assert.equal(SBP_AUTOPAY_STATES.SUCCESS, "success")
    assert.equal(SBP_AUTOPAY_STATES.DECLINED, "declined")
    assert.equal(SBP_AUTOPAY_STATES.MANUAL_PAYMENT_REDIRECT, "manual_payment_redirect")
    assert.equal(SBP_AUTOPAY_STATES.ERROR, "error")
  })
})

describe("createSbpAutopayFsm — transitions", () => {
  it("starts in idle and keeps orderId/cart context", () => {
    const fsm = createSbpAutopayFsm({ orderId: "ord-34", cartSnapshot: { items: 2 } })
    assert.equal(fsm.state, SBP_AUTOPAY_STATES.IDLE)
    assert.equal(fsm.orderId, "ord-34")
    assert.deepEqual(fsm.cartSnapshot, { items: 2 })
  })

  it("idle → loading on startCharge()", () => {
    const fsm = createSbpAutopayFsm({ orderId: "ord-1" })
    fsm.startCharge()
    assert.equal(fsm.state, SBP_AUTOPAY_STATES.LOADING)
  })

  it("loading → success on confirm()", () => {
    const fsm = createSbpAutopayFsm({ orderId: "ord-1" })
    fsm.startCharge()
    fsm.confirm()
    assert.equal(fsm.state, SBP_AUTOPAY_STATES.SUCCESS)
  })

  it("loading → declined → manual_payment_redirect without losing orderId", () => {
    const fsm = createSbpAutopayFsm({ orderId: "ord-keep", cartSnapshot: { total: 200 } })
    fsm.startCharge()
    fsm.decline({ error_code: "CHARGE_DECLINED" })
    assert.equal(fsm.state, SBP_AUTOPAY_STATES.DECLINED)
    fsm.redirectToManual()
    assert.equal(fsm.state, SBP_AUTOPAY_STATES.MANUAL_PAYMENT_REDIRECT)
    assert.equal(fsm.orderId, "ord-keep")
    assert.deepEqual(fsm.cartSnapshot, { total: 200 })
  })

  it("loading → error on network failure (keeps loader off via state)", () => {
    const fsm = createSbpAutopayFsm({ orderId: "ord-net" })
    fsm.startCharge()
    fsm.failNetwork()
    assert.equal(fsm.state, SBP_AUTOPAY_STATES.ERROR)
  })
})

describe("mapSbpAutopayError + toasts", () => {
  it("maps 4xx/5xx init to service unavailable toast", () => {
    assert.equal(
      mapSbpAutopayError(500, {}),
      SBP_AUTOPAY_TOASTS.SERVICE_UNAVAILABLE
    )
    assert.match(SBP_AUTOPAY_TOASTS.SERVICE_UNAVAILABLE, /временно недоступен/i)
  })

  it("maps CHARGE_DECLINED to manual confirm toast", () => {
    assert.equal(
      mapSbpAutopayError(422, { error_code: "CHARGE_DECLINED" }),
      SBP_AUTOPAY_TOASTS.CHARGE_DECLINED
    )
    assert.match(SBP_AUTOPAY_TOASTS.CHARGE_DECLINED, /быстрый платеж|вручную/i)
  })

  it("maps generic charge network error toast", () => {
    assert.equal(
      mapSbpAutopayError(500, { error_code: "NETWORK" }),
      SBP_AUTOPAY_TOASTS.CONNECTION_ERROR
    )
    assert.match(SBP_AUTOPAY_TOASTS.CONNECTION_ERROR, /соединения|еще раз|ещё раз/i)
  })
})

describe("init helpers — save_sbp_account + charge path", () => {
  it("buildSbpInitBody includes save_sbp_account when bind requested", async () => {
    const { buildSbpInitBody, buildSbpChargeBody } = await import(
      "../../app/frontend/lib/shopSbpAutopay.js"
    )
    assert.deepEqual(buildSbpInitBody({ orderId: "o1", saveSbpAccount: true }), {
      order_id: "o1",
      save_sbp_account: true
    })
    assert.deepEqual(buildSbpChargeBody({ orderId: "o2" }), {
      order_id: "o2"
    })
  })
})
