/** Форма новой карты (макет 1000008924) — валидация и стейт save_card. */

export function digitsOnly(value) {
  return String(value ?? "").replace(/\D/g, "")
}

/** Маска PAN: группы по 4 цифры (до 19 цифр ISO). */
export function formatPanMask(input) {
  const digits = digitsOnly(input).slice(0, 19)
  return digits.replace(/(\d{4})(?=\d)/g, "$1 ").trim()
}

export function panDigitsFromMask(panMasked) {
  return digitsOnly(panMasked)
}

/** Алгоритм Луна. */
export function isLuhnValid(pan) {
  const digits = digitsOnly(pan)
  if (digits.length < 12 || digits.length > 19) return false

  let sum = 0
  let alt = false
  for (let i = digits.length - 1; i >= 0; i--) {
    let n = digits.charCodeAt(i) - 48
    if (alt) {
      n *= 2
      if (n > 9) n -= 9
    }
    sum += n
    alt = !alt
  }
  return sum % 10 === 0
}

/** ММ/ГГ с автослэшем. */
export function formatExpDate(input) {
  const digits = digitsOnly(input).slice(0, 4)
  if (digits.length <= 2) return digits
  return `${digits.slice(0, 2)}/${digits.slice(2)}`
}

export function isExpDateValid(expDate) {
  const m = String(expDate ?? "").match(/^(\d{2})\/(\d{2})$/)
  if (!m) return false
  const month = Number(m[1])
  if (month < 1 || month > 12) return false
  return true
}

export function isCvvValid(cvv) {
  return /^\d{3,4}$/.test(String(cvv ?? ""))
}

export function createNewCardFormState() {
  return {
    pan_masked: "",
    exp_date: "",
    cvv: "",
    save_card: true
  }
}

export function applyPanInput(state, raw) {
  return { ...state, pan_masked: formatPanMask(raw) }
}

export function applyExpInput(state, raw) {
  return { ...state, exp_date: formatExpDate(raw) }
}

export function applyCvvInput(state, raw) {
  const cvv = digitsOnly(raw).slice(0, 4)
  return { ...state, cvv }
}

export function setSaveCard(state, value) {
  return { ...state, save_card: !!value }
}

export function isPayEnabled(state) {
  if (!state) return false
  const pan = panDigitsFromMask(state.pan_masked)
  return (
    isLuhnValid(pan) &&
    isExpDateValid(state.exp_date) &&
    isCvvValid(state.cvv)
  )
}

/**
 * Снимок, безопасный для Network/логов: без открытого PAN и CVV.
 * Полный PAN и CVV остаются только в локальном стейте формы до RSA (Шаг 2).
 */
export function formNetworkSnapshot(state) {
  const pan = panDigitsFromMask(state?.pan_masked)
  const last4 = pan.length >= 4 ? pan.slice(-4) : ""
  return {
    save_card: !!state?.save_card,
    exp_date: String(state?.exp_date ?? ""),
    pan_mask: last4 ? `*${last4}` : ""
  }
}
