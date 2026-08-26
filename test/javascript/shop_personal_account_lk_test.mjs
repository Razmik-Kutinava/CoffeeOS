import assert from "node:assert/strict"
import { describe, it } from "node:test"
import {
  formatAboutCopyText,
  shopAboutLegalLinks,
  shopAboutFooter
} from "../../app/frontend/lib/shopAboutConfig.js"
import { loadPlgBlockConfigs, plgBlockHasContent } from "../../app/frontend/lib/shopPlgBlocks.js"
import {
  formatOrderHistoryDate,
  orderHistoryLabel,
  orderHistoryTitle
} from "../../app/frontend/lib/shopAccountOrders.js"
import { loadNotificationPref, saveNotificationPref } from "../../app/frontend/lib/shopNotificationPrefs.js"

describe("shopAboutConfig (#69)", () => {
  it("legal links list has six entries from config", () => {
    const links = shopAboutLegalLinks()
    assert.equal(links.length, 6)
    assert.ok(links.every((l) => l.label && l.url))
  })

  it("formatAboutCopyText includes version and build", () => {
    const text = formatAboutCopyText()
    assert.match(text, /CoffeeOS/)
    assert.match(text, /код/)
  })

  it("footer has legal name and support email", () => {
    const footer = shopAboutFooter()
    assert.ok(footer.legalName)
    assert.ok(footer.supportEmail.includes("@"))
  })
})

describe("shopPlgBlocks (#69)", () => {
  it("returns two empty slots without content", () => {
    const blocks = loadPlgBlockConfigs()
    assert.equal(blocks.length, 2)
    assert.ok(blocks.every((b) => !plgBlockHasContent(b)))
  })
})

describe("shopAccountOrders helpers (#69)", () => {
  it("formats history row labels", () => {
    assert.equal(orderHistoryLabel({ order_number: "202608-0001", id: 1 }), "202608-0001")
    assert.equal(orderHistoryTitle({ title: "Капучино" }), "Капучино")
    assert.match(formatOrderHistoryDate("2026-08-23T10:00:00Z"), /\d{2}\.\d{2}/)
  })
})

describe("shopNotificationPrefs (#69)", () => {
  it("save returns ok flag", () => {
    const saved = saveNotificationPref(false)
    assert.equal(typeof saved.ok, "boolean")
    assert.equal(typeof saved.value, "boolean")
  })
})
