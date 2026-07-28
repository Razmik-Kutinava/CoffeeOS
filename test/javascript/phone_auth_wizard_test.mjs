/**
 * Auth funnel wizard — Шаг 1–2: телефон → flash_call → PIN auto-verify.
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
