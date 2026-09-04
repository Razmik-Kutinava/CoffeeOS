/**
 * #75 promo 11₽ UI strings (PaymentMethodsSheet / paymentMethodI18n).
 * node --test test/javascript/payment_method_promo_11rub_i18n_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import {
  labelSbpBoundUsual,
  promoSaveToday11,
  promoNudgeInsteadOf,
  bindingBlockedMessage,
  bindingStepUpMessage,
  bindingRateLimitedMessage
} from "../../app/frontend/lib/paymentMethodI18n.js"

describe("#75 promo / binding TOV", () => {
  it("promo checked text", () => {
    assert.equal(promoSaveToday11(), "Сохрани — счёт сегодня 11 ₽.")
  })

  it("promo nudge when checkbox off", () => {
    assert.equal(
      promoNudgeInsteadOf(450),
      "Сохрани — счёт станет 11 ₽ вместо 450 ₽."
    )
  })

  it("blocked / step-up / rate-limit messages", () => {
    assert.equal(bindingBlockedMessage(), "Код не принят. Попробуй другой способ.")
    assert.equal(bindingStepUpMessage(), "Нужно подтверждение. Ещё раз код с SMS.")
    assert.equal(
      bindingRateLimitedMessage(),
      "Слишком часто. Следующая попытка — через 15 мин."
    )
  })

  it("saved SBP TOV without last4", () => {
    assert.equal(labelSbpBoundUsual(), "СБП · как обычно")
  })
})
