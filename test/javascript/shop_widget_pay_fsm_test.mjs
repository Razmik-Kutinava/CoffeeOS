/**
 * Widget T-Kassa One-Click + Fallback FSM — (#33) RED.
 *
 * node --test test/javascript/shop_widget_pay_fsm_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import {
  WIDGET_FSM_STATES,
  createWidgetPayFsm,
  widgetFallbackMethods
} from "../../app/frontend/lib/shopWidgetPayFsm.js"

describe("shopWidgetPayFsm — states enum", () => {
  it("exports IDLE, PROCESSING, SUCCESS, ERROR, FALLBACK states", () => {
    assert.equal(WIDGET_FSM_STATES.IDLE, "IDLE")
    assert.equal(WIDGET_FSM_STATES.PROCESSING, "PROCESSING")
    assert.equal(WIDGET_FSM_STATES.SUCCESS, "SUCCESS")
    assert.equal(WIDGET_FSM_STATES.ERROR, "ERROR")
    assert.equal(WIDGET_FSM_STATES.FALLBACK, "FALLBACK")
  })
})

describe("createWidgetPayFsm — state transitions", () => {
  it("starts in IDLE state", () => {
    const fsm = createWidgetPayFsm()
    assert.equal(fsm.state, WIDGET_FSM_STATES.IDLE)
  })

  it("transitions IDLE → PROCESSING on start()", () => {
    const fsm = createWidgetPayFsm()
    fsm.start()
    assert.equal(fsm.state, WIDGET_FSM_STATES.PROCESSING)
  })

  it("transitions PROCESSING → SUCCESS on confirm()", () => {
    const fsm = createWidgetPayFsm()
    fsm.start()
    fsm.confirm()
    assert.equal(fsm.state, WIDGET_FSM_STATES.SUCCESS)
  })

  it("transitions PROCESSING → FALLBACK on reject() with card error", () => {
    const fsm = createWidgetPayFsm()
    fsm.start()
    fsm.reject({ error_code: "1051" })
    assert.equal(fsm.state, WIDGET_FSM_STATES.FALLBACK)
  })

  it("transitions PROCESSING → ERROR on reject() with non-card error", () => {
    const fsm = createWidgetPayFsm()
    fsm.start()
    fsm.reject({ error_code: "9999" })
    assert.equal(fsm.state, WIDGET_FSM_STATES.ERROR)
  })

  it("preserves orderId through transitions", () => {
    const fsm = createWidgetPayFsm({ orderId: "abc-123" })
    fsm.start()
    fsm.reject({ error_code: "1051" })
    assert.equal(fsm.orderId, "abc-123")
  })
})

describe("widgetFallbackMethods — available methods", () => {
  it("returns sbp and card_plus options", () => {
    const methods = widgetFallbackMethods()
    assert.ok(methods.some(m => m.id === "sbp"))
    assert.ok(methods.some(m => m.id === "card_plus"))
  })
})
