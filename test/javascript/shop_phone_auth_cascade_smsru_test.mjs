/**
 * Callcheck → SMS fallback state machine.
 * node --test test/javascript/shop_phone_auth_cascade_smsru_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import {
  AUTH_PHASE,
  CALLCHECK_TIMEOUT_SEC,
  CALLCHECK_POLL_MS,
  SMS_COOLDOWN_SEC,
  initialCallcheckState,
  tickCallcheck,
  afterSmsSend,
  showSmsPin,
  cascadeHint,
  cascadeTimerLabel,
  CALLCHECK_HINT,
  SMS_BTN_LABEL,
  telHrefFromCallPhone,
  smsSentHint
} from "../../app/frontend/lib/phoneAuthCascade.js"

describe("AUTH_PHASE", () => {
  it("has CALLCHECK and SMS only", () => {
    assert.equal(AUTH_PHASE.CALLCHECK, "callcheck")
    assert.equal(AUTH_PHASE.SMS, "sms")
    assert.equal(AUTH_PHASE.FLASH_1, undefined)
  })
})

describe("initialCallcheckState", () => {
  it("starts callcheck with 40s and dial payload", () => {
    const s = initialCallcheckState({
      check_id: "abc",
      call_phone: "74995555555",
      call_phone_pretty: "+7 (499) 555-55-55",
      call_phone_html: '<a href="tel:+74995555555">x</a>'
    })
    assert.equal(s.phase, AUTH_PHASE.CALLCHECK)
    assert.equal(s.secondsLeft, CALLCHECK_TIMEOUT_SEC)
    assert.equal(s.checkId, "abc")
    assert.equal(CALLCHECK_POLL_MS, 3000)
  })
})

describe("tickCallcheck", () => {
  it("counts down then transitions to SMS with autoSend", () => {
    let state = { ...initialCallcheckState(), secondsLeft: 1 }
    const next = tickCallcheck(state)
    assert.equal(next.phase, AUTH_PHASE.SMS)
    assert.equal(next.autoSend, "sms")
    assert.equal(next.timedOut, true)
  })

  it("timeout after 40 ticks", () => {
    let state = initialCallcheckState()
    let ticks = 0
    while (state.phase === AUTH_PHASE.CALLCHECK) {
      state = tickCallcheck(state)
      ticks++
      if (ticks > 50) break
    }
    assert.equal(state.phase, AUTH_PHASE.SMS)
    assert.equal(ticks, 40)
  })
})

describe("SMS pin visibility", () => {
  it("pin only after sms sent", () => {
    assert.equal(showSmsPin(AUTH_PHASE.CALLCHECK, false), false)
    assert.equal(showSmsPin(AUTH_PHASE.SMS, false), false)
    assert.equal(showSmsPin(AUTH_PHASE.SMS, true), true)
  })
})

describe("hints and tel", () => {
  it("callcheck hint then sms hint", () => {
    assert.equal(cascadeHint({ phase: AUTH_PHASE.CALLCHECK }), CALLCHECK_HINT)
    assert.match(smsSentHint("+7 (900) 111-22-33"), /СМС/)
    assert.equal(SMS_BTN_LABEL.includes("СМС"), true)
  })

  it("telHrefFromCallPhone", () => {
    assert.equal(telHrefFromCallPhone("74995555555"), "tel:+74995555555")
  })

  it("afterSmsSend sets cooldown", () => {
    const s = afterSmsSend(initialCallcheckState())
    assert.equal(s.phase, AUTH_PHASE.SMS)
    assert.equal(s.secondsLeft, SMS_COOLDOWN_SEC)
    assert.equal(s.smsSent, true)
  })

  it("timer labels", () => {
    assert.match(cascadeTimerLabel({ phase: AUTH_PHASE.CALLCHECK, secondsLeft: 9 }), /00:09/)
  })
})
