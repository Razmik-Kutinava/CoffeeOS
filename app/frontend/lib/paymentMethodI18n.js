/** i18n подписей способов оплаты (канон макета + ТЗ SBP **** 1234). */

/** Маска карты для sheet: «**** 1234» (Шаг 10 ТЗ Т-Касса v2). */
export function formatMaskedPan(card) {
  const raw = card?.pan || card?.masked_pan || ""
  const digits = String(raw).replace(/\D/g, "")
  if (digits.length >= 4) return `**** ${digits.slice(-4)}`
  return "**** ????"
}

export function formatCardRowLabel(card) {
  return formatMaskedPan(card)
}

export function labelAddCard() {
  return "Картой +"
}

export function ctaAddCard() {
  return "Добавить карту"
}

export function ctaPay() {
  return "Оплатить"
}

export function labelSbp() {
  return "СБП"
}

/** #34 Zero-Click: сохранённый счёт СБП. */
export function labelSbpAccount() {
  return "Ваш счет СБП"
}

/** Чекбокс привязки счёта при первой оплате СБП. */
export function labelBindSbpAccount() {
  return "Привязать счет для покупок в один клик"
}

/** CTA кнопки оплаты при выбранном СБП (CODE:BLACK / deep link). */
export function ctaSbpFastPay() {
  return "Оплатить быстро"
}

export function ctaSbpAccountPay() {
  return "Оплатить"
}

export function sbpUnavailable() {
  return "СБП временно недоступно"
}

export function paymentMethodLoadErrorMessage() {
  return "Не удалось загрузить способы оплаты"
}

export function paymentMethodRetryLabel() {
  return "Повторить"
}
