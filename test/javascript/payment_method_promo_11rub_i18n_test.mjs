/**
 * #75 / Патч 1: promo UI strings from amount_rub (не hardcoded 11).
 * node --test test/javascript/payment_method_promo_11rub_i18n_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import {
  labelSbpBoundUsual,
  promoSaveToday,
  promoNudgeInsteadOf,
  bindingBlockedMessage,
  bindingStepUpMessage,
  bindingRateLimitedMessage
} from "../../app/frontend/lib/paymentMethodI18n.js"

describe("#75 promo / binding TOV (Патч 1 amount_rub)", () => {
  it("promo checked text uses amount_rub", () => {
    assert.equal(promoSaveToday(11), "Сохрани — счёт сегодня 11 ₽.")
    assert.equal(promoSaveToday(15), "Сохрани — счёт сегодня 15 ₽.")
  })

  it("promo nudge uses amount_rub instead of hardcoded 11", () => {
    assert.equal(
      promoNudgeInsteadOf(450, 11),
      "Сохрани — счёт станет 11 ₽ вместо 450 ₽."
    )
    assert.equal(
      promoNudgeInsteadOf(450, 15),
      "Сохрани — счёт станет 15 ₽ вместо 450 ₽."
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
