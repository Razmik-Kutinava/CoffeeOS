/**
 * #35 Order status sticky sheet + #63 Svelte 5 reactivity / dismiss UX.
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
  activeOrderIdsKey,
  SHEET_POINTER_POLICY,
  ORDER_STATUS_SHEET_MODES,
  dismissOrder,
  visibleOrders,
  shouldShowStatusSheetUi
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

describe("applyCableEvent (#35 A1/A2 + #63 immutable)", () => {
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

  it("#63 Subtask 1: replaces orders array reference (no in-place mutate)", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([{ id: "42", status: "accepted", order_number: "N" }])
    const before = state.orders
    applyCableEvent(state, {
      type: "status_changed",
      order_id: "42",
      status: "preparing"
    })
    assert.notEqual(state.orders, before)
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
    const before = state.orders
    applyCableEvent(state, {
      type: "status_changed",
      order_id: "42",
      status: "issued"
    })
    assert.notEqual(state.orders, before)
    assert.equal(state.orders.length, 1)
    assert.equal(state.orders[0].id, "7")
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.PEEK)
  })

  it("#63 Subtask 3: removes on closed via new array", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([{ id: "9", status: "ready", order_number: "C" }])
    const before = state.orders
    applyCableEvent(state, {
      type: "status_changed",
      order_id: "9",
      status: "closed"
    })
    assert.notEqual(state.orders, before)
    assert.equal(state.orders.length, 0)
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.HIDDEN)
  })

  it("updates preparing→ready in place (ready stays in sheet)", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([{ id: "42", status: "preparing", order_number: "N" }])

    applyCableEvent(state, {
      type: "status_changed",
      order_id: "42",
      status: "ready"
    })

    assert.equal(state.orders.length, 1)
    assert.equal(state.orders[0].status, "ready")
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.PEEK)
  })
})

describe("reconnect refresh (#35 A3 + #63 Subtask 2)", () => {
  it("applyReconnectOrders keeps ready orders in sheet", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([{ id: "old", status: "preparing", order_number: "OLD" }])
    const before = state.orders
    applyReconnectOrders(state, [
      { id: "new", status: "ready", order_number: "NEW" }
    ])
    assert.notEqual(state.orders, before)
    assert.equal(state.orders.length, 1)
    assert.equal(state.orders[0].status, "ready")
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.PEEK)
  })

  it("activeOrderIdsKey is order-independent stable", () => {
    assert.equal(
      activeOrderIdsKey([{ id: "b" }, { id: "a" }]),
      activeOrderIdsKey([{ order_id: "a" }, { id: "b" }])
    )
    assert.equal(activeOrderIdsKey([]), "")
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

describe("#63 dismiss + route visibility", () => {
  it("Subtask 5/14: dismissOrder sets userDismissed only for that id", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([
      { id: "a", status: "preparing", order_number: "A" },
      { id: "b", status: "accepted", order_number: "B" }
    ])
    dismissOrder(state, "a")
    assert.equal(state.orders[0].userDismissed, true)
    assert.equal(state.orders[1].userDismissed, false)
    assert.deepEqual(
      visibleOrders(state.orders).map((o) => o.id),
      ["b"]
    )
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.PEEK)
  })

  it("Subtask 6/11: cable updates dismissed order; UI stays hidden for it", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([{ id: "42", status: "preparing", order_number: "N" }])
    dismissOrder(state, "42")
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.HIDDEN)

    applyCableEvent(state, {
      type: "status_changed",
      order_id: "42",
      status: "ready"
    })
    assert.equal(state.orders[0].status, "ready")
    assert.equal(state.orders[0].userDismissed, true)
    assert.equal(visibleOrders(state.orders).length, 0)
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.HIDDEN)
  })

  it("preserves userDismissed across reconnect sync", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([{ id: "42", status: "preparing", order_number: "N" }])
    dismissOrder(state, "42")
    applyReconnectOrders(state, [
      { id: "42", status: "preparing", order_number: "N" }
    ])
    assert.equal(state.orders[0].userDismissed, true)
    assert.equal(state.mode, ORDER_STATUS_SHEET_MODES.HIDDEN)
  })

  it("Subtask 7–10/15: shouldShowStatusSheetUi by route + pay stack", () => {
    const orders = [{ id: "1", status: "preparing" }]
    assert.equal(
      shouldShowStatusSheetUi({ hash: "#/", orders }),
      true
    )
    assert.equal(
      shouldShowStatusSheetUi({ hash: "#/category/2", orders }),
      true
    )
    assert.equal(
      shouldShowStatusSheetUi({ hash: "#/product/99", orders }),
      false
    )
    assert.equal(
      shouldShowStatusSheetUi({ hash: "#/profile", orders }),
      false
    )
    assert.equal(
      shouldShowStatusSheetUi({ hash: "#/checkout", orders }),
      false
    )
    assert.equal(
      shouldShowStatusSheetUi({ hash: "#/", orders, payStackActive: true }),
      false
    )
    assert.equal(
      shouldShowStatusSheetUi({
        hash: "#/",
        orders: [{ id: "1", userDismissed: true }]
      }),
      false
    )
  })
})
