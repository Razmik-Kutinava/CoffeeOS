/**
 * TASK_103 — вертикальный скролл списка активных заказов в статусной шторке.
 * Контракт разметки/CSS; фактическая прокрутка — браузерный замер
 * (artifacts/active_orders_list_scroll/MEASURE.md), в node нет layout.
 *
 * node --test test/javascript/order_status_list_scroll_test.mjs
 */
import { describe, it } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { shouldScrollStatusList } from "../../app/frontend/lib/orderStatusSheet.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const read = (rel) => readFileSync(join(root, rel), "utf8")
const sheetSrc = () => read("app/frontend/components/OrderStatusSheet.svelte")
const accordionSrc = () => read("app/frontend/components/ActiveOrdersAccordion.svelte")

function cssRule(src, selector) {
  const esc = selector.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
  const m = src.match(new RegExp(`${esc}\\s*\\{([^}]*)\\}`))
  return m ? m[1] : null
}

function markup(src) {
  return src.split("<style>")[0]
}

describe("TASK_103 — список заказов в отдельном scroll-контейнере [TDD]", () => {
  it("подсказка ↕ уже при двух заказах (Subtask 1), не при одном", () => {
    assert.equal(shouldScrollStatusList([{ id: 1 }]), false)
    assert.equal(shouldScrollStatusList([{ id: 1 }, { id: 2 }]), true)
    assert.equal(shouldScrollStatusList([{ id: 1 }, { id: 2 }, { id: 3 }]), true)
  })

  it("строки заказов и подсказка лежат внутри .oss__list с data-oss-scroll-root", () => {
    const html = markup(sheetSrc())
    const list = html.match(/<div[^>]*class="oss__list"[^>]*>([\s\S]*?)\n {4}<\/div>/)
    assert.ok(list, "нужен <div class=\"oss__list\"> внутри панели")
    assert.match(list[0], /data-testid="shop-order-status-list"/)
    assert.match(list[0], /data-oss-scroll-root/)
    assert.match(list[1], /\{#each displayOrders as order/)
    assert.match(list[1], /<ActiveOrdersAccordion/)
    assert.match(list[1], /oss__scroll-hint/)
  })

  it("скролл не зависит от числа заказов: .oss__list без class:scrollable", () => {
    const tag = markup(sheetSrc()).match(/<div[^>]*class="oss__list"[^>]*>/)
    assert.ok(tag)
    assert.doesNotMatch(tag[0], /class:/)
  })

  it(".oss__list — scroll-бокс с contain (не тащит CartSheet / экран)", () => {
    const rule = cssRule(sheetSrc(), ".oss__list") || ""
    assert.match(rule, /overflow-y:\s*auto/)
    assert.match(rule, /overscroll-behavior:\s*contain/)
    assert.match(rule, /min-height:\s*0/)
  })

  it(".oss__panel — рамка peek без собственного скролла (Subtask 5)", () => {
    const src = sheetSrc()
    const panel = cssRule(src, ".oss__panel") || ""
    assert.match(panel, /display:\s*flex/)
    assert.match(panel, /flex-direction:\s*column/)
    assert.match(panel, /overflow:\s*hidden/)
    assert.equal(cssRule(src, ".oss__panel.scrollable"), null)
    assert.equal(cssRule(src, ".oss__panel.receipt-open"), null)
    assert.doesNotMatch(src, /class:receipt-open/)
  })

  it("высота peek не меняется (#42)", () => {
    const src = sheetSrc()
    assert.match(cssRule(src, ".oss__panel") || "", /max-height:\s*8\.75rem/)
    assert.match(cssRule(src, ".oss__panel.embedded") || "", /max-height:\s*min\(22vh,\s*8\.5rem\)/)
  })

  it("подгонка чека скроллит только [data-oss-scroll-root], не ближайший overflow-предок", () => {
    const src = accordionSrc()
    const fn = src.match(/function measureReceiptFit\(\)\s*\{([\s\S]*?)\n {2}\}/)
    assert.ok(fn, "measureReceiptFit на месте")
    assert.match(fn[1], /closest\(\s*["']\[data-oss-scroll-root\]["']\s*\)/)
    assert.doesNotMatch(fn[1], /isScrollBox/)
    assert.doesNotMatch(src, /function isScrollBox/)
  })
})
