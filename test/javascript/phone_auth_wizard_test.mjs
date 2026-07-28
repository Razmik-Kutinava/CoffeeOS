/**
 * Auth funnel wizard — Шаг 1: Экран 1 (телефон → flash_call → Экран 2).
 * Node: node --test test/javascript/phone_auth_wizard_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import {
  WIZARD_SCREEN,
  nationalPhoneDigits,
  canContinuePhone,
  buildFlashCallSendBody,
  nextScreenAfterSend
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
