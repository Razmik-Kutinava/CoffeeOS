/** Стейт и хелперы 2–3 экранного phone auth (Callcheck → SMS). */

export const WIZARD_SCREEN = Object.freeze({
  PHONE: 1,
  VERIFY: 2
})

export const PIN_LENGTH = 4

/** Национальные цифры после +7 (ожидаем 10). */
export function nationalPhoneDigits(display) {
  let d = String(display || "").replace(/\D/g, "")
  if (d.startsWith("8") && d.length >= 11) d = "7" + d.slice(1)
  if (d.startsWith("7")) d = d.slice(1)
  return d.slice(0, 10).length
}

export function canContinuePhone(display) {
  return nationalPhoneDigits(display) === 10
}

export function buildInitCallcheckBody(phoneE164) {
  return { phone: phoneE164 }
}

export function buildSendSmsBody(phoneE164) {
  return { phone: phoneE164 }
}

export function nextScreenAfterInit(current = WIZARD_SCREEN.PHONE) {
  return current === WIZARD_SCREEN.PHONE ? WIZARD_SCREEN.VERIFY : current
}

export function emptyPinCells() {
  return Array.from({ length: PIN_LENGTH }, () => "")
}

export function pinCodeFromCells(cells) {
  return (cells || []).map((c) => String(c || "").replace(/\D/g, "")).join("").slice(0, PIN_LENGTH)
}

export function applyPinDigit(cells, index, rawValue) {
  const next = emptyPinCells().map((_, i) => (cells && cells[i]) || "")
  const digits = String(rawValue || "").replace(/\D/g, "")
  const digit = digits.slice(-1)
  next[index] = digit
  const code = pinCodeFromCells(next)
  let focusIndex = index
  if (digit && index < PIN_LENGTH - 1) focusIndex = index + 1
  if (code.length >= PIN_LENGTH) focusIndex = PIN_LENGTH - 1
  return { cells: next, code, focusIndex }
}

export function pinBackspaceFocus(cells, index) {
  if ((cells[index] || "").length > 0) return index
  return Math.max(0, index - 1)
}

export function shouldAutoSubmitPin(code) {
  return String(code || "").replace(/\D/g, "").length === PIN_LENGTH
}

export function buildVerifySmsBody(phoneE164, code) {
  return { phone: phoneE164, code: String(code || "").replace(/\D/g, "").slice(0, PIN_LENGTH) }
}

/** @deprecated flash_call removed — aliases for old tests */
export function buildFlashCallSendBody(phoneE164) {
  return buildInitCallcheckBody(phoneE164)
}

export function buildOtpSendBody(phoneE164, channel) {
  if (String(channel) === "sms") return buildSendSmsBody(phoneE164)
  return buildInitCallcheckBody(phoneE164)
}

export function buildVerifyBody(phoneE164, code) {
  return buildVerifySmsBody(phoneE164, code)
}

export function nextScreenAfterSend(current) {
  return nextScreenAfterInit(current)
}
