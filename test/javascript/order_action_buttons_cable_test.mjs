/**
 * #41 Шаг 5 [TDD-RED] — CTA swap при ActionCable status_changed.
 *
 * node --test test/javascript/order_action_buttons_cable_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  createOrderStatusSheetState,
  applyCableEvent
} from "../../app/frontend/lib/orderStatusSheet.js"
import { orderStatusCtas } from "../../app/frontend/lib/orderStatusCtaMachine.js"
import { accordionRowView } from "../../app/frontend/lib/activeOrdersAccordion.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const sheetPath = join(root, "app/frontend/lib/orderStatusSheet.js")
const accordionComponentPath = join(
  root,
  "app/frontend/components/ActiveOrdersAccordion.svelte"
)
const sheetComponentPath = join(
  root,
  "app/frontend/components/OrderStatusSheet.svelte"
)

function ctasForOrder(order, opts = {}) {
  return orderStatusCtas({
    status: order.status,
    os: opts.os || "android",
    canCancel: Boolean(order.can_cancel),
    hasPushSubscription: Boolean(opts.hasPushSubscription)
  })
}

describe("cable → CTA swap (#41 step 5)", () => {
  it("paid→preparing: cancel disappears, chat+push appear", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([
      {
        id: "42",
        status: "paid",
        can_cancel: true,
        order_number: "202608-42"
      }
    ])

    const before = ctasForOrder(state.orders[0], { hasPushSubscription: false })
    assert.deepEqual(
      before.buttons.map((b) => b.kind),
      ["cancel", "push"]
    )

    applyCableEvent(state, {
      type: "status_changed",
      order_id: "42",
      status: "preparing",
      can_cancel: false
    })

    const after = ctasForOrder(state.orders[0], { hasPushSubscription: false })
    assert.deepEqual(
      after.buttons.map((b) => b.kind),
      ["chat", "push"]
    )
    assert.ok(!after.buttons.some((b) => b.kind === "cancel"))
  })

  it("applyCableEvent patches can_cancel from payload", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([
      { id: "7", status: "accepted", can_cancel: true, order_number: "A" }
    ])

    applyCableEvent(state, {
      type: "status_changed",
      order_id: "7",
      status: "preparing",
      can_cancel: false
    })

    assert.equal(state.orders[0].status, "preparing")
    assert.equal(
      state.orders[0].can_cancel,
      false,
      "can_cancel must follow cable payload so sticky CTA stays consistent"
    )
  })

  it("progress bar marks preparing as current after cable", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([
      { id: "9", status: "paid", can_cancel: true, order_number: "P" }
    ])
    applyCableEvent(state, {
      type: "status_changed",
      order_id: "9",
      status: "preparing"
    })

    const row = accordionRowView(state.orders[0], null)
    assert.equal(row.showProgress, true)
    const preparing = row.steps.find((s) => s.id === "preparing" || s.label === "Готовится")
    assert.ok(preparing, "ожидается шаг Готовится")
    assert.equal(preparing.state, "current")
    assert.ok(row.fillPercent >= 50)
  })
})

describe("wiring sticky panel (#41 step 5)", () => {
  it("orderStatusSheet.applyCableEvent merges can_cancel", () => {
    const src = readFileSync(sheetPath, "utf8")
    assert.match(src, /can_cancel/)
  })

  it("ActiveOrdersAccordion binds status into OrderActionButtons", () => {
    const src = readFileSync(accordionComponentPath, "utf8")
    assert.match(src, /OrderActionButtons/)
    assert.match(src, /status=\{status\}|status=\{.*status/)
  })

  it("OrderStatusSheet syncs after cable without full page reload helpers", () => {
    const src = readFileSync(sheetComponentPath, "utf8")
    assert.match(src, /applyCableEvent/)
    assert.match(src, /sync\(\)/)
    assert.doesNotMatch(src, /location\.reload/)
  })
})
