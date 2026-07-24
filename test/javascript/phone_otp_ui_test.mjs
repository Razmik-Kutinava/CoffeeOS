/**
 * Маска и нормализация телефона для PWA (зеркало бэкенд-формата +7).
 * Node: node --test test/javascript/phone_otp_ui_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import {
  digitsOnly,
  formatPhoneMask,
  normalizePhoneToE164Ru,
  flashCallHint
} from "../../app/frontend/lib/phoneOtp.js"

describe("phoneOtp ui helpers", () => {
  it("formats mask +7 (XXX) XXX-XX-XX", () => {
    assert.equal(formatPhoneMask("9001234567"), "+7 (900) 123-45-67")
  })

  it("normalizes 8900… to +79…", () => {
    assert.equal(normalizePhoneToE164Ru("89001234567"), "+79001234567")
  })

  it("rejects short input", () => {
    assert.equal(normalizePhoneToE164Ru("123"), null)
  })

  it("digitsOnly strips non-digits", () => {
    assert.equal(digitsOnly("+7 (900) 123"), "7900123")
  })

  it("flashCallHint is non-empty", () => {
    assert.match(flashCallHint(), /4 цифр/i)
  })
})
