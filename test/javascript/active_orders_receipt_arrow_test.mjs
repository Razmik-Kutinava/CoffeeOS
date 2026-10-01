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

describe("TASK_84-RECEIPT-ARROW-EXT — стрелка на кнопке «Состав заказа» [TDD]", () => {
  it("collapsed: «Состав заказа >», aria-expanded=false", async () => {
    const state = createActiveOrdersAccordionState([order])
    const cta = ctaOf(await renderSvelte(accordionPath, { order, accordionState: state }))
    assert.equal(cta.text, "Состав заказа >")
    assert.match(cta.attrs, /aria-expanded="false"/)
  })

  it("open: «Состав заказа v», aria-expanded=true", async () => {
    const state = createActiveOrdersAccordionState([order])
    openOrderReceipt(state, "o1")
    const cta = ctaOf(await renderSvelte(accordionPath, { order, accordionState: state }))
    assert.equal(cta.text, "Состав заказа v")
    assert.match(cta.attrs, /aria-expanded="true"/)
  })

  it("arrow is decorative: aria-label stays «Состав заказа», arrow span aria-hidden, not aoa__chevron (#35)", async () => {
    const state = createActiveOrdersAccordionState([order])
    const cta = ctaOf(await renderSvelte(accordionPath, { order, accordionState: state }))
    assert.match(cta.attrs, /aria-label="Состав заказа"/)
    assert.match(cta.inner, /<span[^>]*class="aoa__receipt-arrow[\s"][^>]*aria-hidden="true"/)
    assert.doesNotMatch(readFileSync(accordionPath, "utf8"), /aoa__chevron/)
  })
})
