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

import {
  WIDGET_STATUS_LABELS,
  WIDGET_POLL_MS,
  WIDGET_POLL_MAX,
  isCardRelatedError
} from "../../app/frontend/lib/widgetInlinePay.js"

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

describe("widgetInlinePay — labels and config", () => {
  it("exports status labels", () => {
    assert.equal(WIDGET_STATUS_LABELS.PROCESSING, "статусы от банка")
    assert.equal(WIDGET_STATUS_LABELS.SUCCESS, "Оплачено!")
    assert.equal(WIDGET_STATUS_LABELS.ERROR, "Ошибка оплаты")
  })

  it("exports poll config", () => {
    assert.equal(WIDGET_POLL_MS, 2000)
    assert.equal(WIDGET_POLL_MAX, 15)
  })
})

describe("isCardRelatedError — card error detection", () => {
  it("detects 1051 as card error", () => {
    assert.ok(isCardRelatedError({ error_code: "1051" }))
  })

  it("detects 1005 as card error", () => {
    assert.ok(isCardRelatedError({ error_code: "1005" }))
  })

  it("rejects generic error codes", () => {
    assert.ok(!isCardRelatedError({ error_code: "9999" }))
  })

  it("handles missing error_code", () => {
    assert.ok(!isCardRelatedError({}))
    assert.ok(!isCardRelatedError(null))
  })
})

describe("FSM + fallback integration flow", () => {
  it("card error 1051 → FALLBACK → fallback methods available", () => {
    const fsm = createWidgetPayFsm({ orderId: "order-x" })
    fsm.start()
    assert.equal(fsm.state, WIDGET_FSM_STATES.PROCESSING)

    const errorData = { error_code: "1051" }
    assert.ok(isCardRelatedError(errorData))
    fsm.reject(errorData)
    assert.equal(fsm.state, WIDGET_FSM_STATES.FALLBACK)
    assert.equal(fsm.orderId, "order-x")

    const methods = widgetFallbackMethods()
    assert.equal(methods.length, 2)
  })

  it("non-card error → ERROR (no fallback)", () => {
    const fsm = createWidgetPayFsm()
    fsm.start()
    fsm.reject({ error_code: "5001" })
    assert.equal(fsm.state, WIDGET_FSM_STATES.ERROR)
  })

  it("reset() returns to IDLE from any state", () => {
    const fsm = createWidgetPayFsm()
    fsm.start()
    fsm.reject({ error_code: "1051" })
    assert.equal(fsm.state, WIDGET_FSM_STATES.FALLBACK)
    fsm.reset()
    assert.equal(fsm.state, WIDGET_FSM_STATES.IDLE)
  })
})
