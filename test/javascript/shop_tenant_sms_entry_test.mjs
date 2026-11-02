/**
 * TASK_118 — SMS entry pin: не уводить с точки заказа на preferred;
 * закрытая точка → preferred + #/profile без ?order=.
 * node --test test/javascript/shop_tenant_sms_entry_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { resolveSmsEntryTenantNavigation } from "../../app/frontend/lib/shopTenantHeader.js"

describe("resolveSmsEntryTenantNavigation (TASK_118)", () => {
  it("without sms_entry → normal bootstrap", () => {
    assert.deepEqual(
      resolveSmsEntryTenantNavigation({
        smsEntry: false,
        currentAllowed: true,
        preferred: "point-b",
        currentId: "point-a",
        hash: "#/profile?order=1"
      }),
      { action: "normal" }
    )
  })

  it("sms_entry + current allowed → stay (do not follow preferred)", () => {
    assert.deepEqual(
      resolveSmsEntryTenantNavigation({
        smsEntry: true,
        currentAllowed: true,
        preferred: "point-b",
        currentId: "point-a",
        hash: "#/profile?order=42"
      }),
      { action: "stay" }
    )
  })

  it("sms_entry + current not allowed → preferred with #/profile without order", () => {
    assert.deepEqual(
      resolveSmsEntryTenantNavigation({
        smsEntry: true,
        currentAllowed: false,
        preferred: "point-b",
        currentId: "closed-a",
        hash: "#/profile?order=42"
      }),
      { action: "navigate", tenantId: "point-b", hash: "#/profile" }
    )
  })

  it("sms_entry + not allowed + no preferred → stay (no crash)", () => {
    assert.deepEqual(
      resolveSmsEntryTenantNavigation({
        smsEntry: true,
        currentAllowed: false,
        preferred: null,
        currentId: "closed-a",
        hash: "#/profile?order=42"
      }),
      { action: "stay" }
    )
  })
})
