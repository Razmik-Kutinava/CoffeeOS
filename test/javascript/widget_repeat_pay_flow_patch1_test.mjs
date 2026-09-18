/**
 * Патч 1 (2026-09-17): статусы в кнопке · 1051 · ERROR/timeout → IDLE.
 *
 * node --test test/javascript/widget_repeat_pay_flow_patch1_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

import {
  INLINE_GENERIC_ERROR_LABEL,
  INLINE_INSUFFICIENT_FUNDS_LABEL,
  INLINE_ROTATION_LABELS,
  INLINE_TIMEOUT_LABEL,
  TBANK_INLINE_ERROR_RESET_MS,
  mapTbankInlineError,
  classifyInlinePayErrorLabel
} from "../../app/frontend/lib/shopInlinePayFsm.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")

describe("Патч 1 — Subtask 10/12 labels", () => {
  it("rotation cycle matches patch v1 copy", () => {
    assert.deepEqual(INLINE_ROTATION_LABELS, [
      "Ещё чуть-чуть...",
      "Связываемся с банком...",
      "Платеж принимается от банка..."
    ])
  })

  it("1051 → «Недостаточно средств»; прочие REJECTED → «Ошибка оплаты»", () => {
    assert.equal(INLINE_INSUFFICIENT_FUNDS_LABEL, "Недостаточно средств")
    assert.equal(INLINE_GENERIC_ERROR_LABEL, "Ошибка оплаты")
    assert.equal(mapTbankInlineError({ error_code: "1051" }), "Недостаточно средств")
    assert.equal(mapTbankInlineError({ error_code: "1054" }), "Ошибка оплаты")
    assert.equal(mapTbankInlineError({ error_code: "9999" }), "Ошибка оплаты")
    assert.equal(classifyInlinePayErrorLabel({ error_code: "1051" }), "Недостаточно средств")
    assert.equal(classifyInlinePayErrorLabel({ error_code: "1014" }), "Ошибка оплаты")
  })

  it("timeout label remains customer copy", () => {
    assert.equal(INLINE_TIMEOUT_LABEL, "Время ожидания истекло")
    assert.equal(TBANK_INLINE_ERROR_RESET_MS, 3000)
  })
})

describe("Патч 1 — Subtask 8/10 UI: status inside shop-repeat-card-pay", () => {
  it("RepeatSection binds pay button label to statusText when active", () => {
    const src = readFileSync(join(root, "app/frontend/components/RepeatSection.svelte"), "utf8")
    assert.match(src, /data-testid="shop-repeat-card-pay"/)
    // статус внутри кнопки, не только в InlinePayFallback
    assert.match(
      src,
      /data-testid="shop-repeat-card-pay"[\s\S]{0,800}?payUi\.statusText|cardPayLabel|inlinePayButtonLabel/
    )
    assert.match(src, /Ещё чуть-чуть|INLINE_ROTATION_LABELS|statusText/)
  })

  it("InlinePayFallback can hide status bar when host button owns it", () => {
    const src = readFileSync(
      join(root, "app/frontend/components/InlinePayFallback.svelte"),
      "utf8"
    )
    assert.match(src, /statusInHostButton|hideStatusBar/)
  })
})

describe("Патч 1 — Subtask 12/13 flow: ERROR/timeout → resetAfterMs", () => {
  it("widgetRepeatPayFlow sets resetAfterMs on timeout and rejected paths", () => {
    const src = readFileSync(join(root, "app/frontend/lib/widgetRepeatPayFlow.js"), "utf8")
    assert.match(
      src,
      /kind === ["']timeout["'][\s\S]{0,500}?resetAfterMs\s*=\s*TBANK_INLINE_ERROR_RESET_MS/
    )
    assert.match(
      src,
      /REJECTED|rejected|CANCELED|canceled[\s\S]{0,800}?resetAfterMs\s*=\s*TBANK_INLINE_ERROR_RESET_MS/
    )
    assert.match(
      src,
      /timeout[\s\S]{0,400}?INLINE_TIMEOUT_LABEL|errorLabel/
    )
  })
})
