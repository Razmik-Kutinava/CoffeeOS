/**
 * #73 Патч 1 — poll «Чек формируется» → появление fiscal receipt без перезахода.
 *
 * node --test test/javascript/order_receipt_fiscal_poll_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import {
  ORDER_RECEIPT_FISCAL_POLL_MS,
  shouldKeepPollingFiscal
} from "../../app/frontend/lib/orderReceiptFiscalPoll.js"

describe("#73 Patch1 orderReceiptFiscalPoll", () => {
  it("[TDD] exports poll interval and keep-polling helper", () => {
    assert.equal(typeof ORDER_RECEIPT_FISCAL_POLL_MS, "number")
    assert.ok(ORDER_RECEIPT_FISCAL_POLL_MS >= 3000)
    assert.equal(typeof shouldKeepPollingFiscal, "function")
  })

  it("[TDD] polls only while settled + fiscal_expected + no visible receipt", () => {
    assert.equal(
      shouldKeepPollingFiscal({
        payment_settled: true,
        fiscal_expected: true,
        status: "accepted",
        fiscal_receipts: []
      }),
      true
    )
    assert.equal(
      shouldKeepPollingFiscal({
        payment_settled: true,
        fiscal_expected: true,
        status: "accepted",
        fiscal_receipts: [{ url: "https://ofd.example/r1" }]
      }),
      false
    )
    assert.equal(
      shouldKeepPollingFiscal({
        payment_settled: true,
        fiscal_expected: true,
        status: "cancelled",
        fiscal_receipts: []
      }),
      false
    )
    assert.equal(
      shouldKeepPollingFiscal({
        payment_settled: false,
        fiscal_expected: true,
        status: "pending_payment",
        fiscal_receipts: []
      }),
      false
    )
  })

  it("[TDD] visible via FN/FD/FP stops poll without Url", () => {
    assert.equal(
      shouldKeepPollingFiscal({
        payment_settled: true,
        fiscal_expected: true,
        status: "ready",
        fiscal_receipts: [{ fn_number: "9999", fiscal_document_number: 1, fiscal_document_attribute: 2 }]
      }),
      false
    )
  })
})
