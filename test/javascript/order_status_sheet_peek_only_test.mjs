import { describe, it } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { fitReceiptInView } from "../../app/frontend/lib/activeOrdersAccordion.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const sheetSrc = () =>
  readFileSync(join(root, "app/frontend/components/OrderStatusSheet.svelte"), "utf8")

function cssRule(src, selector) {
  const esc = selector.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
  const m = src.match(new RegExp(`${esc}\\s*\\{([^}]*)\\}`))
  return m ? m[1] : null
}

describe("TASK_84-PEEK-ONLY-EXT — статусная шторка только peek [TDD]", () => {
  it("statusSheetMode never becomes EXPANDED (open receipt keeps peek)", () => {
    assert.doesNotMatch(sheetSrc(), /ORDER_STATUS_SHEET_MODES\.EXPANDED/)
  })

  it("panel has no expanded class / growth CSS", () => {
    const src = sheetSrc()
    assert.doesNotMatch(src, /class:expanded=/)
    assert.equal(cssRule(src, ".oss__panel.expanded"), null)
    assert.equal(cssRule(src, ".oss__panel.embedded.expanded"), null)
  })

  it("peek height caps stay as before (#42)", () => {
    const src = sheetSrc()
    assert.match(cssRule(src, ".oss__panel.embedded") || "", /max-height:\s*min\(22vh,\s*8\.5rem\)/)
    assert.match(cssRule(src, ".oss__panel") || "", /max-height:\s*8\.75rem/)
  })

  it("open receipt does not change panel height or scroll the panel (TASK_103: scroll in .oss__list)", () => {
    const src = sheetSrc()
    assert.equal(cssRule(src, ".oss__panel.receipt-open"), null)
    assert.doesNotMatch(src, /class:receipt-open/)
    assert.match(cssRule(src, ".oss__list") || "", /overflow-y:\s*auto/)
  })

  it("receipt fits inside peek panel (embedded 136px) with own scroll", () => {
    const m = { containerTop: 708, containerBottom: 844, clipBottom: 844, anchorTop: 760, ctaHeightPx: 25 }
    const fit = fitReceiptInView(m)
    const receiptTop = m.containerTop + m.ctaHeightPx + fit.gapPx
    assert.ok(fit.maxHeightPx >= 64)
    assert.ok(receiptTop + fit.maxHeightPx <= m.clipBottom)
  })
})
