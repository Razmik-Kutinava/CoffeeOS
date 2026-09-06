/**
 * Понятные сообщения при ошибке оплаты (карта / сеть + Повторить).
 *
 * node --test test/javascript/payment_error_user_messages_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  INLINE_CARD_ERROR_LABEL,
  INLINE_NETWORK_ERROR_LABEL,
  mapTbankInlineError,
  classifyInlinePayErrorLabel
} from "../../app/frontend/lib/shopInlinePayFsm.js"
import {
  PAY_FSM,
  PAY_FSM_LABELS,
  fsmFromPaymentError,
  resolveCheckoutSheetInlineError
} from "../../app/frontend/lib/shopPayFsm.js"
import { resolveNetworkRetryUi } from "../../app/frontend/lib/widgetRepeatPayFlow.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")

const CARD_MSG =
  "Недостаточно средств, или карта заблокирована банком, или истёк срок действия карты"
const NET_MSG = "Нет связи. Повторить"

describe("payment error user messages — labels [TDD]", () => {
  it("exports exact customer card and network texts", () => {
    assert.equal(INLINE_CARD_ERROR_LABEL, CARD_MSG)
    assert.equal(INLINE_NETWORK_ERROR_LABEL, NET_MSG)
  })

  it("maps card ErrorCodes (1051/1054/1014) to card message", () => {
    assert.equal(mapTbankInlineError({ error_code: "1051" }), CARD_MSG)
    assert.equal(mapTbankInlineError({ error_code: "1054" }), CARD_MSG)
    assert.equal(mapTbankInlineError({ error_code: "1014" }), CARD_MSG)
  })

  it("keeps generic label for unknown bank code (no technical codes in UI)", () => {
    assert.equal(
      mapTbankInlineError({ error_code: "9999" }),
      "Ошибка оплаты, попробуйте снова"
    )
    assert.ok(!/\d{3,}/.test(mapTbankInlineError({ error_code: "9999" })))
  })

  it("classifyInlinePayErrorLabel: offline/timeout → network; card code → card", () => {
    const netErr = new Error("Failed to fetch")
    assert.equal(classifyInlinePayErrorLabel({ error: netErr }), NET_MSG)
    assert.equal(classifyInlinePayErrorLabel({ kind: "timeout" }), NET_MSG)
    assert.equal(classifyInlinePayErrorLabel({ error_code: "1051" }), CARD_MSG)
  })
})

describe("payment error user messages — checkout FSM labels [TDD]", () => {
  it("CLIENT_ERROR / NET_ERROR labels match customer copy", () => {
    assert.equal(PAY_FSM_LABELS[PAY_FSM.CLIENT_ERROR], CARD_MSG)
    assert.equal(PAY_FSM_LABELS[PAY_FSM.NET_ERROR], NET_MSG)
  })

  it("fsmFromPaymentError still routes card vs network (logic reuse)", () => {
    assert.equal(fsmFromPaymentError({ error_code: "1051" }), PAY_FSM.CLIENT_ERROR)
    assert.equal(fsmFromPaymentError(new Error("Failed to fetch")), PAY_FSM.NET_ERROR)
  })
})

describe("payment error user messages — network retry UI [TDD]", () => {
  it("resolveNetworkRetryUi shows retry CTA without duplicating sheet error", () => {
    const ui = resolveNetworkRetryUi()
    assert.equal(ui.showRetry, true)
    assert.equal(ui.showFallbackMethods, false)
    assert.equal(ui.showExpandedCards, false)
    assert.equal(ui.showNewCardForm, false)
    assert.equal(ui.openPaymentSheet, false)
  })
})

describe("payment error user messages — sheet inline on pay decline [TDD #26 step5]", () => {
  it("resolveCheckoutSheetInlineError returns friendly labels for NET/CLIENT/BANK", () => {
    const raw = new Error("Failed to fetch")
    assert.equal(resolveCheckoutSheetInlineError(raw, PAY_FSM.NET_ERROR), NET_MSG)
    assert.equal(resolveCheckoutSheetInlineError(raw, PAY_FSM.CLIENT_ERROR), CARD_MSG)
    assert.equal(
      resolveCheckoutSheetInlineError(raw, PAY_FSM.BANK_ERROR),
      PAY_FSM_LABELS[PAY_FSM.BANK_ERROR]
    )
    assert.ok(!/Failed to fetch/i.test(resolveCheckoutSheetInlineError(raw, PAY_FSM.NET_ERROR)))
  })

  it("Checkout catch must not assign e.message into sheetInlineError on pay", () => {
    const src = readFileSync(join(root, "app/frontend/routes/Checkout.svelte"), "utf8")
    assert.match(src, /resolveCheckoutSheetInlineError/)
    assert.ok(
      !/sheetInlineError\s*=\s*e\.message/.test(src),
      "сырой e.message в sheetInlineError запрещён (Failed to fetch)"
    )
    assert.ok(
      !/sheetInlineError\s*=\s*chargeErr\.message/.test(src),
      "сырой chargeErr.message в sheetInlineError запрещён"
    )
  })
})
