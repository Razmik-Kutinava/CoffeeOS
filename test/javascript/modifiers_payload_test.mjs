import assert from "node:assert/strict"
import { buildModifierPayload } from "../../app/frontend/lib/modifiers.js"

const groups = [
  {
    id: "g1",
    modifier_type: "required",
    modifiers: [
      { id: "m1", name: "Обычный", price_change: 0 },
      { id: "m2", name: "По крепче", price_change: 10 }
    ]
  }
]

const { selected_modifiers, removed_modifiers } = buildModifierPayload(groups, { g1: "m2" })

assert.equal(selected_modifiers.length, 1)
assert.equal(selected_modifiers[0].name, "По крепче")
assert.equal(removed_modifiers.length, 1)
assert.equal(removed_modifiers[0].name, "Обычный")

console.log("modifiers_payload_test: OK")
