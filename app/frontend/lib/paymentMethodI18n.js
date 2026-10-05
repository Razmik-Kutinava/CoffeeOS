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

/** #79: срок возврата после автоплатежа / отмены. */
export function labelSbpRefundTiming() {
  return "Возврат при отмене — 1–3 рабочих дня"
}

/** #75 TOV сохранённого СБП без last4. */
export function labelSbpBoundUsual() {
  return "СБП · как обычно"
}

/** Чекбокс привязки счёта при первой оплате СБП. */
export function labelBindSbpAccount() {
  return "Привязать счет для покупок в один клик"
}

/** #75 / Патч 1: промо — сумма из amount_rub (не hardcoded 11). */
export function promoSaveToday(amountRub) {
  const amount = formatPromoAmountRub(amountRub)
  return `Сохрани — счёт сегодня ${amount} ₽.`
}

/** @deprecated имя — alias promoSaveToday(11) для старых импортов */
export function promoSaveToday11(amountRub = 11) {
  return promoSaveToday(amountRub)
}

/** #75 / Патч 1 nudge: чекбокс выключен. */
export function promoNudgeInsteadOf(cartTotalRub, amountRub = 11) {
  const sum = Number(cartTotalRub)
  const pretty = Number.isFinite(sum) ? String(Math.round(sum)) : String(cartTotalRub ?? "")
  const amount = formatPromoAmountRub(amountRub)
  return `Сохрани — счёт станет ${amount} ₽ вместо ${pretty} ₽.`
}

/** TASK_101: подпись строки суммы заказа в шторке способов оплаты. */
export function labelOrderTotal() {
  return "Итого"
}

/** TASK_101: 3245 → «3 245 ₽» (NBSP — сумма не переносится). Невалидная / ≤ 0 → "" (строку не показываем). */
export function formatRubAmount(value) {
  if (value === null || value === undefined || value === "") return ""
  const n = Math.round(Number(value))
  if (!Number.isFinite(n) || n <= 0) return ""
  const digits = String(n).replace(/\B(?=(\d{3})+(?!\d))/g, "\u00A0")
  return `${digits}\u00A0₽`
}

function formatPromoAmountRub(amountRub) {
  const n = Number(amountRub)
  if (Number.isFinite(n)) return String(Math.round(n))
  return String(amountRub ?? 11)
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

/** TASK_100 Матрица: тексты ошибки оплаты — ключи по категориям, не по error_code. */
export function payErrorInsufficientFunds() {
  return "Недостаточно средств на карте"
}

export function payErrorCardExpired() {
  return "Срок действия карты истёк"
}

export function payErrorTooManyAttempts() {
  return "Слишком много попыток оплаты. Попробуйте позже"
}

export function payErrorCardDeclined() {
  return "Не удалось списать деньги. Обратитесь в банк — этой картой нельзя оплатить заказ."
}

export function payErrorPaymentFailed() {
  return "Не удалось выполнить оплату. Попробуйте ещё раз"
}

export function ctaChangeCard() {
  return "Изменить карту"
}

export function ctaTryLater() {
  return "Попробовать позже"
}

export function ctaRetryPayment() {
  return "Повторить оплату"
}
