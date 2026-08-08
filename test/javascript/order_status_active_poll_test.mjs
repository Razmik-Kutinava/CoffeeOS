/**
 * #47 — polling + visibility для /orders/active + refresh frequent [TDD RED].
 *
 * node --test test/javascript/order_status_active_poll_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, mock } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const sheetPath = join(root, "app/frontend/components/OrderStatusSheet.svelte")
const libPath = join(root, "app/frontend/lib/orderStatusSheet.js")

describe("#47 G1/G2 — OrderStatusSheet source: poll + visibility", () => {
  it("wires visibilitychange to refresh active orders (not only window online)", () => {
    const src = readFileSync(sheetPath, "utf8")
    assert.match(
      src,
      /visibilitychange/,
      "G2: при возврате на вкладку нужен refresh без F5"
    )
  })

  it("starts interval poll while mounted (ACTIVE_ORDERS_POLL or setInterval)", () => {
    const src = readFileSync(sheetPath, "utf8")
    const hasPoll =
      /ACTIVE_ORDERS_POLL_MS/.test(src) ||
      /startActiveOrdersPolling/.test(src) ||
      /setInterval\s*\(/.test(src)
    assert.equal(
      hasPoll,
      true,
      "G1: нужен polling /orders/active пока sheet mounted"
    )
  })

  it("refreshActive also refreshes frequent products (G3)", () => {
    const src = readFileSync(sheetPath, "utf8")
    const start = src.indexOf("async function refreshActive")
    assert.ok(start >= 0, "refreshActive must exist")
    const nextFn = src.indexOf("\n  function ", start + 1)
    const body = src.slice(start, nextFn > start ? nextFn : start + 800)
    assert.match(
      body,
      /refreshFrequentProducts\s*\(/,
      "G3: внутри refreshActive — refreshFrequentProducts (не только cancel/terminal)"
    )
  })
})

describe("#47 — orderStatusSheet poll helpers", () => {
  it("exports ACTIVE_ORDERS_POLL_MS in catalog-like range (5–15s)", async () => {
    const mod = await import("../../app/frontend/lib/orderStatusSheet.js")
    assert.equal(typeof mod.ACTIVE_ORDERS_POLL_MS, "number")
    assert.ok(
      mod.ACTIVE_ORDERS_POLL_MS >= 5_000 && mod.ACTIVE_ORDERS_POLL_MS <= 15_000,
      `expected 5–15s, got ${mod.ACTIVE_ORDERS_POLL_MS}`
    )
  })

  it("startActiveOrdersPolling ticks onTick and stop clears timer", async () => {
    const mod = await import("../../app/frontend/lib/orderStatusSheet.js")
    assert.equal(typeof mod.startActiveOrdersPolling, "function")
    assert.equal(typeof mod.stopActiveOrdersPolling, "function")

    mock.timers.enable({ apis: ["setInterval", "clearInterval"] })
    try {
      let ticks = 0
      mod.startActiveOrdersPolling(() => {
        ticks += 1
      })
      mock.timers.tick(mod.ACTIVE_ORDERS_POLL_MS)
      mock.timers.tick(mod.ACTIVE_ORDERS_POLL_MS)
      assert.ok(ticks >= 2, `expected ≥2 ticks, got ${ticks}`)
      mod.stopActiveOrdersPolling()
      const afterStop = ticks
      mock.timers.tick(mod.ACTIVE_ORDERS_POLL_MS)
      assert.equal(ticks, afterStop, "after stop — no more ticks")
    } finally {
      mock.timers.reset()
      try {
        mod.stopActiveOrdersPolling()
      } catch {
        /* */
      }
    }
  })

  it("lib documents poll export for Sheet wiring", () => {
    const src = readFileSync(libPath, "utf8")
    assert.match(src, /ACTIVE_ORDERS_POLL_MS/)
    assert.match(src, /startActiveOrdersPolling/)
    assert.match(src, /stopActiveOrdersPolling/)
  })
})
