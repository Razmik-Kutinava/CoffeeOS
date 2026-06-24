/** B1.12-R2 — маски, Luhn, сбор CardData для Т-Банка nonPCI. */

const PAN_MAX_DIGITS = 19

export function digitsOnly(value) {
  return String(value || "").replace(/\D/g, "")
}

/** `4300 0000 0000 5953` */
export function formatPanInput(value) {
  const digits = digitsOnly(value).slice(0, PAN_MAX_DIGITS)
  return digits.replace(/(\d{4})(?=\d)/g, "$1 ").trim()
}

/** `12 / 28` */
export function formatExpiryInput(value) {
  const digits = digitsOnly(value).slice(0, 4)
  if (digits.length <= 2) return digits
  return `${digits.slice(0, 2)} / ${digits.slice(2)}`
}

export function parseExpiry(display) {
  const digits = digitsOnly(display)
  if (digits.length !== 4) return null
  const month = Number(digits.slice(0, 2))
  const year = digits.slice(2)
  if (month < 1 || month > 12) return null
  return { month, expDate: `${digits.slice(0, 2)}${year}` }
}

export function luhnValid(pan) {
  const digits = digitsOnly(pan)
  if (digits.length < 13 || digits.length > PAN_MAX_DIGITS) return false

  let sum = 0
  let alt = false
  for (let i = digits.length - 1; i >= 0; i -= 1) {
    let n = Number(digits[i])
    if (alt) {
      n *= 2
      if (n > 9) n -= 9
    }
    sum += n
    alt = !alt
  }
  return sum % 10 === 0
}

export function normalizeCardHolder(name) {
  const cleaned = String(name || "")
    .trim()
    .replace(/\s+/g, " ")
    .toUpperCase()
  return cleaned || "CARDHOLDER"
}

/** Официальный формат Т-Банка: ключ=значение, разделитель «;». */
export function buildCardDataString({ pan, expDate, cvv, cardHolder }) {
  const panDigits = digitsOnly(pan)
  const cvvDigits = digitsOnly(cvv).slice(0, 4)
  const holder = normalizeCardHolder(cardHolder)
  return `PAN=${panDigits};ExpDate=${expDate};CardHolder=${holder};CVV=${cvvDigits}`
}

export function validateCardFields({ pan, expiry, cvv }) {
  const errors = {}
  const panDigits = digitsOnly(pan)
  const cvvDigits = digitsOnly(cvv)
  const exp = parseExpiry(expiry)

  if (!panDigits) errors.pan = "Введите номер карты"
  else if (!luhnValid(panDigits)) errors.pan = "Неверный номер карты"

  if (!exp) errors.expiry = "Укажите срок ММ / ГГ"
  if (!cvvDigits || cvvDigits.length < 3) errors.cvv = "Введите CVC/CVV"

  return {
    valid: Object.keys(errors).length === 0,
    errors,
    expDate: exp?.expDate || null
  }
}

/** Для network audit: тело запроса не должно содержать сырой PAN/CVV. */
export function assertNoPlainCardInPayload(body, pan, cvv) {
  const raw = typeof body === "string" ? body : JSON.stringify(body || {})
  const panDigits = digitsOnly(pan)
  const cvvDigits = digitsOnly(cvv)
  if (panDigits.length >= 13 && raw.includes(panDigits)) {
    throw new Error("PAN must not appear in request payload")
  }
  if (cvvDigits.length >= 3 && raw.includes(cvvDigits)) {
    throw new Error("CVV must not appear in request payload")
  }
}
