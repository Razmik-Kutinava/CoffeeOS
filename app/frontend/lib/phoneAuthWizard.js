/** Стейт и хелперы 2-экранного phone auth wizard (каскад OTP). */

export const WIZARD_SCREEN = Object.freeze({
  PHONE: 1,
  CODE: 2
})

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

/** Тело POST /shop/api/phone_otp/send для старта каскада. */
export function buildFlashCallSendBody(phoneE164) {
  return { phone: phoneE164, channel: "flash_call" }
}

export function nextScreenAfterSend(current = WIZARD_SCREEN.PHONE) {
  return current === WIZARD_SCREEN.PHONE ? WIZARD_SCREEN.CODE : current
}
