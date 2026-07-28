/**
 * Auth funnel wizard — Шаг 1–3: телефон → PIN → Flash cascade.
 * Node: node --test test/javascript/phone_auth_wizard_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import {
  WIZARD_SCREEN,
  PIN_LENGTH,
  nationalPhoneDigits,
  canContinuePhone,
  buildFlashCallSendBody,
  nextScreenAfterSend,
  emptyPinCells,
  pinCodeFromCells,
  applyPinDigit,
  pinBackspaceFocus,
  shouldAutoSubmitPin,
  buildVerifyBody
} from "../../app/frontend/lib/phoneAuthWizard.js"
import {
  FLASH_WAIT_SEC,
  FLASH_HINT,
  RETRY_FLASH_LABEL,
  formatMmSs,
  waitingCallLabel,
  initialFlashCascade,
  tickFlashCascade,
  showRetryFlashButton,
  afterManualFlashResend
} from "../../app/frontend/lib/phoneAuthCascade.js"
import { formatPhoneMask, normalizePhoneToE164Ru } from "../../app/frontend/lib/phoneOtp.js"

describe("phoneAuthWizard Screen 1", () => {
  it("nationalPhoneDigits counts 10 national digits from mask", () => {
    assert.equal(nationalPhoneDigits("+7 (900) 123-45-67"), 10)
    assert.equal(nationalPhoneDigits("+7 (900) 12"), 5)
    assert.equal(nationalPhoneDigits("+7"), 0)
  })

  it("canContinuePhone only when exactly 10 national digits", () => {
    assert.equal(canContinuePhone("+7 (900) 123-45-6"), false)
    assert.equal(canContinuePhone("+7 (900) 123-45-67"), true)
    assert.equal(canContinuePhone(formatPhoneMask("9001234567")), true)
  })

  it("buildFlashCallSendBody uses channel flash_call and E164 phone", () => {
    const phone = normalizePhoneToE164Ru("9001234567")
    assert.deepEqual(buildFlashCallSendBody(phone), {
      phone: "+79001234567",
      channel: "flash_call"
    })
  })

  it("nextScreenAfterSend goes to CODE screen", () => {
    assert.equal(nextScreenAfterSend(WIZARD_SCREEN.PHONE), WIZARD_SCREEN.CODE)
  })

  it("rejects continue for incomplete number", () => {
    assert.equal(canContinuePhone("+7 (900)"), false)
    assert.equal(normalizePhoneToE164Ru("+7 (900)"), null)
  })
})

describe("phoneAuthWizard Screen 2 PIN", () => {
  it("emptyPinCells has PIN_LENGTH blanks", () => {
    assert.equal(PIN_LENGTH, 4)
    assert.deepEqual(emptyPinCells(), ["", "", "", ""])
  })

  it("applyPinDigit fills cell and advances focus", () => {
    const r = applyPinDigit(emptyPinCells(), 0, "9")
    assert.deepEqual(r.cells, ["9", "", "", ""])
    assert.equal(r.code, "9")
    assert.equal(r.focusIndex, 1)
  })

  it("shouldAutoSubmitPin only on 4th digit", () => {
    assert.equal(shouldAutoSubmitPin("123"), false)
    assert.equal(shouldAutoSubmitPin("1234"), true)
    let cells = emptyPinCells()
    ;["1", "2", "3", "4"].forEach((d, i) => {
      const r = applyPinDigit(cells, i, d)
      cells = r.cells
      assert.equal(shouldAutoSubmitPin(r.code), i === 3)
    })
    assert.equal(pinCodeFromCells(cells), "1234")
  })

  it("buildVerifyBody sends phone and code", () => {
    assert.deepEqual(buildVerifyBody("+79001234567", "1234"), {
      phone: "+79001234567",
      code: "1234"
    })
  })

  it("pinBackspaceFocus moves left on empty cell", () => {
    assert.equal(pinBackspaceFocus(["1", "", "", ""], 1), 0)
    assert.equal(pinBackspaceFocus(["1", "2", "", ""], 1), 1)
  })
})

describe("phoneAuthCascade Flash #1/#2", () => {
  it("formats timer as MM:SS and waiting label", () => {
    assert.equal(FLASH_WAIT_SEC, 20)
    assert.equal(formatMmSs(20), "00:20")
    assert.equal(formatMmSs(5), "00:05")
    assert.equal(waitingCallLabel(20), "Ждем звонок... 00:20")
    assert.match(FLASH_HINT, /4 цифр/)
    assert.equal(RETRY_FLASH_LABEL, "Запросить звонок еще раз")
  })

  it("initial cascade is round 1 with 20s", () => {
    assert.deepEqual(initialFlashCascade(), { flashRound: 1, secondsLeft: 20 })
  })

  it("ticks down without resend until last second of round 1", () => {
    let s = initialFlashCascade()
    for (let i = 0; i < 19; i++) {
      const t = tickFlashCascade(s)
      assert.equal(t.autoResend, false)
      s = { flashRound: t.flashRound, secondsLeft: t.secondsLeft }
    }
    assert.equal(s.secondsLeft, 1)
    assert.equal(s.flashRound, 1)
    assert.equal(showRetryFlashButton(s.flashRound), false)
  })

  it("auto-resends flash on end of round 1 and starts round 2", () => {
    const t = tickFlashCascade({ flashRound: 1, secondsLeft: 1 })
    assert.equal(t.autoResend, true)
    assert.equal(t.flashRound, 2)
    assert.equal(t.secondsLeft, 20)
    assert.equal(showRetryFlashButton(t.flashRound), true)
  })

  it("round 2 ends at 0 without autoResend (messenger later)", () => {
    const t = tickFlashCascade({ flashRound: 2, secondsLeft: 1 })
    assert.equal(t.autoResend, false)
    assert.equal(t.secondsLeft, 0)
    assert.equal(showRetryFlashButton(2), true)
  })

  it("afterManualFlashResend resets 20s on round >= 2", () => {
    assert.deepEqual(afterManualFlashResend(2), { flashRound: 2, secondsLeft: 20 })
    assert.deepEqual(afterManualFlashResend(1), { flashRound: 2, secondsLeft: 20 })
  })
})
