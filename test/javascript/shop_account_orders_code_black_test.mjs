import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import {
  HISTORY_ORDER_HIGHLIGHT_MS,
  orderHistoryPointLabel,
  parseProfileHighlightOrderId
} from "../../app/frontend/lib/shopAccountOrders.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const read = (rel) => readFileSync(join(root, rel), "utf8")

describe("TASK_116 shopAccountOrders point label + highlight", () => {
  it("orderHistoryPointLabel shows name or closed mark", () => {
    assert.equal(
      orderHistoryPointLabel({ tenant: { name: "Point A", closed: false } }),
      "Point A"
    )
    assert.equal(
      orderHistoryPointLabel({ tenant: { name: "Hidden", closed: true } }),
      "Точка закрыта"
    )
    assert.equal(orderHistoryPointLabel({}), "")
  })

  it("highlight constant is 3000 ms", () => {
    assert.equal(HISTORY_ORDER_HIGHLIGHT_MS, 3000)
  })

  it("parseProfileHighlightOrderId reads order from hash query", () => {
    assert.equal(parseProfileHighlightOrderId("#/profile?order=42"), "42")
    assert.equal(parseProfileHighlightOrderId("#/profile?order=abc-1&x=1"), "abc-1")
    assert.equal(parseProfileHighlightOrderId("#/profile"), null)
    assert.equal(parseProfileHighlightOrderId("#/order/1/receipt"), null)
  })
})

describe("TASK_116 Profile / OrderReceipt source guards", () => {
  it("Profile shows status, point label, highlight hooks and keeps repeat", () => {
    const src = read("app/frontend/routes/Profile.svelte")
    assert.match(src, /orderHistoryPointLabel/)
    assert.match(src, /parseProfileHighlightOrderId/)
    assert.match(src, /HISTORY_ORDER_HIGHLIGHT_MS/)
    assert.match(src, /data-testid="shop-lk-order-status"/)
    assert.match(src, /data-testid="shop-lk-order-point"/)
    assert.match(src, /data-testid="shop-lk-order-highlight"/)
    assert.match(src, /startHistoryRepeatFromOrderId/)
    assert.match(src, /releaseHistoryRepeatUi/)
  })

  it("OrderReceipt shows order tenant point label", () => {
    const src = read("app/frontend/routes/OrderReceipt.svelte")
    assert.match(src, /orderHistoryPointLabel|tenant\.closed|Точка закрыта/)
    assert.match(src, /data-testid="shop-order-receipt-point"/)
    assert.match(src, /runHistoryRepeatPayFlow/)
    assert.match(src, /releaseHistoryRepeatUi/)
  })

  it("historyRepeatAdapter not modified for this task boundary", () => {
    const src = read("app/frontend/lib/historyRepeatAdapter.js")
    assert.match(src, /repeat_preview|fetchRepeatPreview|compareRepeatPreview/)
  })
})
