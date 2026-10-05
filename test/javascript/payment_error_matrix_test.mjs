/**
 * TASK_100 — Матрица сообщений ошибки оплаты + отдельный CTA.
 *
 * node --test test/javascript/payment_error_matrix_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  PAY_FSM,
  PAY_ERROR_CATEGORY,
  classifyPaymentError,
  resolvePaymentErrorUi,
  resolveCheckoutSheetInlineError,
  shouldAutoOpenNewCardOnClientError
} from "../../app/frontend/lib/shopPayFsm.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const read = (p) => readFileSync(join(root, p), "utf8")

const C = PAY_ERROR_CATEGORY
const OLD_MSG = "Недостаточно средств, или карта заблокирована банком, или истёк срок действия карты"
const CARD_MSG = "Не удалось списать деньги. Обратитесь в банк — этой картой нельзя оплатить заказ."
const GENERAL_MSG = "Не удалось выполнить оплату. Попробуйте ещё раз"

const bankErr = (code, message = "") => {
  const e = new Error(message)
  e.error_code = code
  return e
}

describe("TASK_100 classifyPaymentError [TDD]", () => {
  it("1051 → insufficient_funds", () => {
    assert.equal(classifyPaymentError(bankErr("1051")), C.INSUFFICIENT_FUNDS)
  })

  it("1014 → card_expired (не insufficient_funds)", () => {
    assert.equal(classifyPaymentError(bankErr("1014")), C.CARD_EXPIRED)
  })

  it("119 / 2200 → too_many_attempts (не card_declined)", () => {
    assert.equal(classifyPaymentError(bankErr("119")), C.TOO_MANY_ATTEMPTS)
    assert.equal(classifyPaymentError(bankErr("2200")), C.TOO_MANY_ATTEMPTS)
  })

  it("остальные подтверждённые карточные коды → card_declined", () => {
    for (const code of ["1005", "1013", "1041", "1053", "1054", "1057", "1061", "1062", "1078"]) {
      assert.equal(classifyPaymentError(bankErr(code)), C.CARD_DECLINED, code)
    }
  })

  it("без кода, но backend message про карту → card_declined", () => {
    assert.equal(classifyPaymentError(new Error("Карта заблокирована")), C.CARD_DECLINED)
  })

  it("неизвестный код без карточной семантики → payment_failed (не карта)", () => {
    assert.equal(classifyPaymentError(bankErr("9999", "Bad request")), C.PAYMENT_FAILED)
  })

  it("3DS прерван → payment_failed", () => {
    const e = new Error("three_ds_abort")
    e.kind = "three_ds_abort"
    assert.equal(classifyPaymentError(e), C.PAYMENT_FAILED)
  })

  it("сеть и 5xx — вне Матрицы (null)", () => {
    assert.equal(classifyPaymentError(new Error("Failed to fetch")), null)
    assert.equal(classifyPaymentError(bankErr("", "x"), { httpStatus: 502 }), null)
  })
})

describe("TASK_100 resolvePaymentErrorUi — Матрица [TDD]", () => {
  const rows = [
    [C.INSUFFICIENT_FUNDS, "Недостаточно средств на карте", "Изменить карту", "change_card"],
    [C.CARD_EXPIRED, "Срок действия карты истёк", "Изменить карту", "change_card"],
    [C.TOO_MANY_ATTEMPTS, "Слишком много попыток оплаты. Попробуйте позже", "Попробовать позже", "close"],
    [C.CARD_DECLINED, CARD_MSG, "Изменить карту", "change_card"],
    [C.PAYMENT_FAILED, GENERAL_MSG, "Повторить оплату", "retry"]
  ]
  for (const [cat, message, label, action] of rows) {
    it(`${cat} → «${message}» + CTA «${label}»`, () => {
      const ui = resolvePaymentErrorUi(cat)
      assert.equal(ui.message, message)
      assert.deepEqual(ui.cta, { label, action })
      assert.ok(!ui.message.includes(label), "CTA не склеен с текстом ошибки")
    })
  }

  it("null-категория → null (NET/BANK как раньше)", () => {
    assert.equal(resolvePaymentErrorUi(null), null)
  })

  it("карточный fallback не утверждает блокировку карты", () => {
    assert.ok(!/заблокирован/i.test(resolvePaymentErrorUi(C.CARD_DECLINED).message))
  })
})

describe("TASK_100 inline-сообщение шторки [TDD]", () => {
  it("1051 в шторке — новый текст, не старый общий", () => {
    const msg = resolveCheckoutSheetInlineError(bankErr("1051"), PAY_FSM.CLIENT_ERROR)
    assert.equal(msg, "Недостаточно средств на карте")
    assert.notEqual(msg, OLD_MSG)
  })

  it("явная категория 3DS abort → общий fallback", () => {
    assert.equal(
      resolveCheckoutSheetInlineError(null, PAY_FSM.CLIENT_ERROR, C.PAYMENT_FAILED),
      GENERAL_MSG
    )
  })

  it("состояние NET_ERROR — всегда «Нет связи», даже с неизвестным кодом (решение владельца)", () => {
    const e = bankErr("NETWORK", "Ошибка соединения")
    assert.equal(resolveCheckoutSheetInlineError(e, PAY_FSM.NET_ERROR), "Нет связи. Повторить")
  })

  it("ошибка не открывает форму новой карты автоматически", () => {
    assert.equal(shouldAutoOpenNewCardOnClientError(PAY_FSM.CLIENT_ERROR), false)
  })
})

describe("TASK_100 message и CTA — отдельные UI-элементы [TDD]", () => {
  it("CheckoutPayButton берёт подпись/действие из errorCta (change_card / close / retry)", () => {
    const src = read("app/frontend/components/CheckoutPayButton.svelte")
    assert.match(src, /errorCta/)
    assert.match(src, /"close"/)
    assert.match(src, /onClose/)
  })

  it("PaymentMethodsSheet: alert с inlineError + errorCta в кнопку", () => {
    const src = read("app/frontend/components/PaymentMethodsSheet.svelte")
    assert.match(src, /data-testid="payment-method-inline-error"/)
    assert.match(src, /\{errorCta\}|errorCta=\{errorCta\}/)
  })

  it("«Попробовать позже» закрывает шторку и сбрасывает ошибку (повторное открытие — чистая кнопка)", () => {
    const sheet = read("app/frontend/components/PaymentMethodsSheet.svelte")
    assert.match(sheet, /onTryLater/)
    const src = read("app/frontend/routes/Checkout.svelte")
    const m = src.match(/function onPayErrorTryLater\(\)\s*\{([\s\S]*?)\n  \}/)
    assert.ok(m, "onPayErrorTryLater в Checkout")
    assert.match(m[1], /payFsmState\s*=\s*PAY_FSM\.DEFAULT/)
    assert.match(m[1], /payErrorCategory\s*=\s*null/)
    assert.match(m[1], /closePaymentSheet\(\)/)
    assert.match(src, /onTryLater=\{onPayErrorTryLater\}/)
  })

  it("Checkout классифицирует ошибку и передаёт errorCta в шторку", () => {
    const src = read("app/frontend/routes/Checkout.svelte")
    assert.match(src, /classifyPaymentError/)
    assert.match(src, /errorCta=/)
  })
})
