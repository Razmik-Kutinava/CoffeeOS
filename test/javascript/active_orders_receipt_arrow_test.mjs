import { describe, it } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { createActiveOrdersAccordionState } from "../../app/frontend/lib/activeOrdersAccordion.js"
import { openOrderReceipt } from "../../app/frontend/lib/orderStatusNotifyActions.js"
import { renderSvelte } from "./svelte_ssr_helper.mjs"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const accordionPath = join(root, "app/frontend/components/ActiveOrdersAccordion.svelte")
const source = readFileSync(accordionPath, "utf8")

const order = {
  id: "o1",
  status: "preparing",
  order_number: "202610-1",
  sales_point: { name: "Point A" },
  items: [{ product_id: "p1", name: "Капучино", quantity: 1, price: 280, modifiers: [], discount: 0, line_total: 280 }],
  subtotal: 280,
  discount: 0,
  total_amount: 280
}

function ctaOf(html) {
  const m = html.match(/<button([^>]*data-testid="active-order-receipt-cta"[^>]*)>([\s\S]*?)<\/button>/)
  assert.ok(m, "receipt CTA must render")
  const text = m[2].replace(/<!--[\s\S]*?-->/g, "").replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim()
  return { attrs: m[1], inner: m[2], text }
}

function cssRule(selector) {
  const escaped = selector.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
  const m = source.match(new RegExp(`(?:^|\\n)\\s*${escaped}\\s*\\{([^}]*)\\}`))
  return m ? m[1] : ""
}

async function render(state) {
  return renderSvelte(accordionPath, { order, accordionState: state })
}

describe("TASK_104 — переключатель состава заказа: только стрелка", () => {
  it("Subtask 1: закрытый чек — видна только «>», aria-expanded=false", async () => {
    const cta = ctaOf(await render(createActiveOrdersAccordionState([order])))
    assert.equal(cta.text, ">")
    assert.doesNotMatch(cta.inner, /Состав заказа/)
    assert.match(cta.attrs, /aria-expanded="false"/)
  })

  it("Subtask 2: открытый чек — видна только «v», aria-expanded=true", async () => {
    const state = createActiveOrdersAccordionState([order])
    openOrderReceipt(state, "o1")
    const cta = ctaOf(await render(state))
    assert.equal(cta.text, "v")
    assert.doesNotMatch(cta.inner, /Состав заказа/)
    assert.match(cta.attrs, /aria-expanded="true"/)
  })

  it("Subtask 3: повторное нажатие сворачивает — «>» и aria-expanded=false", async () => {
    const state = createActiveOrdersAccordionState([order])
    openOrderReceipt(state, "o1")
    openOrderReceipt(state, "o1")
    const cta = ctaOf(await render(state))
    assert.equal(cta.text, ">")
    assert.match(cta.attrs, /aria-expanded="false"/)
  })

  it("Subtask 4: доступное имя «Состав заказа», стрелка aria-hidden, button type=button", async () => {
    const cta = ctaOf(await render(createActiveOrdersAccordionState([order])))
    assert.match(cta.attrs, /aria-label="Состав заказа"/)
    assert.match(cta.attrs, /type="button"/)
    assert.match(cta.inner, /<span[^>]*class="aoa__receipt-arrow[\s"][^>]*aria-hidden="true"/)
  })

  it("Subtask 4: видимый фокус с клавиатуры", () => {
    assert.match(cssRule(".aoa__receipt-cta:focus-visible"), /outline\s*:/)
  })

  it("Subtask 1/2: без заливки, скругления и полной ширины", () => {
    const rule = cssRule(".aoa__receipt-cta")
    assert.ok(rule, ".aoa__receipt-cta rule must exist")
    assert.doesNotMatch(rule, /background\s*:\s*#ff8c42/i)
    assert.match(rule, /background\s*:\s*transparent/)
    assert.doesNotMatch(rule, /width\s*:\s*100%/)
    assert.doesNotMatch(rule, /border-radius\s*:\s*0\.5rem/)
  })

  it("положение: отдельный элемент справа под строкой статуса, не в .aoa__head (#35)", async () => {
    const rule = cssRule(".aoa__receipt-cta")
    assert.match(rule, /margin-left\s*:\s*auto/)
    const html = await render(createActiveOrdersAccordionState([order]))
    const headEnd = html.indexOf("aoa__head")
    const cta = html.indexOf('data-testid="active-order-receipt-cta"')
    const actions = html.indexOf("aoa__actions")
    assert.ok(headEnd > 0 && cta > headEnd, "CTA after head")
    assert.ok(actions < 0 || cta > actions, "CTA after action buttons (outside head)")
    assert.doesNotMatch(source, /aoa__chevron/)
  })

  it("кликабельная область не меньше 44×36 px", () => {
    const rule = cssRule(".aoa__receipt-cta")
    assert.match(rule, /min-width\s*:\s*2\.75rem/)
    assert.match(rule, /min-height\s*:\s*2\.25rem/)
  })

  it("Subtask 5: якорь fitReceiptInView — та же кнопка", () => {
    assert.match(source, /bind:this=\{receiptCtaEl\}/)
    assert.match(source, /const anchor = receiptCtaEl \|\| el/)
  })
})
