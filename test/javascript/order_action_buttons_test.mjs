/**
 * #41 Шаг 4 [TDD-RED] — статический рендер OrderActionButtons.
 *
 * node --test test/javascript/order_action_buttons_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync, existsSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import { orderStatusCtas } from "../../app/frontend/lib/orderStatusCtaMachine.js"
import {
  ACTION_CTA_STYLE,
  ORDER_ACTION_TEST_IDS
} from "../../app/frontend/lib/orderActionButtons.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const componentPath = join(
  root,
  "app/frontend/components/OrderActionButtons.svelte"
)
const accordionPath = join(
  root,
  "app/frontend/components/ActiveOrdersAccordion.svelte"
)

describe("ACTION_CTA_STYLE (#41 step 4)", () => {
  it("uses mockup accent #ff6b35 (not legacy #ff8c42)", () => {
    assert.equal(ACTION_CTA_STYLE.background, "#ff6b35")
    assert.equal(ACTION_CTA_STYLE.color, "#ffffff")
    assert.ok(ACTION_CTA_STYLE.borderRadius)
    assert.equal(ACTION_CTA_STYLE.actionsClass, "oab__actions")
    assert.equal(ACTION_CTA_STYLE.buttonClass, "oab__btn")
  })

  it("exposes stable data-testid ids", () => {
    assert.equal(ORDER_ACTION_TEST_IDS.root, "order-action-buttons")
    assert.equal(ORDER_ACTION_TEST_IDS.button, "order-action-btn")
  })
})

describe("static matrix paid + ios (#41 step 4)", () => {
  it("renders config: Отменить заказ + Карта в Apple Wallet", () => {
    const view = orderStatusCtas({
      status: "paid",
      os: "ios",
      canCancel: true,
      hasPushSubscription: false
    })
    assert.equal(view.buttons.length, 2)
    assert.equal(view.buttons[0].label, "Отменить заказ")
    assert.equal(view.buttons[1].label, "Карта в Apple Wallet")
    assert.deepEqual(
      view.buttons.map((b) => b.kind),
      ["cancel", "wallet"]
    )
  })
})

describe("OrderActionButtons.svelte markup (#41 step 4)", () => {
  it("component file exists with testids, accent, and mapper wire", () => {
    assert.equal(existsSync(componentPath), true, "OrderActionButtons.svelte missing")
    const src = readFileSync(componentPath, "utf8")
    assert.match(src, /orderStatusCtas/)
    assert.match(src, /ACTION_CTA_STYLE|orderActionButtons/)
    assert.match(src, /data-testid=\{ORDER_ACTION_TEST_IDS\.root\}|data-testid=["']order-action-buttons["']/)
    assert.match(src, /data-testid=\{ORDER_ACTION_TEST_IDS\.button\}|data-testid=["']order-action-btn["']/)
    assert.match(src, /ACTION_CTA_STYLE\.background|style:background/)
    const styleSrc = readFileSync(
      join(root, "app/frontend/lib/orderActionButtons.js"),
      "utf8"
    )
    assert.match(styleSrc, /#ff6b35/)
  })
})

describe("ActiveOrdersAccordion wires OrderActionButtons (#41 step 4)", () => {
  it("imports OrderActionButtons for the right-side action column", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /OrderActionButtons/)
  })
})
