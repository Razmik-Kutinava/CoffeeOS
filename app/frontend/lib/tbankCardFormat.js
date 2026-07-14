/** Формат CardData для Т-Банка nonPCI: PAN;ExpDate;CVV (key=value). */

const PAN_MAX_DIGITS = 19

export function digitsOnly(value) {
  return String(value || "").replace(/\D/g, "")
}

export function formatPanInput(value) {
  const digits = digitsOnly(value).slice(0, PAN_MAX_DIGITS)
  return digits.replace(/(\d{4})(?=\d)/g, "$1 ").trim()
}

/** ММ/ГГ → ExpDate MMYY для CardData. */
export function expDateForCardData(display) {
  const digits = digitsOnly(display)
  if (digits.length !== 4) return null
  const month = Number(digits.slice(0, 2))
  if (month < 1 || month > 12) return null
  return digits
}

export function normalizeCardHolder(name) {
  const cleaned = String(name || "")
    .trim()
    .replace(/\s+/g, " ")
    .toUpperCase()
  return cleaned || "CARDHOLDER"
}

/** Официальный контракт: PAN=…;ExpDate=MMYY;CardHolder=…;CVV=… */
export function buildCardDataString({ pan, expDate, cvv, cardHolder }) {
  const panDigits = digitsOnly(pan)
  const cvvDigits = digitsOnly(cvv).slice(0, 4)
  const holder = normalizeCardHolder(cardHolder)
  return `PAN=${panDigits};ExpDate=${expDate};CardHolder=${holder};CVV=${cvvDigits}`
}
