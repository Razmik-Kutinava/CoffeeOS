/**
 * #36 Active orders accordion + text receipt — RED [TDD].
 * #84 restore receipt in status sheet (reverse #35 QA no-receipt).
 *
 * node --test test/javascript/active_orders_accordion_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  RECEIPT_SCROLL,
  CHEVRON,
  createActiveOrdersAccordionState,
  toggleExpandedOrder,
  accordionRowView,
  receiptView,
  receiptPanelView,
  fitReceiptInView,
  statusMetaThird
} from "../../app/frontend/lib/activeOrdersAccordion.js"
import { openOrderReceipt } from "../../app/frontend/lib/orderStatusNotifyActions.js"
import { renderSvelte } from "./svelte_ssr_helper.mjs"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const accordionComponentPath = join(
  root,
  "app/frontend/components/ActiveOrdersAccordion.svelte"
)

const sampleOrders = [
  {
    id: "o1",
    status: "preparing",
    order_number: "202607-1",
    created_at: "2026-07-31T12:00:00Z",
    sales_point: { name: "Point A", address: "Lenina 1", city: "Kazan" },
    items: [
      {
        product_id: "p1",
        name: "Капучино",
        quantity: 1,
        price: 280,
        modifiers: [{ name: "Сироп ваниль", price: 30 }],
        discount: 0,
        line_total: 280
      }
    ],
    subtotal: 280,
    discount: 30,
    total_amount: 250
  },
  {
    id: "o2",
    status: "accepted",
    order_number: "202607-2",
    sales_point: { name: "Point A" },
    items: [
      {
        product_id: "p2",
        name: "Эспрессо",
        quantity: 2,
        price: 150,
        modifiers: [],
        discount: 0,
        line_total: 300
      }
    ],
    subtotal: 300,
    discount: 0,
    total_amount: 300
  }
]

describe("activeOrdersAccordion — scroll + chevron (#36 B1/B3)", () => {
  it("receipt scroll is max-height 350px overflow-y auto", () => {
    assert.equal(RECEIPT_SCROLL.maxHeightPx, 350)
    assert.equal(RECEIPT_SCROLL.overflowY, "auto")
  })

  it("chevron collapsed > and expanded v", () => {
    assert.equal(CHEVRON.collapsed, ">")
    assert.equal(CHEVRON.expanded, "v")
  })
})

describe("createActiveOrdersAccordionState + toggle (#36 B1/B2)", () => {
  it("starts with no expanded order", () => {
    const state = createActiveOrdersAccordionState(sampleOrders)
    assert.equal(state.activeExpandedOrderId, null)
    assert.equal(state.orders.length, 2)
  })

  it("toggle expands one order", () => {
    const state = createActiveOrdersAccordionState(sampleOrders)
    toggleExpandedOrder(state, "o1")
    assert.equal(state.activeExpandedOrderId, "o1")
  })

  it("opening second order closes the first (only one expanded)", () => {
    const state = createActiveOrdersAccordionState(sampleOrders)
    toggleExpandedOrder(state, "o1")
    toggleExpandedOrder(state, "o2")
    assert.equal(state.activeExpandedOrderId, "o2")
  })

  it("toggle same id collapses", () => {
    const state = createActiveOrdersAccordionState(sampleOrders)
    toggleExpandedOrder(state, "o1")
    toggleExpandedOrder(state, "o1")
    assert.equal(state.activeExpandedOrderId, null)
  })
})

describe("accordionRowView (#36 B1)", () => {
  it("row shows progress steps, order number, sales point, chevron", () => {
    const state = createActiveOrdersAccordionState(sampleOrders)
    toggleExpandedOrder(state, "o1")
    const row = accordionRowView(sampleOrders[0], state.activeExpandedOrderId)
    assert.equal(row.orderNumber, "202607-1")
    assert.equal(row.salesPointName, "Point A")
    assert.equal(row.expanded, true)
    assert.equal(row.chevron, "v")
    assert.ok(Array.isArray(row.steps))
    assert.equal(row.steps.length, 4)
    assert.equal(row.steps[0].label, "Принят")
    assert.equal(row.steps[3].label, "Готов")
  })

  it("collapsed row uses > chevron", () => {
    const row = accordionRowView(sampleOrders[1], "o1")
    assert.equal(row.expanded, false)
    assert.equal(row.chevron, ">")
  })
})

describe("statusMetaThird (#35 D2 screen 06)", () => {
  it("cart_expanded third segment is first product name only", () => {
    assert.equal(statusMetaThird(sampleOrders[0], "cart_expanded"), "Капучино")
  })

  it("peek third segment stays sales point (screen 01)", () => {
    assert.equal(statusMetaThird(sampleOrders[0], "peek"), "Point A")
  })

  it("cart_expanded with empty items omits product (no silent sales-point fallback)", () => {
    assert.equal(
      statusMetaThird({ sales_point: { name: "Point A" }, items: [] }, "cart_expanded"),
      ""
    )
  })

  it("accordionRowView exposes metaThird for cart_expanded context", () => {
    const row = accordionRowView(sampleOrders[0], null, {
      sheetContext: "cart_expanded"
    })
    assert.equal(row.metaThird, "Капучино")
    assert.equal(row.salesPointName, "Point A")
  })

  it("accordionRowView peek metaThird is sales point", () => {
    const row = accordionRowView(sampleOrders[0], null, { sheetContext: "peek" })
    assert.equal(row.metaThird, "Point A")
  })
})

describe("receiptView — text only (#36 B4/B5)", () => {
  it("maps line fields name → modifiers → qty → price → discount → line_total", () => {
    const receipt = receiptView(sampleOrders[0])
    assert.equal(receipt.lines.length, 1)
    const line = receipt.lines[0]
    assert.equal(line.name, "Капучино")
    assert.deepEqual(line.modifiers, [{ name: "Сироп ваниль", price: 30 }])
    assert.equal(line.quantity, 1)
    assert.equal(line.price, 280)
    assert.equal(line.discount, 0)
    assert.equal(line.lineTotal, 280)
  })

  it("footer shows subtotal discount total_amount", () => {
    const receipt = receiptView(sampleOrders[0])
    assert.equal(receipt.subtotal, 280)
    assert.equal(receipt.discount, 30)
    assert.equal(receipt.totalAmount, 250)
  })

  it("receipt has no action buttons / interactive flags", () => {
    const receipt = receiptView(sampleOrders[0])
    assert.equal(receipt.hasActionButtons, false)
    assert.equal(receipt.interactive, false)
    assert.ok(!("buttons" in receipt) || !receipt.buttons?.length)
  })

  it("empty items and zero discount are valid", () => {
    const receipt = receiptView({
      id: "empty",
      items: [],
      subtotal: 0,
      discount: 0,
      total_amount: 0
    })
    assert.deepEqual(receipt.lines, [])
    assert.equal(receipt.discount, 0)
    assert.equal(receipt.totalAmount, 0)
  })

  it("item without modifiers yields empty modifiers on line", () => {
    const receipt = receiptView(sampleOrders[1])
    assert.deepEqual(receipt.lines[0].modifiers, [])
  })
})

describe("#84 restore receipt in status sheet", () => {
  it("ActiveOrdersAccordion renders receipt via receiptPanelView → receiptView", () => {
    const src = readFileSync(accordionComponentPath, "utf8")
    assert.match(
      src,
      /receiptPanelView\s*\(/,
      "status sheet row must call receiptPanelView (wraps receiptView)"
    )
    assert.match(
      src,
      /aoa__receipt|data-testid=["']active-order-receipt["']/,
      "status model must show order composition block"
    )
    const libSrc = readFileSync(
      join(root, "app/frontend/lib/activeOrdersAccordion.js"),
      "utf8"
    )
    assert.match(
      libSrc,
      /receiptPanelView[\s\S]*receiptView\s*\(/,
      "receiptPanelView must call existing receiptView"
    )
  })

  it("CTA Состав заказа wires openOrderReceipt", () => {
    const src = readFileSync(accordionComponentPath, "utf8")
    assert.match(src, /openOrderReceipt/, "must call openOrderReceipt")
    assert.match(
      src,
      /Состав заказа|secondaryLabel|LABELS\.receipt/,
      "must expose CTA label Состав заказа"
    )
  })

  it("dismiss button aria-label is Скрыть (not cancel)", () => {
    const src = readFileSync(accordionComponentPath, "utf8")
    assert.match(
      src,
      /aria-label=["']Скрыть[^"']*["']/,
      "X must read as hide/dismiss, not close/cancel order"
    )
  })
})

describe("#92 WebPush recovery after denied", () => {
  it("recovery panel with open-settings and watch-readiness CTAs", () => {
    const src = readFileSync(accordionComponentPath, "utf8")
    assert.match(src, /data-testid=["']active-order-push-recovery["']/)
    assert.match(src, /data-testid=["']active-order-open-settings["']/)
    assert.match(src, /data-testid=["']active-order-watch-readiness["']/)
  })
})

describe("TASK_84-RECEIPT-DISPLAY-EXT runtime receipt [TDD]", () => {
  it("CTA expand → panel text has item name + Total Amount (not source-only)", () => {
    const state = createActiveOrdersAccordionState(sampleOrders)
    openOrderReceipt(state, "o1")
    const panel = receiptPanelView(sampleOrders[0], state.activeExpandedOrderId)
    assert.equal(panel.show, true)
    assert.equal(panel.className, "aoa__receipt")
    assert.equal(panel.testId, "active-order-receipt")
    assert.match(panel.text, /Капучино/)
    assert.match(panel.text, /Сироп ваниль/)
    assert.match(panel.text, /×1 · 280₽/)
    assert.match(panel.text, /Subtotal:\s*280₽/)
    assert.match(panel.text, /Discount:\s*30₽/)
    assert.match(panel.text, /Total Amount:\s*250₽/)
    assert.equal(panel.scroll.maxHeight, "350px")
    assert.equal(panel.scroll.overflowY, "auto")
    assert.equal(panel.receipt?.hasActionButtons, false)
  })

  it("toggle collapse clears receipt panel", () => {
    const state = createActiveOrdersAccordionState(sampleOrders)
    openOrderReceipt(state, "o1")
    openOrderReceipt(state, "o1")
    const panel = receiptPanelView(sampleOrders[0], state.activeExpandedOrderId)
    assert.equal(state.activeExpandedOrderId, null)
    assert.equal(panel.show, false)
    assert.equal(panel.text, "")
  })

  it("only one expanded receipt at a time", () => {
    const state = createActiveOrdersAccordionState(sampleOrders)
    openOrderReceipt(state, "o1")
    openOrderReceipt(state, "o2")
    assert.equal(receiptPanelView(sampleOrders[0], state.activeExpandedOrderId).show, false)
    const second = receiptPanelView(sampleOrders[1], state.activeExpandedOrderId)
    assert.equal(second.show, true)
    assert.match(second.text, /Эспрессо/)
    assert.match(second.text, /Total Amount:\s*300₽/)
  })

  it("empty items still shows totals without throwing", () => {
    const empty = {
      id: "empty",
      status: "preparing",
      items: [],
      subtotal: 0,
      discount: 0,
      total_amount: 0
    }
    const state = createActiveOrdersAccordionState([empty])
    openOrderReceipt(state, "empty")
    const panel = receiptPanelView(empty, state.activeExpandedOrderId)
    assert.equal(panel.show, true)
    assert.match(panel.text, /Total Amount:\s*0₽/)
  })

  it("SSR: collapsed row renders CTA but no .aoa__receipt", async () => {
    const state = createActiveOrdersAccordionState(sampleOrders)
    const html = await renderSvelte(accordionComponentPath, {
      order: sampleOrders[0],
      accordionState: state
    })
    assert.match(html, /data-testid="active-order-receipt-cta"/)
    assert.doesNotMatch(html, /class="aoa__receipt[\s"]/)
  })

  it("SSR: after openOrderReceipt DOM has .aoa__receipt, item text, Total Amount", async () => {
    const state = createActiveOrdersAccordionState(sampleOrders)
    openOrderReceipt(state, "o1")
    const html = await renderSvelte(accordionComponentPath, {
      order: sampleOrders[0],
      accordionState: state
    })
    assert.match(html, /class="aoa__receipt[\s"]/)
    assert.match(html, /data-testid="active-order-receipt"/)
    assert.match(html, /Капучино/)
    assert.match(html, /\+ Сироп ваниль/)
    assert.match(html, /Total Amount: 250₽/)
    assert.match(html, /max-height: 350px; overflow-y: auto/)
    const receiptHtml = html.slice(html.search(/class="aoa__receipt[\s"]/))
    assert.doesNotMatch(receiptHtml, /<button/, "receipt must stay text-only")
  })

  it("SSR: only the expanded order renders .aoa__receipt", async () => {
    const state = createActiveOrdersAccordionState(sampleOrders)
    openOrderReceipt(state, "o1")
    openOrderReceipt(state, "o2")
    const [first, second] = await Promise.all(
      sampleOrders.map((order) =>
        renderSvelte(accordionComponentPath, { order, accordionState: state })
      )
    )
    assert.doesNotMatch(first, /class="aoa__receipt[\s"]/)
    assert.match(second, /class="aoa__receipt[\s"]/)
    assert.match(second, /Эспрессо/)
    assert.match(second, /Total Amount: 300₽/)
  })

  it("ActiveOrdersAccordion uses receiptPanelView for display path", () => {
    const src = readFileSync(accordionComponentPath, "utf8")
    assert.match(
      src,
      /receiptPanelView\s*\(/,
      "component must call receiptPanelView (runtime path, not source-only receiptView)"
    )
  })
})

describe("TASK_84-RECEIPT-DISPLAY-EXT Патч 1 — receipt fits visible area [TDD]", () => {
  // Замер local 390×844: .oss__panel 638–862, CartSheet clip 844, CTA top 752.
  const measured = {
    containerTop: 638,
    containerBottom: 862,
    clipBottom: 844,
    anchorTop: 752,
    ctaHeightPx: 25
  }

  it("receipt bottom stays inside clip (CartSheet) after scrolling CTA to panel top", () => {
    const fit = fitReceiptInView(measured)
    const receiptTop = measured.containerTop + measured.ctaHeightPx + fit.gapPx
    assert.ok(receiptTop + fit.maxHeightPx <= measured.clipBottom)
    assert.equal(fit.scrollDelta, 114)
    assert.equal(fit.bottomGapPx, 18)
  })

  it("receipt shorter than content gets own scroll (not the outer panel)", () => {
    const fit = fitReceiptInView(measured)
    assert.ok(fit.maxHeightPx < 196, "196px receipt must scroll inside itself")
  })

  it("caps at RECEIPT_SCROLL.maxHeightPx when space is large", () => {
    const fit = fitReceiptInView({
      containerTop: 0,
      containerBottom: 900,
      clipBottom: 900,
      anchorTop: 100,
      ctaHeightPx: 25
    })
    assert.equal(fit.maxHeightPx, RECEIPT_SCROLL.maxHeightPx)
    assert.equal(fit.bottomGapPx, 0)
  })

  it("never collapses below a readable minimum", () => {
    const fit = fitReceiptInView({
      containerTop: 800,
      containerBottom: 820,
      clipBottom: 820,
      anchorTop: 810,
      ctaHeightPx: 25
    })
    assert.equal(fit.maxHeightPx, 64)
  })

  it("component fits receipt on expand and blocks scroll chaining", () => {
    const src = readFileSync(accordionComponentPath, "utf8")
    assert.match(src, /fitReceiptInView\s*\(/)
    assert.match(src, /overscroll-behavior:\s*contain/)
  })

  it("re-fits after panel max-height transition ends (bugbot)", () => {
    const src = readFileSync(accordionComponentPath, "utf8")
    assert.match(src, /addEventListener\(\s*["']transitionend["']/)
    assert.match(src, /removeEventListener\(\s*["']transitionend["']/)
  })

  it("stale async fit is dropped after collapse / re-run (bugbot)", () => {
    const src = readFileSync(accordionComponentPath, "utf8")
    assert.match(src, /fitGeneration/)
    assert.match(src, /gen\s*!==\s*fitGeneration/)
  })
})
