/** Хелперы телефона / Flash Call для PWA auth. */

export function digitsOnly(value) {
  return String(value || "").replace(/\D/g, "")
}

/**
 * Маска отображения: +7 (XXX) XXX-XX-XX
 */
export function formatPhoneMask(input) {
  let d = digitsOnly(input)
  if (d.startsWith("8") && d.length >= 11) d = "7" + d.slice(1)
  if (d.startsWith("7")) d = d.slice(1)
  d = d.slice(0, 10)
  const a = d.slice(0, 3)
  const b = d.slice(3, 6)
  const c = d.slice(6, 8)
  const e = d.slice(8, 10)
  let out = "+7"
  if (a) out += ` (${a}`
  if (a.length === 3) out += ")"
  if (b) out += ` ${b}`
  if (c) out += `-${c}`
  if (e) out += `-${e}`
  return out
}

/** @returns {string|null} +79XXXXXXXXX или null */
export function normalizePhoneToE164Ru(input) {
  let d = digitsOnly(input)
  if (d.length === 11 && d.startsWith("8")) d = "7" + d.slice(1)
  if (d.length === 10 && d.startsWith("9")) d = "7" + d
  if (!/^7\d{10}$/.test(d)) return null
  return `+${d}`
}

export function flashCallHint() {
  return "Введите последние 4 цифры номера, с которого вам звонят"
}

export const PHONE_OTP_COOLDOWN_SEC = 60
