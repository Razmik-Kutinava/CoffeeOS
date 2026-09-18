/**
 * Phone auth wizard helpers — Callcheck + SMS.
 * node --test test/javascript/phone_auth_wizard_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"
import {
  WIZARD_SCREEN,
  PIN_LENGTH,
  nationalPhoneDigits,
  canContinuePhone,
  buildInitCallcheckBody,
  buildSendSmsBody,
  nextScreenAfterInit,
  emptyPinCells,
  pinCodeFromCells,
  applyPinDigit,
  shouldAutoSubmitPin,
  buildVerifySmsBody
} from "../../app/frontend/lib/phoneAuthWizard.js"
import { formatPhoneMask, normalizePhoneToE164Ru } from "../../app/frontend/lib/phoneOtp.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")

describe("phoneAuthWizard Screen 1", () => {
  it("nationalPhoneDigits counts 10 national digits from mask", () => {
    assert.equal(nationalPhoneDigits("+7 (900) 123-45-67"), 10)
    assert.equal(nationalPhoneDigits("+7 (900) 12"), 5)
  })

  it("canContinuePhone only when exactly 10 national digits", () => {
    assert.equal(canContinuePhone("+7 (900) 123-45-6"), false)
    assert.equal(canContinuePhone("+7 (900) 123-45-67"), true)
    assert.equal(canContinuePhone(formatPhoneMask("9001234567")), true)
  })

  it("buildInitCallcheckBody has phone only", () => {
    const phone = normalizePhoneToE164Ru("9001234567")
    assert.deepEqual(buildInitCallcheckBody(phone), { phone })
  })

  it("buildSendSmsBody has phone only", () => {
    const phone = normalizePhoneToE164Ru("9001234567")
    assert.deepEqual(buildSendSmsBody(phone), { phone })
  })

  it("nextScreenAfterInit goes to VERIFY", () => {
    assert.equal(nextScreenAfterInit(WIZARD_SCREEN.PHONE), WIZARD_SCREEN.VERIFY)
  })
})

describe("#90 POSTCALL-EXT lifecycle wiring", () => {
  it("PhoneAuthCodeStep resumes Callcheck on visibility/pageshow without init_callcheck", () => {
    const step = readFileSync(
      join(root, "app/frontend/components/PhoneAuthCodeStep.svelte"),
      "utf8"
    )
    const wizard = readFileSync(
      join(root, "app/frontend/components/PhoneAuthWizard.svelte"),
      "utf8"
    )
    assert.match(step, /visibilitychange/)
    assert.match(step, /pageshow/)
    assert.match(step, /pagehide/)
    assert.match(step, /markLeftForDial/)
    assert.match(step, /callcheckForegroundAction/)
    assert.match(step, /\/phone_otp\/init_callcheck/)
    assert.match(step, /retryCallcheck/)
    // Wizard: first init from continue CTA; CodeStep retries Callcheck #2 on timer
    assert.match(wizard, /init_callcheck/)
    assert.doesNotMatch(wizard, /visibilitychange/)
    assert.doesNotMatch(wizard, /pageshow/)
    assert.doesNotMatch(wizard, /pagehide/)
  })
})

describe("PIN helpers", () => {
  it("PIN_LENGTH is 6", () => {
    assert.equal(PIN_LENGTH, 6)
    assert.equal(emptyPinCells().length, 6)
  })

  it("applyPinDigit and auto-submit", () => {
    let cells = emptyPinCells()
    let code = ""
    for (let i = 0; i < 6; i++) {
      const r = applyPinDigit(cells, i, String((i + 1) % 10))
      cells = r.cells
      code = r.code
    }
    assert.equal(code, "123456")
    assert.equal(shouldAutoSubmitPin(code), true)
    assert.deepEqual(buildVerifySmsBody("+79001234567", code), {
      phone: "+79001234567",
      code: "123456"
    })
    assert.equal(pinCodeFromCells(cells), "123456")
  })
})
