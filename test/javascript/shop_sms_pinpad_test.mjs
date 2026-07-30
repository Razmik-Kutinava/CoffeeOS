/**
 * SMS pinpad unit tests — #32 скрин.
 * node --test test/javascript/shop_sms_pinpad_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import {
  SMS_PIN_LENGTH,
  SMS_PIN_TIMER_SEC,
  createSmsPinPadState,
  formatSmsTimer,
  appendSmsDigit,
  backspaceSmsDigit,
  tickSmsTimer,
  isSmsCodeComplete
} from "../../app/frontend/lib/shopSmsPinPad.js"

describe("shopSmsPinPad", () => {
  it("starts at 00:59", () => {
    const s = createSmsPinPadState()
    assert.equal(s.secondsLeft, SMS_PIN_TIMER_SEC)
    assert.equal(formatSmsTimer(s.secondsLeft), "00:59")
  })

  it("formats timer as MM:SS", () => {
    assert.equal(formatSmsTimer(59), "00:59")
    assert.equal(formatSmsTimer(0), "00:00")
    assert.equal(formatSmsTimer(90), "01:30")
  })

  it("appends digits up to length 4", () => {
    let s = createSmsPinPadState()
    s = appendSmsDigit(s, "1")
    s = appendSmsDigit(s, "2")
    s = appendSmsDigit(s, "3")
    s = appendSmsDigit(s, "4")
    s = appendSmsDigit(s, "5")
    assert.equal(s.code, "1234")
    assert.equal(SMS_PIN_LENGTH, 4)
    assert.ok(isSmsCodeComplete(s))
  })

  it("backspaces last digit", () => {
    let s = createSmsPinPadState()
    s = appendSmsDigit(s, "9")
    s = appendSmsDigit(s, "8")
    s = backspaceSmsDigit(s)
    assert.equal(s.code, "9")
  })

  it("ticks timer down and stops at 0", () => {
    let s = createSmsPinPadState({ secondsLeft: 2 })
    s = tickSmsTimer(s)
    assert.equal(s.secondsLeft, 1)
    s = tickSmsTimer(s)
    assert.equal(s.secondsLeft, 0)
    s = tickSmsTimer(s)
    assert.equal(s.secondsLeft, 0)
  })
})
