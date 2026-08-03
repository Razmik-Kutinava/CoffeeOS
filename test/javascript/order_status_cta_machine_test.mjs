/**
 * #38 Шаг 5 [TDD-RED] — PWA UI CTA state machine на карточке заказа.
 *
 * node --test test/javascript/order_status_cta_machine_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  CTA_STYLE,
  orderStatusCtas,
  showReconnectBanner
} from "../../app/frontend/lib/orderStatusCtaMachine.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const orderStatusPath = join(root, "app/frontend/routes/OrderStatus.svelte")

describe("orderStatusCtas (#38 step 5)", () => {
  it("accepted: max 2 — Отменить + Push (android)", () => {
    const view = orderStatusCtas({
      status: "accepted",
      os: "android",
      canCancel: true
    })
    assert.equal(view.buttons.length, 2)
    assert.ok(view.buttons.length <= 2)
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["cancel", "push"]
    )
    assert.equal(view.buttons[0].label, "Отменить")
    assert.match(view.buttons[1].label, /Уведомление|Push|push/i)
    assert.equal(view.style.background, CTA_STYLE.background)
  })

  it("accepted ios: Отменить + Wallet", () => {
    const view = orderStatusCtas({
      status: "accepted",
      os: "ios",
      canCancel: true
    })
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["cancel", "wallet"]
    )
    assert.match(view.buttons[1].label, /Apple Wallet|Wallet/)
  })

  it("accepted without canCancel: only Push/Wallet (≤2)", () => {
    const view = orderStatusCtas({
      status: "accepted",
      os: "android",
      canCancel: false
    })
    assert.equal(view.buttons.length, 1)
    assert.equal(view.buttons[0].kind, "push")
  })

  it("preparing: cancel gone — Чат + Чаевые (android)", () => {
    const view = orderStatusCtas({
      status: "preparing",
      os: "android",
      canCancel: false
    })
    assert.equal(view.buttons.length, 2)
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["chat", "tips"]
    )
    assert.equal(view.buttons[0].label, "Чат")
    assert.equal(view.buttons[1].label, "Чаевые")
    assert.ok(!view.buttons.some((b) => b.kind === "cancel"))
  })

  it("preparing ios: Чат + Wallet", () => {
    const view = orderStatusCtas({
      status: "preparing",
      os: "ios",
      canCancel: true
    })
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["chat", "wallet"]
    )
  })

  it("ready: same matrix as preparing (chat + tips/wallet)", () => {
    const android = orderStatusCtas({ status: "ready", os: "android" })
    const ios = orderStatusCtas({ status: "ready", os: "ios" })
    assert.deepEqual(
      android.buttons.map((b) => b.kind),
      ["chat", "tips"]
    )
    assert.deepEqual(
      ios.buttons.map((b) => b.kind),
      ["chat", "wallet"]
    )
  })

  it("cancelled / unknown: no CTAs", () => {
    assert.equal(orderStatusCtas({ status: "cancelled", os: "android" }).buttons.length, 0)
    assert.equal(orderStatusCtas({ status: "pending_payment", os: "ios" }).buttons.length, 0)
  })
})

describe("showReconnectBanner (#38 step 5)", () => {
  it("true only when cable disconnected", () => {
    assert.equal(showReconnectBanner("disconnected"), true)
    assert.equal(showReconnectBanner("connected"), false)
    assert.equal(showReconnectBanner("idle"), false)
  })
})

describe("OrderStatus wires CTA machine (#38 step 5)", () => {
  it("imports orderStatusCtaMachine", () => {
    const src = readFileSync(orderStatusPath, "utf8")
    assert.match(src, /orderStatusCtaMachine/)
    assert.match(src, /orderStatusCtas/)
  })
})
