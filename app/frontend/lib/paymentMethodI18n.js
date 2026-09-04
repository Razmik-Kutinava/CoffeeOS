/** i18n подписей способов оплаты (#26 скрин 03 + formatMaskedPan для Step10). */

/** Маска **** last4 — канон Step10 / API (не строка sheet). */
export function formatMaskedPan(card) {
  const raw = card?.pan || card?.masked_pan || ""
  const digits = String(raw).replace(/\D/g, "")
  if (digits.length >= 4) return `**** ${digits.slice(-4)}`
  return "**** ????"
}

/** Маска sheet: «*1594» (#26 скрин 03). */
export function formatCardMaskStar(card) {
  const raw = card?.pan || card?.masked_pan || ""
  const digits = String(raw).replace(/\D/g, "")
  if (digits.length >= 4) return `*${digits.slice(-4)}`
  return "*????"
}

/** Префикс «Картой» (оранжевый в UI). */
export function labelCardBy() {
  return "Картой"
}

/** Полная строка sheet: «Картой *1594». */
export function formatCardRowLabel(card) {
  return `${labelCardBy()} ${formatCardMaskStar(card)}`
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

/** #75 TOV сохранённого СБП без last4. */
export function labelSbpBoundUsual() {
  return "СБП · как обычно"
}

/** Чекбокс привязки счёта при первой оплате СБП. */
export function labelBindSbpAccount() {
  return "Привязать счет для покупок в один клик"
}

/** #75 промо: чекбокс включён. */
export function promoSaveToday11() {
  return "Сохрани — счёт сегодня 11 ₽."
}

/** #75 nudge: чекбокс выключен. */
export function promoNudgeInsteadOf(cartTotalRub) {
  const sum = Number(cartTotalRub)
  const pretty = Number.isFinite(sum) ? String(Math.round(sum)) : String(cartTotalRub ?? "")
  return `Сохрани — счёт станет 11 ₽ вместо ${pretty} ₽.`
}

export function bindingBlockedMessage() {
  return "Код не принят. Попробуй другой способ."
}

export function bindingStepUpMessage() {
  return "Нужно подтверждение. Ещё раз код с SMS."
}

export function bindingRateLimitedMessage() {
  return "Слишком часто. Следующая попытка — через 15 мин."
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
