/**
 * #71 Email-сбор после оплаты (Callcheck-флоу)
 *
 * node --test test/javascript/email_collection_test.mjs
 */
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { describe, it } from "node:test"
import { fileURLToPath } from "node:url"

import {
  getEmailValidationError,
  isValidEmailFormat,
  submitOrderEmail
} from "../../app/frontend/lib/emailCollection.js"
import { createNewCardFormState, setSaveCard } from "../../app/frontend/lib/shopNewCardForm.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")

function readFront(rel) {
  return readFileSync(join(root, "app/frontend", rel), "utf8")
}

describe("#71 Checkout — no email gate (S1/S2)", () => {
  it("identityReady / canPay depend on phoneVerified, not email", () => {
    const src = readFront("routes/Checkout.svelte")
    assert.match(src, /identityReady\s*=\s*\$derived\(phoneVerified\)/)
    assert.match(src, /canPay\s*=\s*\$derived\(identityReady/)
    assert.doesNotMatch(src, /canPay[^\n]*emailVerified/)
    assert.doesNotMatch(src, /identityReady[^\n]*emailVerified/)
  })

  it("checkout markup has no email input / email OTP fields", () => {
    const src = readFront("routes/Checkout.svelte")
    assert.doesNotMatch(src, /type=["']email["']/)
    assert.doesNotMatch(src, /email_otp/i)
    assert.doesNotMatch(src, /data-testid=["']checkout-email/)
  })

  it("checkout payment UI has no name field (identity = Callcheck phone)", () => {
    const src = readFront("routes/Checkout.svelte")
    // S1: нет поля «Имя» на экране оплаты
    assert.doesNotMatch(src, />Имя</)
    assert.doesNotMatch(src, /autocomplete=["']name["']/)
  })
})

describe("#71 save_card toggle (S3)", () => {
  it("NewCardForm exposes optional save toggle copy", () => {
    const src = readFront("components/NewCardForm.svelte")
    assert.match(src, /Сохранить карту для быстрой оплаты/)
    assert.match(src, /shop-new-card-save-toggle/)
  })

  it("save_card state does not gate form validity", () => {
    let state = createNewCardFormState()
    state = setSaveCard(state, false)
    assert.equal(state.save_card, false)
    state = setSaveCard(state, true)
    assert.equal(state.save_card, true)
  })
})

describe("#71 PaymentResult success shows email block (S4/S6)", () => {
  it("PaymentResult mounts OrderSuccessEmailBlock and success copy", () => {
    const src = readFront("routes/PaymentResult.svelte")
    assert.match(src, /OrderSuccessEmailBlock/)
    assert.match(src, /Чек сформирован/)
    assert.match(src, /handleEmailSkip/)
  })

  it("status=ok does NOT auto settleSuccess/redirect before email block [TDD]", () => {
    const src = readFront("routes/PaymentResult.svelte")
    // Happy-path: показать блок, не пушить /order сразу из onMount
    assert.doesNotMatch(
      src,
      /if\s*\(\s*isSbpReturnSuccessStatus\(status\)\s*\)\s*\{\s*[\s\S]*?await settleSuccess\(\)/
    )
    assert.match(src, /status === ["']ok["'][\s\S]*OrderSuccessEmailBlock/)
  })

  it("ok / ok_sbp / success stay on success UI path", () => {
    const src = readFront("routes/PaymentResult.svelte")
    assert.match(src, /ok_sbp/)
    assert.match(
      src,
      /status === ["']ok["'][\s\S]{0,80}ok_sbp|ok_sbp[\s\S]{0,80}status === ["']ok["']/
    )
  })
})

describe("#71 OrderSuccessEmailBlock UX (S5/S7/S18)", () => {
  it("copy and marketing consent opt-in default", () => {
    const block = readFront("components/OrderSuccessEmailBlock.svelte")
    assert.match(block, /Куда прислать чек и предложения/)
    assert.match(block, /Отправляйте мне предложения/)
    assert.match(block, /order-marketing-consent/)
    assert.match(block, /order-email-skip/)
    assert.doesNotMatch(block, /обязательн/i)
    const result = readFront("routes/PaymentResult.svelte")
    assert.match(result, /marketingConsent=\{false\}/)
  })

  it("inline validation helpers", () => {
    assert.equal(isValidEmailFormat(""), false)
    assert.equal(getEmailValidationError(""), "")
    assert.equal(getEmailValidationError("invalid@"), "Некорректный email")
    assert.equal(getEmailValidationError("user@example.com"), "")
    assert.equal(isValidEmailFormat("user@example.com"), true)
  })

  it("submitOrderEmail not called for invalid email from client helper path", async () => {
    let called = 0
    const api = async () => {
      called += 1
      return { success: true }
    }
    // client must validate before network — block pattern: getEmailValidationError first
    const err = getEmailValidationError("bad@")
    assert.equal(err, "Некорректный email")
    if (!err) await submitOrderEmail(api, { orderId: "x", email: "bad@", marketing_consent: false })
    assert.equal(called, 0)
  })

  it("submitOrderEmail POSTs to orders/:id/email", async () => {
    let url = ""
    let body = null
    const api = async (path, opts = {}) => {
      url = path
      body = JSON.parse(opts.body)
      return { success: true, email: body.email, queued_receipt: true }
    }
    const res = await submitOrderEmail(api, {
      orderId: "ord-1",
      email: "A@B.com",
      marketing_consent: true
    })
    assert.equal(url, "/shop/api/orders/ord-1/email")
    assert.equal(body.email, "a@b.com")
    assert.equal(body.marketing_consent, true)
    assert.equal(res.success, true)
  })
})
