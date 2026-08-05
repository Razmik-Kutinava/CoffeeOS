/**
 * #38 / #40 / #41 — PWA UI CTA state machine на карточке заказа.
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

describe("orderStatusCtas (#38 / #40 step 5)", () => {
  it("accepted: max 2 — Отменить заказ + Push (android)", () => {
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
    assert.equal(view.buttons[0].label, "Отменить заказ")
    assert.equal(view.buttons[0].hint, "Вернем 100% суммы")
    assert.equal(view.buttons[1].label, "Включить Push")
    assert.equal(view.style.background, CTA_STYLE.background)
  })

  it("accepted ios: Отменить заказ + Wallet", () => {
    const view = orderStatusCtas({
      status: "accepted",
      os: "ios",
      canCancel: true
    })
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["cancel", "wallet"]
    )
    assert.equal(view.buttons[0].label, "Отменить заказ")
    assert.equal(view.buttons[0].hint, "Вернем 100% суммы")
    assert.equal(view.buttons[1].label, "Добавить в Wallet")
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

  it("[TDD] pending_payment + canCancel: Отменить заказ (без 100% hint)", () => {
    const view = orderStatusCtas({
      status: "pending_payment",
      os: "android",
      canCancel: true
    })
    const cancel = view.buttons.find((b) => b.kind === "cancel")
    assert.ok(cancel, "ожидается кнопка cancel")
    assert.equal(cancel.label, "Отменить заказ")
    assert.equal(cancel.hint, undefined)
    assert.ok(view.buttons.length <= 2)
  })

  it("preparing: cancel gone — Чат + Чаевые (android, subscribed)", () => {
    const view = orderStatusCtas({
      status: "preparing",
      os: "android",
      canCancel: false,
      hasPushSubscription: true
    })
    assert.equal(view.buttons.length, 2)
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["chat", "tips"]
    )
    assert.equal(view.buttons[0].label, "Чат с поддержкой")
    assert.equal(view.buttons[1].label, "Оставить чаевые")
    assert.ok(!view.buttons.some((b) => b.kind === "cancel"))
  })

  it("preparing ios + subscribed: Чат + Чаевые", () => {
    const view = orderStatusCtas({
      status: "preparing",
      os: "ios",
      canCancel: true,
      hasPushSubscription: true
    })
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["chat", "tips"]
    )
    assert.equal(view.buttons[0].label, "Чат с поддержкой")
    assert.equal(view.buttons[1].label, "Оставить чаевые")
  })

  it("ready + subscribed: same matrix as preparing (chat + tips)", () => {
    const android = orderStatusCtas({
      status: "ready",
      os: "android",
      hasPushSubscription: true
    })
    const ios = orderStatusCtas({
      status: "ready",
      os: "ios",
      hasPushSubscription: true
    })
    assert.deepEqual(
      android.buttons.map((b) => b.kind),
      ["chat", "tips"]
    )
    assert.equal(android.buttons[0].label, "Чат с поддержкой")
    assert.deepEqual(
      ios.buttons.map((b) => b.kind),
      ["chat", "tips"]
    )
    assert.equal(ios.buttons[0].label, "Чат с поддержкой")
  })

  it("cancelled / unknown: no CTAs", () => {
    assert.equal(orderStatusCtas({ status: "cancelled", os: "android" }).buttons.length, 0)
    assert.equal(orderStatusCtas({ status: "issued", os: "ios" }).buttons.length, 0)
  })
})

describe("orderStatusCtas (#41 step 3 ButtonMapper) [TDD-RED]", () => {
  it("paid ≡ accepted: cancel + Wallet (ios)", () => {
    const view = orderStatusCtas({
      status: "paid",
      os: "ios",
      canCancel: true,
      hasPushSubscription: false
    })
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["cancel", "wallet"]
    )
    assert.equal(view.buttons[0].label, "Отменить заказ")
    assert.equal(view.buttons[1].label, "Добавить в Wallet")
  })

  it("paid android: cancel + Включить Push", () => {
    const view = orderStatusCtas({
      status: "paid",
      os: "android",
      canCancel: true,
      hasPushSubscription: false
    })
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["cancel", "push"]
    )
    assert.equal(view.buttons[1].label, "Включить Push")
  })

  it("edge: preparing + !hasPushSubscription → chat + Push (android)", () => {
    const view = orderStatusCtas({
      status: "preparing",
      os: "android",
      hasPushSubscription: false
    })
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["chat", "push"]
    )
    assert.equal(view.buttons[0].label, "Чат с поддержкой")
    assert.equal(view.buttons[1].label, "Включить Push")
  })

  it("edge: preparing + !hasPushSubscription → chat + Wallet (ios)", () => {
    const view = orderStatusCtas({
      status: "preparing",
      os: "ios",
      hasPushSubscription: false
    })
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["chat", "wallet"]
    )
    assert.equal(view.buttons[1].label, "Добавить в Wallet")
  })

  it("edge: ready + !hasPushSubscription → chat + Push (android)", () => {
    const view = orderStatusCtas({
      status: "ready",
      os: "android",
      hasPushSubscription: false
    })
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["chat", "push"]
    )
    assert.equal(view.buttons[1].label, "Включить Push")
  })

  it("max 2 buttons always", () => {
    const view = orderStatusCtas({
      status: "accepted",
      os: "android",
      canCancel: true,
      hasPushSubscription: false
    })
    assert.ok(view.buttons.length <= 2)
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
