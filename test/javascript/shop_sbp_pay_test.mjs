/**
 * SBP return polling — Шаг 11 (RED→GREEN).
 * node --test test/javascript/shop_sbp_pay_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import {
  initSbpPayment,
  redirectToSbp,
  sbpPollOptions,
  mapSbpInitError,
  SBP_LOADING_LABEL,
  SBP_INCOMPLETE_MESSAGE,
  pollSbpPaymentStatus,
  isSbpReturnSuccessStatus
} from "../../app/frontend/lib/shopSbpPay.js"
import { ctaSbpFastPay, labelSbp } from "../../app/frontend/lib/paymentMethodI18n.js"

describe("paymentMethodI18n — SBP fast pay CTA", () => {
  it("exposes «Оплатить быстро» for SBP", () => {
    assert.equal(labelSbp(), "СБП")
    assert.equal(ctaSbpFastPay(), "Оплатить быстро")
  })
})

describe("shopSbpPay — init + redirect", () => {
  it("initSbpPayment posts /payments/sbp/init and returns payment_url", async () => {
    const calls = []
    const api = async (path, opts = {}) => {
      calls.push({ path, opts })
      return { payment_url: "https://qr.nspk.ru/AS10000TEST" }
    }

    const url = await initSbpPayment(api, { orderId: "ord-1" })
    assert.equal(url, "https://qr.nspk.ru/AS10000TEST")
    assert.equal(calls[0].path, "/payments/sbp/init")
    assert.equal(calls[0].opts.method, "POST")
    assert.deepEqual(calls[0].opts.body, { order_id: "ord-1" })
  })

  it("initSbpPayment throws mapped error on 400/500", async () => {
    const api = async () => {
      const err = new Error("bad")
      err.status = 500
      err.body = { error: "bank down" }
      throw err
    }
    await assert.rejects(() => initSbpPayment(api, { orderId: "x" }), /bank down|не удалось|ошибка/i)
  })

  it("redirectToSbp assigns window.location to nspk url", () => {
    const hits = []
    redirectToSbp("https://qr.nspk.ru/AS1", (href) => hits.push(href))
    assert.deepEqual(hits, ["https://qr.nspk.ru/AS1"])
  })

  it("redirectToSbp rejects non-nspk urls", () => {
    assert.throws(() => redirectToSbp("https://evil.example/pay"), /nspk|недопустим/i)
  })

  it("sbpPollOptions is 2s × 30 (60s cap)", () => {
    const opts = sbpPollOptions()
    assert.equal(opts.intervalMs, 2000)
    assert.equal(opts.maxAttempts, 30)
  })

  it("mapSbpInitError surfaces terminal message", () => {
    assert.match(mapSbpInitError(400, { error: "bad order" }), /bad order|заказ/i)
    assert.match(mapSbpInitError(500, {}), /ошибка|не удалось/i)
  })

  it("exports monochrome loading label", () => {
    assert.match(SBP_LOADING_LABEL, /оплат|сбп|загруз/i)
  })
})

describe("shopSbpPay — return polling (Шаг 11)", () => {
  it("exports incomplete message for timeout / reject", () => {
    assert.match(SBP_INCOMPLETE_MESSAGE, /не завершен|попробовать/i)
  })

  it("isSbpReturnSuccessStatus accepts success and ok", () => {
    assert.equal(isSbpReturnSuccessStatus("success"), true)
    assert.equal(isSbpReturnSuccessStatus("ok"), true)
    assert.equal(isSbpReturnSuccessStatus("fail"), false)
    assert.equal(isSbpReturnSuccessStatus("cancel"), false)
  })

  it("pollSbpPaymentStatus resolves when finalize settles", async () => {
    let n = 0
    const sleeps = []
    const api = async (path) => {
      n += 1
      assert.match(path, /\/orders\/ord-1\/finalize/)
      if (n < 3) return { status: "pending_payment", payment_settled: false }
      return { status: "accepted", payment_settled: true }
    }
    const res = await pollSbpPaymentStatus(api, {
      orderId: "ord-1",
      sleep: async (ms) => {
        sleeps.push(ms)
      }
    })
    assert.equal(res.payment_settled, true)
    assert.equal(n, 3)
    assert.deepEqual(sleeps, [2000, 2000])
  })

  it("pollSbpPaymentStatus stops on cancelled/rejected with incomplete message", async () => {
    const api = async () => ({ status: "cancelled", payment_settled: false })
    await assert.rejects(
      () => pollSbpPaymentStatus(api, { orderId: "x", sleep: async () => {} }),
      (err) => {
        assert.match(err.message, /не завершен|попробовать/i)
        assert.equal(err.kind, "sbp_terminal")
        return true
      }
    )
  })

  it("pollSbpPaymentStatus times out after maxAttempts without infinite loop", async () => {
    let n = 0
    const api = async () => {
      n += 1
      return { status: "pending_payment", payment_settled: false }
    }
    await assert.rejects(
      () => pollSbpPaymentStatus(api, { orderId: "x", sleep: async () => {} }),
      (err) => {
        assert.match(err.message, /не завершен|попробовать/i)
        assert.equal(err.kind, "sbp_timeout")
        return true
      }
    )
    assert.equal(n, 30)
  })
})
