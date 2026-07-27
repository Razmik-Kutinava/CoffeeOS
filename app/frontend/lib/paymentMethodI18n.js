/** i18n подписей способов оплаты (канон макета repeat invalid token). */

import { panFromCard } from "./paymentMethodLabels.js"

export function formatCardRowLabel(card) {
  return `Картой ${panFromCard(card)}`
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

/** CTA кнопки оплаты при выбранном СБП (CODE:BLACK / deep link). */
export function ctaSbpFastPay() {
  return "Оплатить быстро"
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
