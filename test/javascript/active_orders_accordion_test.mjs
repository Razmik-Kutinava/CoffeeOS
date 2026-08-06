/**
 * #36 Active orders accordion + text receipt — RED [TDD].
 *
 * node --test test/javascript/active_orders_accordion_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import {
  RECEIPT_SCROLL,
  CHEVRON,
  createActiveOrdersAccordionState,
  toggleExpandedOrder,
  accordionRowView,
  receiptView,
  statusMetaThird
} from "../../app/frontend/lib/activeOrdersAccordion.js"

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
