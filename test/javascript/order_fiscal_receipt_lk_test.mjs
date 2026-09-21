/**
 * #73 — ЛК OrderReceipt: секция «Чек» с ссылкой и ФН/ФД/ФП (без своего QR).
 *
 * node --test test/javascript/order_fiscal_receipt_lk_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const src = readFileSync(join(root, "app/frontend/routes/OrderReceipt.svelte"), "utf8")

describe("#73 OrderReceipt fiscal OFD section", () => {
  it("has Чек section, external link, forming state", () => {
    assert.match(src, /data-testid="shop-order-fiscal-section"/)
    assert.match(src, /data-testid="shop-order-fiscal-link"/)
    assert.match(src, /data-testid="shop-order-ofd-forming"/)
    assert.match(src, /Чек формируется/)
    assert.match(src, /target="_blank"/)
  })

  it("[TDD] shows FN/FD/FP fiscal attributes from API (not own QR)", () => {
    assert.match(src, /fn_number/)
    assert.match(src, /fiscal_document_number/)
    assert.match(src, /fiscal_document_attribute/)
    assert.match(src, /data-testid="shop-order-fiscal-attrs"/)
    // запрет ТЗ: не генерировать свой QR по ФН/ФД/ФП
    assert.doesNotMatch(src, /qrcode|QRCode|generateQr|new QRCode/i)
  })

  it("labels refund receipt separately", () => {
    assert.match(src, /operation_type === ["']refund["']/)
    assert.match(src, /Чек возврата/)
  })

  it("shows receipt without Url via FN/FD/FP; no forming for cancelled", () => {
    assert.match(src, /receiptVisible/)
    assert.match(src, /status !== ["']cancelled["']/)
    assert.match(src, /shop-order-fiscal-label/)
  })

  it("[TDD Patch1] live-refresh polls while Чек формируется (not status-sheet)", () => {
    assert.match(src, /orderReceiptFiscalPoll/)
    assert.match(src, /shouldKeepPollingFiscal/)
    assert.match(src, /ORDER_RECEIPT_FISCAL_POLL_MS|setInterval/)
    assert.doesNotMatch(src, /ACTIVE_ORDERS_POLL_MS|GuestOrderChannel|receiptView/)
  })
})
