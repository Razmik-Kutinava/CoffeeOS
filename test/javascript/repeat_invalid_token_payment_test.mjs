/**
 * Repeat order invalid token — payment sheet UX (RED).
 * node --test test/javascript/repeat_invalid_token_payment_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach } from "node:test"
import {
  formatCardRowLabel,
  labelAddCard,
  labelSbp,
  ctaAddCard,
  ctaPay,
  sbpUnavailable,
  paymentMethodLoadErrorMessage
} from "../../app/frontend/lib/paymentMethodI18n.js"
import {
  getIsTokenInvalid,
  setTokenInvalid,
  clearTokenInvalid,
  persistPaymentSelection,
  loadPaymentSelection,
  shouldShowAddCardCta,
  mapPaymentErrorSurface,
  isInvalidRebillPaymentError
} from "../../app/frontend/lib/repeatInvalidTokenStore.js"

describe("paymentMethodI18n", () => {
  it("formats card row as «**** XXXX» per SBP ТЗ Шаг 10", () => {
    assert.equal(
      formatCardRowLabel({ pan: "*1594", payment_system: "VISA" }),
      "**** 1594"
    )
  })

  it("exposes add-card and pay CTA labels", () => {
    assert.equal(labelAddCard(), "Картой +")
    assert.equal(ctaAddCard(), "Добавить карту")
    assert.equal(ctaPay(), "Оплатить")
  })

  it("exposes SBP labels", () => {
    assert.equal(labelSbp(), "СБП")
    assert.match(sbpUnavailable(), /СБП.*недоступ/i)
  })

  it("load error message is non-empty for inline stub", () => {
    assert.match(paymentMethodLoadErrorMessage(), /не удалось|ошибка/i)
  })
})

describe("repeatInvalidTokenStore — invalid rebill flag", () => {
  beforeEach(() => {
    globalThis.sessionStorage = {
      _data: {},
      getItem(k) {
        return this._data[k] ?? null
      },
      setItem(k, v) {
        this._data[k] = String(v)
      },
      removeItem(k) {
        delete this._data[k]
      },
      clear() {
        this._data = {}
      }
    }
    clearTokenInvalid()
  })

  it("starts not invalid", () => {
    assert.equal(getIsTokenInvalid(), false)
  })

  it("setTokenInvalid persists for card id", () => {
    setTokenInvalid("card-1594")
    assert.equal(getIsTokenInvalid(), true)
    assert.equal(getIsTokenInvalid("card-1594"), true)
    assert.equal(getIsTokenInvalid("other"), false)
  })

  it("clearTokenInvalid resets flag", () => {
    setTokenInvalid("card-1594")
    clearTokenInvalid("card-1594")
    assert.equal(getIsTokenInvalid(), false)
  })
})

describe("repeatInvalidTokenStore — payment selection persist", () => {
  beforeEach(() => {
    globalThis.sessionStorage = {
      _data: {},
      getItem(k) {
        return this._data[k] ?? null
      },
      setItem(k, v) {
        this._data[k] = String(v)
      },
      removeItem(k) {
        delete this._data[k]
      },
      clear() {
        this._data = {}
      }
    }
    persistPaymentSelection({ selectedCardId: null, selectionMode: "saved_card" })
  })

  it("persists and restores selected card after close/open", () => {
    persistPaymentSelection({ selectedCardId: "card-1594", selectionMode: "saved_card" })
    const loaded = loadPaymentSelection()
    assert.equal(loaded.selectedCardId, "card-1594")
    assert.equal(loaded.selectionMode, "saved_card")
  })
})

describe("repeatInvalidTokenStore — peek CTA mapping", () => {
  it("shows Add card CTA when token invalid in repeat context", () => {
    assert.equal(
      shouldShowAddCardCta({
        isTokenInvalid: true,
        hasRepeatContext: true,
        cartItemCount: 1
      }),
      true
    )
  })

  it("shows checkout total CTA when token valid", () => {
    assert.equal(
      shouldShowAddCardCta({
        isTokenInvalid: false,
        hasRepeatContext: true,
        cartItemCount: 1
      }),
      false
    )
  })

  it("hides Add card CTA without repeat context", () => {
    assert.equal(
      shouldShowAddCardCta({
        isTokenInvalid: true,
        hasRepeatContext: false,
        cartItemCount: 1
      }),
      false
    )
  })
})

describe("repeatInvalidTokenStore — HTTP error surface", () => {
  it("pre-open load failure maps to toast", () => {
    assert.equal(mapPaymentErrorSurface({ httpStatus: 500, phase: "pre_open" }), "toast")
    assert.equal(mapPaymentErrorSurface({ httpStatus: 400, phase: "pre_open" }), "toast")
  })

  it("pay failure inside sheet maps to inline", () => {
    assert.equal(mapPaymentErrorSurface({ httpStatus: 500, phase: "pay" }), "inline")
    assert.equal(mapPaymentErrorSurface({ httpStatus: 400, phase: "pay" }), "inline")
  })
})

describe("repeatInvalidTokenStore — invalid rebill detection from one_click", () => {
  it("detects client/bank rebill errors", () => {
    assert.equal(isInvalidRebillPaymentError({ error_code: "1014", httpStatus: 422 }), true)
    assert.equal(isInvalidRebillPaymentError({ error_code: "1051", httpStatus: 422 }), true)
    assert.equal(isInvalidRebillPaymentError({ httpStatus: 500 }), false)
    assert.equal(isInvalidRebillPaymentError({ error_code: "0", httpStatus: 200 }), false)
  })
})

/** G7: insufficient funds / CLIENT_ERROR → открыть NewCardForm, не retry той же карты. */
describe("shopPayFsm — G7 CLIENT_ERROR CTA → open_new_card [TDD]", () => {
  it("resolvePayFsmCtaAction maps CLIENT_ERROR to open_new_card", async () => {
    const { PAY_FSM, resolvePayFsmCtaAction } = await import(
      "../../app/frontend/lib/shopPayFsm.js"
    )
    assert.equal(typeof resolvePayFsmCtaAction, "function")
    assert.equal(resolvePayFsmCtaAction(PAY_FSM.CLIENT_ERROR), "open_new_card")
  })

  it("resolvePayFsmCtaAction keeps retry for net/bank and pay for default", async () => {
    const { PAY_FSM, resolvePayFsmCtaAction } = await import(
      "../../app/frontend/lib/shopPayFsm.js"
    )
    assert.equal(resolvePayFsmCtaAction(PAY_FSM.NET_ERROR), "retry")
    assert.equal(resolvePayFsmCtaAction(PAY_FSM.BANK_ERROR), "retry")
    assert.equal(resolvePayFsmCtaAction(PAY_FSM.DEFAULT), "pay")
  })

  it("shouldAutoOpenNewCardOnClientError is true for CLIENT_ERROR (D4=C)", async () => {
    const { PAY_FSM, shouldAutoOpenNewCardOnClientError } = await import(
      "../../app/frontend/lib/shopPayFsm.js"
    )
    assert.equal(typeof shouldAutoOpenNewCardOnClientError, "function")
    assert.equal(shouldAutoOpenNewCardOnClientError(PAY_FSM.CLIENT_ERROR), true)
    assert.equal(shouldAutoOpenNewCardOnClientError(PAY_FSM.DEFAULT), false)
    assert.equal(shouldAutoOpenNewCardOnClientError(PAY_FSM.NET_ERROR), false)
  })
})
