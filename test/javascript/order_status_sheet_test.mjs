/**
 * #35 Order status sticky sheet — RED [TDD].
 *
 * node --test test/javascript/order_status_sheet_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import {
  createOrderStatusSheetState,
  shouldScrollStatusList,
  applyCableEvent,
  applyReconnectOrders,
  mapReconnectError,
  SHEET_POINTER_POLICY,
  ORDER_STATUS_SHEET_MODES
} from "../../app/frontend/lib/orderStatusSheet.js"

describe("orderStatusSheet — modes + pointer policy (#35 A2)", () => {
  it("exports peek and hidden modes", () => {
    assert.equal(ORDER_STATUS_SHEET_MODES.PEEK, "peek")
    assert.equal(ORDER_STATUS_SHEET_MODES.HIDDEN, "hidden")
  })

  it("catalog clicks pass through outside sheet hit-area", () => {
    assert.equal(SHEET_POINTER_POLICY.catalogClicksPassThrough, true)
    assert.equal(SHEET_POINTER_POLICY.blockCatalogUnderSheet, false)
  })
})

describe("createOrderStatusSheetState (#35 A2)", () => {
  it("starts hidden with empty orders", () => {
    const state = createOrderStatusSheetState()
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.HIDDEN)
    assert.deepEqual(state.orders, [])
    assert.equal(state.connection, "idle")
  })

  it("setOrders with active orders opens peek", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([
      { id: "o1", status: "preparing", order_number: "N1" }
    ])
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.PEEK)
    assert.equal(state.orders.length, 1)
  })

  it("setOrders empty returns to hidden", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([{ id: "o1", status: "ready", order_number: "N1" }])
    state.setOrders([])
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.HIDDEN)
  })
})

describe("shouldScrollStatusList (#35 A2b)", () => {
  it("scroll off for 1–2 statuses", () => {
    assert.equal(shouldScrollStatusList([{ id: 1 }, { id: 2 }]), false)
    assert.equal(shouldScrollStatusList([{ id: 1 }]), false)
  })

  it("scroll on when more than 2 statuses", () => {
    assert.equal(
      shouldScrollStatusList([{ id: 1 }, { id: 2 }, { id: 3 }]),
      true
    )
  })
})

describe("applyCableEvent (#35 A1/A2)", () => {
  it("updates matching order status from cable payload", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([
      { id: "42", status: "accepted", order_number: "202607-42" }
    ])
    applyCableEvent(state, {
      type: "status_changed",
      order_id: "42",
      status: "preparing",
      order_number: "202607-42"
    })
    assert.equal(state.orders[0].status, "preparing")
  })

  it("ignores events for unknown orders", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([{ id: "1", status: "accepted", order_number: "A" }])
    applyCableEvent(state, {
      type: "status_changed",
      order_id: "999",
      status: "ready"
    })
    assert.equal(state.orders[0].status, "accepted")
    assert.equal(state.orders.length, 1)
  })

  it("removes order on issued/cancelled terminal status", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([
      { id: "42", status: "ready", order_number: "N" },
      { id: "7", status: "preparing", order_number: "M" }
    ])
    applyCableEvent(state, {
      type: "status_changed",
      order_id: "42",
      status: "issued"
    })
    assert.equal(state.orders.length, 1)
    assert.equal(state.orders[0].id, "7")
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.PEEK)
  })

  it("removes order on status=ready status_changed event", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([{ id: "42", status: "preparing", order_number: "N" }])

    applyCableEvent(state, {
      type: "status_changed",
      order_id: "42",
      status: "ready"
    })

    assert.equal(state.orders.length, 0)
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.HIDDEN)
  })
})

describe("reconnect refresh (#35 A3)", () => {
  it("applyReconnectOrders replaces list and peeks when non-empty", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([{ id: "old", status: "preparing", order_number: "OLD" }])
    applyReconnectOrders(state, [
      { id: "new", status: "ready", order_number: "NEW" }
    ])
    assert.equal(state.orders.length, 1)
    assert.equal(state.orders[0].id, "new")
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.PEEK)
  })

  it("mapReconnectError 404 → hide", () => {
    assert.equal(mapReconnectError(404), "hide")
  })

  it("mapReconnectError 500 → error with retry", () => {
    assert.equal(mapReconnectError(500), "error_retry")
  })

  it("marks connection lost then online", () => {
    const state = createOrderStatusSheetState()
    state.setConnection("lost")
    assert.equal(state.connection, "lost")
    state.setConnection("online")
    assert.equal(state.connection, "online")
  })
})
