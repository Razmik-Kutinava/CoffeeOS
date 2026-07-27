/**
 * Шаг 10 — маска карты **** 1234 (SBP epic polish).
 * node --test test/javascript/shop_card_mask_step10_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { formatCardRowLabel, formatMaskedPan } from "../../app/frontend/lib/paymentMethodI18n.js"
import { panFromCard } from "../../app/frontend/lib/paymentMethodLabels.js"

describe("card mask Step 10 — **** 1234", () => {
  it("formatMaskedPan uses **** last4", () => {
    assert.equal(formatMaskedPan({ pan: "*1594" }), "**** 1594")
    assert.equal(formatMaskedPan({ masked_pan: "430000******1234" }), "**** 1234")
    assert.equal(formatMaskedPan({ pan: "**** 8339" }), "**** 8339")
  })

  it("formatCardRowLabel shows **** 1234 for sheet (ТЗ Шаг 10)", () => {
    assert.equal(
      formatCardRowLabel({ pan: "*1594", payment_system: "VISA" }),
      "**** 1594"
    )
  })

  it("panFromCard keeps compact *XXXX for legacy labels", () => {
    assert.equal(panFromCard({ pan: "*5953" }), "*5953")
  })
})
