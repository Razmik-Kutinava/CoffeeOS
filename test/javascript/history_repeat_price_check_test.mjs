/**
 * TASK_121 — проверка цен перед повтором заказа из истории [TDD].
 *
 * node --test test/javascript/history_repeat_price_check_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"
import { get } from "svelte/store"

import {
  HISTORY_REPEAT_PRICES_CHANGED_TEXT,
  HISTORY_REPEAT_PROMO_TEXT,
  HISTORY_REPEAT_UNAVAILABLE_TEXT,
  HISTORY_REPEAT_PREVIEW_FAILED_TEXT,
  HISTORY_REPEAT_BLOCK_REASONS,
  historyRepeatBlockText,
  repeatPreviewPath,
  fetchRepeatPreview,
  compareRepeatPreview,
  historyRepeatNotice,
  showHistoryRepeatNotice,
  dismissHistoryRepeatNotice
} from "../../app/frontend/lib/historyRepeatPriceCheck.js"
import { renderSvelte } from "./svelte_ssr_helper.mjs"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const read = (p) => readFileSync(join(root, p), "utf8")
const noticePath = join(root, "app/frontend/components/HistoryRepeatNotice.svelte")

function line(over = {}) {
  return {
    product_id: "p1",
    product_name: "Латте",
    quantity: 1,
    price: 200,
    unit_total: 200,
    line_total: 200,
    unavailable: false,
    ...over
  }
}

function preview(over = {}) {
  const items = over.items || [ line(), line({ product_id: "p2", quantity: 2, price: 150, unit_total: 150, line_total: 300 }) ]
  return {
    order_id: "hist-1",
    items,
    total: 500,
    previous_total: 500,
    previous_discount: 0,
    ...over
  }
}

describe("TASK_121 Subtask 11 — тексты константами", () => {
  it("тексты по умолчанию из документа", () => {
    assert.equal(HISTORY_REPEAT_PRICES_CHANGED_TEXT, "Повторить заказ нельзя: цены изменились")
    assert.equal(HISTORY_REPEAT_PROMO_TEXT, "Повторить заказ нельзя: он был оформлен по акции")
    assert.equal(HISTORY_REPEAT_UNAVAILABLE_TEXT, "Повторить заказ нельзя: некоторых позиций нет в этой точке")
    assert.equal(HISTORY_REPEAT_PREVIEW_FAILED_TEXT, "Не удалось проверить цены. Попробуйте ещё раз.")
  })

  it("причина → текст", () => {
    assert.equal(historyRepeatBlockText(HISTORY_REPEAT_BLOCK_REASONS.prices), HISTORY_REPEAT_PRICES_CHANGED_TEXT)
    assert.equal(historyRepeatBlockText(HISTORY_REPEAT_BLOCK_REASONS.promo), HISTORY_REPEAT_PROMO_TEXT)
    assert.equal(historyRepeatBlockText(HISTORY_REPEAT_BLOCK_REASONS.unavailable), HISTORY_REPEAT_UNAVAILABLE_TEXT)
  })
})

describe("TASK_121 Subtask 1 — запрос превью", () => {
  it("GET /orders/:id/repeat_preview, без тела и без изменения заказа", async () => {
    const calls = []
    const api = async (path, opts = {}) => {
      calls.push({ path, method: opts.method || "GET", body: opts.body })
      return preview()
    }
    const res = await fetchRepeatPreview({ id: "hist-1" }, { api })
    assert.equal(res.order_id, "hist-1")
    assert.deepEqual(calls, [ { path: "/orders/hist-1/repeat_preview", method: "GET", body: undefined } ])
    assert.equal(repeatPreviewPath("a/b"), "/orders/a%2Fb/repeat_preview")
  })
})

describe("TASK_121 Subtask 2–5, 7 — сравнение", () => {
  it("всё совпало → повтор разрешён", () => {
    assert.deepEqual(compareRepeatPreview(preview()), { ok: true })
  })

  it("копейки не дают ложного отличия", () => {
    const p = preview({
      items: [ line({ price: 199.9, unit_total: 199.90000000000001, line_total: 199.9 }) ],
      total: 199.9,
      previous_total: 199.9
    })
    assert.deepEqual(compareRepeatPreview(p), { ok: true })
  })

  it("цена за единицу выше → цены изменились", () => {
    const p = preview({ items: [ line({ unit_total: 230, line_total: 230 }) ], total: 230, previous_total: 200 })
    assert.deepEqual(compareRepeatPreview(p), { ok: false, reason: "prices" })
  })

  it("цена за единицу ниже → цены изменились", () => {
    const p = preview({ items: [ line({ unit_total: 180, line_total: 180 }) ], total: 180, previous_total: 200 })
    assert.deepEqual(compareRepeatPreview(p), { ok: false, reason: "prices" })
  })

  it("цены строк те же, но общая сумма другая → цены изменились", () => {
    const p = preview({ items: [ line() ], total: 200, previous_total: 210 })
    assert.deepEqual(compareRepeatPreview(p), { ok: false, reason: "prices" })
  })

  it("модификаторы: сравнивается цена за единицу с модификаторами", () => {
    const p = preview({ items: [ line({ price: 230, unit_total: 250, line_total: 250 }) ], total: 250, previous_total: 230 })
    assert.deepEqual(compareRepeatPreview(p), { ok: false, reason: "prices" })
  })

  it("заказ по акции (скидка на заказ) → по акции", () => {
    const p = preview({ items: [ line() ], total: 200, previous_total: 11, previous_discount: 189 })
    assert.deepEqual(compareRepeatPreview(p), { ok: false, reason: "promo" })
  })

  it("прежняя сумма ниже суммы строк без discount_amount → по акции", () => {
    const p = preview({ items: [ line() ], total: 200, previous_total: 11, previous_discount: 0 })
    assert.deepEqual(compareRepeatPreview(p), { ok: false, reason: "promo" })
  })

  it("недоступная позиция → некоторых позиций нет (приоритетнее акции и цен)", () => {
    const p = preview({
      items: [ line({ unit_total: 260, line_total: 260 }), line({ product_id: "p2", unavailable: true, unit_total: null, line_total: null }) ],
      total: 260,
      previous_total: 11,
      previous_discount: 189
    })
    assert.deepEqual(compareRepeatPreview(p), { ok: false, reason: "unavailable" })
  })

  it("акция приоритетнее отличия цен", () => {
    const p = preview({ items: [ line({ unit_total: 260, line_total: 260 }) ], total: 260, previous_total: 11, previous_discount: 189 })
    assert.deepEqual(compareRepeatPreview(p), { ok: false, reason: "promo" })
  })

  it("битый ответ превью → исключение (оплату не запускаем)", () => {
    assert.throws(() => compareRepeatPreview(null))
    assert.throws(() => compareRepeatPreview({}))
    assert.throws(() => compareRepeatPreview({ items: [] }))
    assert.throws(() => compareRepeatPreview({ items: [ line() ], total: "x", previous_total: 200 }))
  })
})

describe("TASK_121 Subtask 6 — сообщение на главной", () => {
  beforeEach(() => dismissHistoryRepeatNotice())

  it("показ и закрытие; хранится только в памяти", () => {
    assert.equal(get(historyRepeatNotice), null)
    showHistoryRepeatNotice("prices")
    assert.deepEqual(get(historyRepeatNotice), { reason: "prices", text: HISTORY_REPEAT_PRICES_CHANGED_TEXT })
    dismissHistoryRepeatNotice()
    assert.equal(get(historyRepeatNotice), null)
    const src = read("app/frontend/lib/historyRepeatPriceCheck.js")
    assert.doesNotMatch(src, /localStorage|sessionStorage/)
  })

  it("SSR: блок с текстом и кнопкой закрытия, без своего слоя поверх экрана", async () => {
    showHistoryRepeatNotice("unavailable")
    const html = await renderSvelte(noticePath, {})
    assert.match(html, /data-testid="shop-history-repeat-notice"/)
    assert.ok(html.includes(HISTORY_REPEAT_UNAVAILABLE_TEXT))
    assert.match(html, /aria-label="Закрыть"/)
    const src = read("app/frontend/components/HistoryRepeatNotice.svelte")
    assert.doesNotMatch(src, /position:\s*(fixed|absolute|sticky)/)
    assert.doesNotMatch(src, /z-index/)
    assert.match(src, /dismissHistoryRepeatNotice/)
    assert.match(src, /onpointerdown|onpointerup|ontouchstart/, "закрытие жестом")
  })

  it("SSR: нет сообщения — нет блока", async () => {
    const html = await renderSvelte(noticePath, {})
    assert.doesNotMatch(html, /shop-history-repeat-notice/)
  })

  it("каталог показывает блок над категориями и сбрасывает сообщение при уходе", () => {
    const src = read("app/frontend/routes/Catalog.svelte")
    assert.match(src, /import HistoryRepeatNotice from "\.\.\/components\/HistoryRepeatNotice\.svelte"/)
    const markup = src.slice(src.indexOf("</script>"))
    assert.ok(markup.indexOf("<HistoryRepeatNotice") >= 0, "блок смонтирован")
    assert.ok(markup.indexOf("<HistoryRepeatNotice") < markup.indexOf("{#if loading}"), "над каталогом и скелетоном")
    assert.match(src, /return \(\) => \{[^}]*dismissHistoryRepeatNotice\(\)/)
  })
})
