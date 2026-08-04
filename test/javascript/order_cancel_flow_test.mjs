/**
 * #40 Шаг 6 [TDD-RED] — модалка подтверждения отмены (accepted) + формат суммы.
 *
 * node --test test/javascript/order_cancel_flow_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync, existsSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  formatCancelAmountRub,
  buildAcceptedCancelModalCopy,
  shouldShowAcceptedCancelModal
} from "../../app/frontend/lib/orderCancelFlow.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const modalPath = join(root, "app/frontend/components/OrderCancelModal.svelte")
const orderStatusPath = join(root, "app/frontend/routes/OrderStatus.svelte")

describe("orderCancelFlow (#40 step 6)", () => {
  it("[TDD] formatCancelAmountRub rounds and appends ₽", () => {
    assert.equal(formatCancelAmountRub(150), "150 ₽")
    assert.equal(formatCancelAmountRub(150.4), "150 ₽")
    assert.equal(formatCancelAmountRub(150.6), "151 ₽")
    assert.equal(formatCancelAmountRub("200.00"), "200 ₽")
  })

  it("[TDD] buildAcceptedCancelModalCopy matches TZ copy", () => {
    const copy = buildAcceptedCancelModalCopy({
      orderNumber: "202608-0005",
      amount: 320
    })

    assert.equal(copy.title, "Отменить заказ №202608-0005?")
    assert.match(copy.body, /320 ₽/)
    assert.equal(copy.confirmLabel, "Да, отменить и вернуть 320 ₽")
    assert.equal(copy.dismissLabel, "Оставить заказ")
  })

  it("[TDD] shouldShowAcceptedCancelModal only for accepted", () => {
    assert.equal(shouldShowAcceptedCancelModal("accepted"), true)
    assert.equal(shouldShowAcceptedCancelModal("pending_payment"), false)
    assert.equal(shouldShowAcceptedCancelModal("preparing"), false)
    assert.equal(shouldShowAcceptedCancelModal("ready"), false)
  })
})

describe("OrderCancelModal artifact (#40 step 6)", () => {
  it("[TDD] OrderCancelModal.svelte exists with confirm/dismiss hooks", () => {
    assert.equal(existsSync(modalPath), true, "ожидается OrderCancelModal.svelte")
    const src = readFileSync(modalPath, "utf8")
    assert.match(src, /confirmLabel|confirm/)
    assert.match(src, /dismissLabel|Оставить заказ/)
    assert.match(src, /title/)
  })

  it("[TDD] OrderStatus uses orderCancelFlow / modal instead of window.confirm only", () => {
    const src = readFileSync(orderStatusPath, "utf8")
    assert.match(src, /orderCancelFlow|OrderCancelModal/)
    assert.doesNotMatch(src, /window\.confirm\("Отменить заказ\?"\)/)
  })
})
