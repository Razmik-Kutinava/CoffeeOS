/**
 * #41 Шаг 7 [TDD-RED] — mobile touch targets ≥ 44px.
 *
 * node --test test/javascript/order_action_buttons_mobile_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import { ACTION_CTA_STYLE } from "../../app/frontend/lib/orderActionButtons.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const componentPath = join(
  root,
  "app/frontend/components/OrderActionButtons.svelte"
)

describe("ACTION_CTA_STYLE touch target (#41 step 7)", () => {
  it("min touch height is at least 44px", () => {
    assert.ok(
      ACTION_CTA_STYLE.heightPx >= 44,
      `expected heightPx >= 44, got ${ACTION_CTA_STYLE.heightPx}`
    )
  })
})

describe("OrderActionButtons mobile CSS (#41 step 7)", () => {
  it("buttons wrap text and stay within action column", () => {
    const src = readFileSync(componentPath, "utf8")
    assert.match(src, /min-height|heightPx/)
    assert.match(src, /white-space:\s*normal|word-break/)
    assert.match(src, /width:\s*100%/)
    assert.match(
      src,
      /@media[^{]*max-width:\s*767px|min-height:\s*44px|ACTION_CTA_STYLE\.heightPx/
    )
  })
})
