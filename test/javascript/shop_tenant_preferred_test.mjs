/**
 * resolvePreferredTenantId — sticky vs last_ordered (рекомендации / повторить).
 * node --test test/javascript/shop_tenant_preferred_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { resolvePreferredTenantId } from "../../app/frontend/lib/shopTenantHeader.js"

describe("resolvePreferredTenantId", () => {
  it("prefers selected when present and allowed", () => {
    assert.equal(
      resolvePreferredTenantId({
        selectedId: "fly-overnight",
        lastOrderedId: "point-a",
        switchableIds: ["fly-overnight", "point-a"]
      }),
      "fly-overnight"
    )
  })

  it("falls back to last_ordered when selected is inactive / missing", () => {
    assert.equal(
      resolvePreferredTenantId({
        selectedId: "fly-overnight",
        lastOrderedId: "point-a",
        switchableIds: ["point-a", "point-b"]
      }),
      "point-a"
    )
  })

  it("uses last_ordered when no selected", () => {
    assert.equal(
      resolvePreferredTenantId({
        selectedId: null,
        lastOrderedId: "point-a",
        switchableIds: ["point-a"]
      }),
      "point-a"
    )
  })

  it("returns null when nothing known", () => {
    assert.equal(resolvePreferredTenantId({}), null)
  })
})
