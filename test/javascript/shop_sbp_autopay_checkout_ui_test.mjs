/**
 * #34 Checkout SBP Autopay UI helpers.
 * node --test test/javascript/shop_sbp_autopay_checkout_ui_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import {
  pickDefaultPaymentSelection,
  chargeSbpAutopay,
  buildSbpInitBody,
  SBP_AUTOPAY_TOASTS
} from "../../app/frontend/lib/shopSbpAutopay.js"
import { initSbpPayment } from "../../app/frontend/lib/shopSbpPay.js"
import {
  labelSbpAccount,
  labelBindSbpAccount
} from "../../app/frontend/lib/paymentMethodI18n.js"

describe("i18n — SBP account labels", () => {
  it("exposes account + bind checkbox labels", () => {
    assert.match(labelSbpAccount(), /ваш счет сбп/i)
    assert.match(labelBindSbpAccount(), /привязать счет/i)
  })
})

describe("pickDefaultPaymentSelection", () => {
  it("defaults to sbp_account when AccountToken exists", () => {
    const picked = pickDefaultPaymentSelection({
      sbpAccounts: [{ id: "a1" }],
      cards: [{ id: "c1" }],
      primary: { id: "c1" },
      persisted: { selectedCardId: "c1", selectionMode: "saved_card" }
    })
    assert.equal(picked.selectionMode, "sbp_account")
    assert.equal(picked.selectedCardId, null)
  })

  it("falls back to card when no sbp account", () => {
    const picked = pickDefaultPaymentSelection({
      sbpAccounts: [],
      cards: [{ id: "c1" }],
      primary: { id: "c1" }
    })
    assert.equal(picked.selectionMode, "saved_card")
    assert.equal(picked.selectedCardId, "c1")
  })

  it("falls back to manual sbp when empty", () => {
    const picked = pickDefaultPaymentSelection({ sbpAccounts: [], cards: [] })
    assert.equal(picked.selectionMode, "sbp")
  })
})

describe("initSbpPayment — save_sbp_account", () => {
  it("posts save_sbp_account when bind requested", async () => {
    const calls = []
    const api = async (path, opts = {}) => {
      calls.push({ path, opts })
      return { payment_url: "https://qr.nspk.ru/AS1" }
    }
    await initSbpPayment(api, { orderId: "o1", saveSbpAccount: true })
    assert.deepEqual(calls[0].opts.body, { order_id: "o1", save_sbp_account: true })
  })
})

describe("chargeSbpAutopay", () => {
  it("posts /payments/sbp/charge", async () => {
    const calls = []
    const api = async (path, opts = {}) => {
      calls.push({ path, opts })
      return { status: "CONFIRMED", order_id: "o9" }
    }
    const res = await chargeSbpAutopay(api, { orderId: "o9" })
    assert.equal(res.status, "CONFIRMED")
    assert.equal(calls[0].path, "/payments/sbp/charge")
    assert.deepEqual(calls[0].opts.body, { order_id: "o9" })
  })

  it("maps CHARGE_DECLINED toast", async () => {
    const api = async () => {
      const err = new Error("declined")
      err.status = 422
      err.body = { error_code: "CHARGE_DECLINED" }
      throw err
    }
    await assert.rejects(
      () => chargeSbpAutopay(api, { orderId: "o1" }),
      (e) => e.message === SBP_AUTOPAY_TOASTS.CHARGE_DECLINED && e.error_code === "CHARGE_DECLINED"
    )
  })
})

describe("buildSbpInitBody", () => {
  it("omits flag when false", () => {
    assert.deepEqual(buildSbpInitBody({ orderId: "x", saveSbpAccount: false }), {
      order_id: "x"
    })
  })
})
