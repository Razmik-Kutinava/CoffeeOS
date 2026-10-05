/**
 * TASK_101: строка «Итого» в шторке способов оплаты (серверный total корзины).
 * node --test test/javascript/payment_methods_order_total_test.mjs
 */
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { describe, it } from "node:test"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"
import * as i18n from "../../app/frontend/lib/paymentMethodI18n.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const sheet = readFileSync(join(root, "app/frontend/components/PaymentMethodsSheet.svelte"), "utf8")
const NBSP = "\u00A0"

describe("TASK_101 formatRubAmount / labelOrderTotal [TDD]", () => {
  it("labelOrderTotal → Итого", () => {
    assert.equal(typeof i18n.labelOrderTotal, "function")
    assert.equal(i18n.labelOrderTotal(), "Итого")
  })

  it("Subtask 5: 3245 → «3 245 ₽» (пробел тысяч + знак ₽)", () => {
    assert.equal(typeof i18n.formatRubAmount, "function")
    const out = i18n.formatRubAmount(3245)
    assert.equal(out, `3${NBSP}245${NBSP}₽`)
    assert.match(out, /^3\s245\s₽$/)
  })

  it("крупные и мелкие суммы, строка из API", () => {
    assert.equal(i18n.formatRubAmount(1000000), `1${NBSP}000${NBSP}000${NBSP}₽`)
    assert.equal(i18n.formatRubAmount(759), `759${NBSP}₽`)
    assert.equal(i18n.formatRubAmount("759.0"), `759${NBSP}₽`)
  })

  it("Subtask 10: 0 / NaN / пусто / отрицательное → пустая строка (без «0 ₽»)", () => {
    for (const v of [0, null, undefined, "", "abc", Number.NaN, -5]) {
      assert.equal(i18n.formatRubAmount(v), "", `value=${String(v)}`)
    }
  })
})

describe("TASK_101 PaymentMethodsSheet: строка Итого [TDD]", () => {
  const rowAt = sheet.indexOf('data-testid="payment-methods-order-total"')
  const headerEnd = sheet.indexOf("</header>")
  const loadingAt = sheet.indexOf("{#if loading}")
  const listAt = sheet.indexOf('class="pm-sheet__list"')
  const inlineErrorAt = sheet.indexOf("{#if inlineError}")

  it("Subtask 4/6: строка есть, после header и до веток loading / списка способов", () => {
    assert.ok(rowAt > 0, "нет data-testid=payment-methods-order-total")
    assert.ok(rowAt > headerEnd, "строка должна быть под заголовком шторки")
    assert.ok(rowAt < loadingAt, "строка не должна зависеть от loading/loadError (над первым способом в любом случае)")
    assert.ok(rowAt < listAt, "строка выше первой карты / СБП / «Картой +»")
  })

  it("Subtask 8: строка вне блока ошибки оплаты (остаётся на месте в error state)", () => {
    assert.ok(rowAt < inlineErrorAt, "Итого выше inline-ошибки и не внутри неё")
  })

  it("Subtask 4/5: подпись и сумма через i18n, сумма — серверный cartTotalRub", () => {
    assert.match(sheet, /labelOrderTotal\(\)/)
    assert.match(sheet, /formatRubAmount\(cartTotalRub\)/)
  })

  it("Subtask 10: guard — строка только при валидной сумме", () => {
    assert.match(sheet, /\{#if\s+orderTotalLabel\}/)
    assert.match(sheet, /const orderTotalLabel = \$derived\(formatRubAmount\(cartTotalRub\)\)/)
  })

  it("DoD 3: клиент не считает price × qty в шторке", () => {
    assert.doesNotMatch(sheet, /price\s*\*\s*(qty|quantity)/)
    assert.doesNotMatch(sheet, /line_total/)
  })

  it("Subtask 11: сумма не переносится и выровнена вправо", () => {
    assert.match(sheet, /\.pm-sheet__total\s*\{[^}]*justify-content:\s*space-between/)
    assert.match(sheet, /\.pm-sheet__total-amount\s*\{[^}]*white-space:\s*nowrap/)
  })
})
