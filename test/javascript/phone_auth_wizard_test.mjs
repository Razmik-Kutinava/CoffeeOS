/**
 * Auth funnel wizard — Шаг 1–4: телефон → PIN → Flash → Messenger → SMS.
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
  buildOtpSendBody,
  nextScreenAfterSend,
  emptyPinCells,
  pinCodeFromCells,
  applyPinDigit,
  pinBackspaceFocus,
  shouldAutoSubmitPin,
  buildVerifyBody
} from "../../app/frontend/lib/phoneAuthWizard.js"
import {
  CASCADE_PHASE,
  FLASH_WAIT_SEC,
  MESSENGER_WAIT_SEC,
  SMS_COOLDOWN_SEC,
  FLASH_HINT,
  RETRY_FLASH_LABEL,
  MESSENGER_BTN_LABEL,
  SMS_BTN_LABEL,
  formatMmSs,
  waitingCallLabel,
  messengerSentHint,
  initialFlashCascade,
  tickFlashCascade,
  showRetryFlashButton,
  showMessengerButton,
  showSmsButton,
  afterManualFlashResend,
  afterMessengerSend,
  afterSmsSend,
  afterMessengerDeliveryError
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

  it("buildOtpSendBody supports messenger and sms", () => {
    assert.deepEqual(buildOtpSendBody("+79001234567", "messenger"), {
      phone: "+79001234567",
      channel: "messenger"
    })
    assert.deepEqual(buildOtpSendBody("+79001234567", "sms"), {
      phone: "+79001234567",
      channel: "sms"
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
    assert.equal(waitingCallLabel(20), "Ждем звонок... 00:20")
    assert.match(FLASH_HINT, /4 цифр/)
    assert.equal(RETRY_FLASH_LABEL, "Запросить звонок еще раз")
  })

  it("initial cascade is flash_1 with 20s", () => {
    assert.deepEqual(initialFlashCascade(), {
      phase: CASCADE_PHASE.FLASH_1,
      secondsLeft: 20,
      lastChannel: null
    })
  })

  it("ticks down without autosend until last second of flash_1", () => {
    let s = initialFlashCascade()
    for (let i = 0; i < 19; i++) {
      const t = tickFlashCascade(s)
      assert.equal(t.autoSend, null)
      s = { phase: t.phase, secondsLeft: t.secondsLeft, lastChannel: t.lastChannel }
    }
    assert.equal(s.secondsLeft, 1)
    assert.equal(s.phase, CASCADE_PHASE.FLASH_1)
    assert.equal(showRetryFlashButton(s.phase), false)
  })

  it("auto flash_call on end of flash_1 → flash_2", () => {
    const t = tickFlashCascade({
      phase: CASCADE_PHASE.FLASH_1,
      secondsLeft: 1,
      lastChannel: null
    })
    assert.equal(t.autoSend, "flash_call")
    assert.equal(t.phase, CASCADE_PHASE.FLASH_2)
    assert.equal(t.secondsLeft, 20)
    assert.equal(showRetryFlashButton(t.phase), true)
  })

  it("end of flash_2 → messenger with auto messenger send", () => {
    const t = tickFlashCascade({
      phase: CASCADE_PHASE.FLASH_2,
      secondsLeft: 1,
      lastChannel: "flash_call"
    })
    assert.equal(t.autoSend, "messenger")
    assert.equal(t.phase, CASCADE_PHASE.MESSENGER)
    assert.equal(t.secondsLeft, 0)
    assert.equal(showMessengerButton(t.phase, t.secondsLeft), true)
  })

  it("afterManualFlashResend resets flash_2 20s", () => {
    assert.deepEqual(afterManualFlashResend(), {
      phase: CASCADE_PHASE.FLASH_2,
      secondsLeft: 20,
      lastChannel: "flash_call"
    })
  })
})

describe("phoneAuthCascade Messenger + SMS", () => {
  it("timings messenger 30 / sms 60", () => {
    assert.equal(MESSENGER_WAIT_SEC, 30)
    assert.equal(SMS_COOLDOWN_SEC, 60)
    assert.match(MESSENGER_BTN_LABEL, /WhatsApp/)
    assert.equal(SMS_BTN_LABEL, "Отправить код в СМС")
  })

  it("afterMessengerSend starts 30s wait", () => {
    assert.deepEqual(afterMessengerSend(), {
      phase: CASCADE_PHASE.MESSENGER,
      secondsLeft: 30,
      lastChannel: "messenger"
    })
    assert.equal(showMessengerButton(CASCADE_PHASE.MESSENGER, 30), false)
  })

  it("messenger timer end → sms phase", () => {
    const t = tickFlashCascade({
      phase: CASCADE_PHASE.MESSENGER,
      secondsLeft: 1,
      lastChannel: "messenger"
    })
    assert.equal(t.phase, CASCADE_PHASE.SMS)
    assert.equal(t.secondsLeft, 0)
    assert.equal(t.autoSend, null)
    assert.equal(showSmsButton(t.phase), true)
  })

  it("afterSmsSend starts 60s cooldown", () => {
    assert.deepEqual(afterSmsSend(), {
      phase: CASCADE_PHASE.SMS,
      secondsLeft: 60,
      lastChannel: "sms"
    })
  })

  it("messenger delivery error jumps to sms", () => {
    assert.deepEqual(afterMessengerDeliveryError(), {
      phase: CASCADE_PHASE.SMS,
      secondsLeft: 0,
      lastChannel: null
    })
    assert.match(messengerSentHint("+7 (900) 123-45-67"), /мессенджер/)
  })
})
