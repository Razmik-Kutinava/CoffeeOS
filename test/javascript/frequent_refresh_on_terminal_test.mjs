/**
 * Quick Repeat ревизия — F3: после terminal Cable (#35) обновить frequent.
 *
 * node --test test/javascript/frequent_refresh_on_terminal_test.mjs
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

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")

describe("F3 — refresh frequent on terminal status (source contract)", () => {
  it("OrderStatusSheet calls refreshFrequentProducts after cable status", () => {
    const src = readFileSync(
      join(root, "app/frontend/components/OrderStatusSheet.svelte"),
      "utf8"
    )
    assert.match(
      src,
      /refreshFrequentProducts/,
      "после status_changed (в т.ч. issued/cancelled) нужен refresh frequent"
    )
  })

  it("App visibilitychange already restores guest (includes frequent refresh)", () => {
    const src = readFileSync(join(root, "app/frontend/App.svelte"), "utf8")
    assert.match(src, /visibilitychange/)
    assert.match(src, /restoreGuestSession/)
  })
})

describe("F3 — applyCableEvent terminal hook", () => {
  it("invokes onTerminal when order reaches issued/cancelled", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([{ id: "42", status: "ready", order_number: "N" }])
    let called = 0
    applyCableEvent(
      state,
      { type: "status_changed", order_id: "42", status: "issued" },
      { onTerminal: () => { called += 1 } }
    )
    assert.equal(called, 1, "onTerminal должен вызваться при terminal status")
    assert.equal(state.orders.length, 0)
  })

  it("does not invoke onTerminal for ready (stays in sheet)", () => {
    const state = createOrderStatusSheetState()
    state.setOrders([{ id: "42", status: "preparing", order_number: "N" }])
    let called = 0
    applyCableEvent(
      state,
      { type: "status_changed", order_id: "42", status: "ready" },
      { onTerminal: () => { called += 1 } }
    )
    assert.equal(called, 0)
    assert.equal(state.orders[0].status, "ready")
  })
})
