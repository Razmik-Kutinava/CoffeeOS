/**
 * RED: каскад OTP Flash×2 → SMS (без Messenger).
 *
 * node --test test/javascript/shop_phone_auth_cascade_smsru_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import {
  CASCADE_PHASE,
  FLASH_WAIT_SEC,
  SMS_COOLDOWN_SEC,
  initialFlashCascade,
  tickFlashCascade,
  showRetryFlashButton,
  showSmsButton,
  afterManualFlashResend,
  afterSmsSend,
  cascadeHint,
  cascadeTimerLabel,
  FLASH_HINT,
  SMS_BTN_LABEL,
  smsSentHint
} from "../../app/frontend/lib/phoneAuthCascade.js"

describe("CASCADE_PHASE — no MESSENGER phase", () => {
  it("has FLASH_1, FLASH_2, SMS but NOT MESSENGER", () => {
    assert.ok(CASCADE_PHASE.FLASH_1)
    assert.ok(CASCADE_PHASE.FLASH_2)
    assert.ok(CASCADE_PHASE.SMS)
    assert.equal(CASCADE_PHASE.MESSENGER, undefined)
  })
})

describe("initialFlashCascade — starts at FLASH_1 with 20s", () => {
  it("returns phase FLASH_1 with 20 seconds", () => {
    const s = initialFlashCascade()
    assert.equal(s.phase, CASCADE_PHASE.FLASH_1)
    assert.equal(s.secondsLeft, FLASH_WAIT_SEC)
  })
})

describe("tickFlashCascade — Flash #1 → Flash #2 → SMS", () => {
  it("FLASH_1 counts down from 20 to 1 then transitions to FLASH_2 with autoSend flash_call", () => {
    let state = { phase: CASCADE_PHASE.FLASH_1, secondsLeft: 1, lastChannel: null }
    const next = tickFlashCascade(state)
    assert.equal(next.phase, CASCADE_PHASE.FLASH_2)
    assert.equal(next.secondsLeft, FLASH_WAIT_SEC)
    assert.equal(next.autoSend, "flash_call")
  })

  it("FLASH_2 at secondsLeft=1 transitions directly to SMS (not MESSENGER)", () => {
    let state = { phase: CASCADE_PHASE.FLASH_2, secondsLeft: 1, lastChannel: "flash_call" }
    const next = tickFlashCascade(state)
    assert.equal(next.phase, CASCADE_PHASE.SMS)
    assert.equal(next.autoSend, "sms")
  })

  it("total cascade: 20s FLASH_1 + 20s FLASH_2 = SMS at 40s", () => {
    let state = initialFlashCascade()
    let totalTicks = 0
    while (state.phase !== CASCADE_PHASE.SMS) {
      state = tickFlashCascade(state)
      totalTicks++
      if (totalTicks > 100) break
    }
    assert.equal(state.phase, CASCADE_PHASE.SMS)
    assert.equal(totalTicks, 40)
  })
})

describe("showSmsButton — appears at SMS phase", () => {
  it("true when phase is SMS", () => {
    assert.ok(showSmsButton(CASCADE_PHASE.SMS))
  })
  it("false when phase is FLASH_1", () => {
    assert.ok(!showSmsButton(CASCADE_PHASE.FLASH_1))
  })
})

describe("showRetryFlashButton — appears at FLASH_2", () => {
  it("true when phase is FLASH_2", () => {
    assert.ok(showRetryFlashButton(CASCADE_PHASE.FLASH_2))
  })
  it("false when phase is FLASH_1", () => {
    assert.ok(!showRetryFlashButton(CASCADE_PHASE.FLASH_1))
  })
})

describe("afterSmsSend — SMS cooldown 60s", () => {
  it("returns SMS phase with 60s cooldown", () => {
    const s = afterSmsSend()
    assert.equal(s.phase, CASCADE_PHASE.SMS)
    assert.equal(s.secondsLeft, SMS_COOLDOWN_SEC)
    assert.equal(s.lastChannel, "sms")
  })
})

describe("smsSentHint — includes phone number", () => {
  it("contains formatted phone and '4-значный код в СМС'", () => {
    const hint = smsSentHint("+7 (900) 111-22-33")
    assert.match(hint, /4-значный код в СМС/)
    assert.match(hint, /\+7.*900/)
  })
})

describe("cascadeHint — flash vs sms", () => {
  it("returns FLASH_HINT for flash channel", () => {
    assert.equal(cascadeHint({ lastChannel: null }), FLASH_HINT)
  })
  it("returns SMS hint for sms channel", () => {
    const hint = cascadeHint({ lastChannel: "sms", phoneDisplay: "+7 (900) 111-22-33" })
    assert.match(hint, /СМС|код/i)
  })
})

describe("cascadeTimerLabel — flash waiting vs SMS cooldown", () => {
  it("shows 'Ждем звонок...' for FLASH phases", () => {
    const label = cascadeTimerLabel({ phase: CASCADE_PHASE.FLASH_1, secondsLeft: 15 })
    assert.match(label, /Ждем звонок/)
  })
  it("shows SMS retry timer for SMS phase with cooldown", () => {
    const label = cascadeTimerLabel({ phase: CASCADE_PHASE.SMS, secondsLeft: 45, lastChannel: "sms" })
    assert.match(label, /SMS|СМС/i)
  })
})
