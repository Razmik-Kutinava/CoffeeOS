/**
 * #33 F1–F2 + UX 2026-08-13: отказ → СБП/карта+ на экране;
 * «карта +» → openPaymentSheet (PaymentMethodsSheet), не expand в peek.
 *
 * node --test test/javascript/widget_repeat_pay_flow_fallback_ui_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import {
  resolveCardDeclineFallbackUi,
  resolveCardPlusExpandedUi
} from "../../app/frontend/lib/widgetRepeatPayFlow.js"

describe("#33 F1 — card decline → fallback methods only (no expanded)", () => {
  it("resolveCardDeclineFallbackUi shows СБП/карта+ without expanded cards/form", () => {
    const ui = resolveCardDeclineFallbackUi()
    assert.equal(ui.showFallbackMethods, true)
    assert.equal(ui.showExpandedCards, false)
    assert.equal(ui.showNewCardForm, false)
  })
})

describe("#33 F2 / UX — tap «карта +» → PaymentMethodsSheet flag (not peek expand)", () => {
  it("resolveCardPlusExpandedUi opens payment sheet without peek form", () => {
    const ui = resolveCardPlusExpandedUi()
    assert.equal(ui.showFallbackMethods, true)
    assert.equal(ui.showExpandedCards, false)
    assert.equal(ui.showNewCardForm, false)
    assert.equal(ui.openPaymentSheet, true)
  })
})
