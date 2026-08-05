/**
 * #37 Шаг 2 — верстка CTA в аккордеоне [RED / TDD].
 *
 * node --test test/javascript/order_status_notify_actions_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  CTA_STYLE,
  notifyActionsView,
  openOrderReceipt
} from "../../app/frontend/lib/orderStatusNotifyActions.js"
import {
  createActiveOrdersAccordionState
} from "../../app/frontend/lib/activeOrdersAccordion.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const accordionPath = join(
  root,
  "app/frontend/components/ActiveOrdersAccordion.svelte"
)

describe("CTA_STYLE kit tokens (#37 step 2)", () => {
  it("uses project accent #ff8c42 and h-9 / rounded-lg tokens", () => {
    assert.equal(CTA_STYLE.background, "#ff8c42")
    assert.equal(CTA_STYLE.color, "#000000")
    assert.equal(CTA_STYLE.fontWeight, 600)
    assert.equal(CTA_STYLE.heightPx, 36)
    assert.equal(CTA_STYLE.borderRadius, "0.5rem")
    assert.equal(CTA_STYLE.fontSizeRem, 0.75)
    assert.equal(CTA_STYLE.actionsWidthRem, 11)
    assert.equal(CTA_STYLE.actionsGapRem, 0.5)
  })
})

describe("notifyActionsView by OS (#37 step 2)", () => {
  it("ios → Wallet primary + Состав заказа secondary", () => {
    const view = notifyActionsView({ os: "ios" })
    assert.equal(view.primaryKind, "wallet")
    assert.match(view.primaryLabel, /Карта в Apple Wallet/)
    assert.equal(view.secondaryLabel, "Состав заказа")
  })

  it("android → Push primary + Состав заказа", () => {
    const view = notifyActionsView({ os: "android" })
    assert.equal(view.primaryKind, "push")
    assert.match(view.primaryLabel, /Уведомление о готовности/)
    assert.equal(view.secondaryLabel, "Состав заказа")
  })

  it("desktop → same Push CTA as android", () => {
    const view = notifyActionsView({ os: "desktop" })
    assert.equal(view.primaryKind, "push")
    assert.match(view.primaryLabel, /Уведомление о готовности/)
    assert.equal(view.secondaryLabel, "Состав заказа")
  })

  it("exposes actions/button class hooks for scoped CSS", () => {
    const view = notifyActionsView({ os: "ios" })
    assert.equal(view.actionsClass, "aoa__actions")
    assert.equal(view.buttonClass, "aoa__cta")
    assert.equal(view.style.background, "#ff8c42")
  })
})

describe("ActiveOrdersAccordion wires notify CTAs (#37 step 2 / #41)", () => {
  it("imports OrderActionButtons; receipt via chevron (no stub placeholders)", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /OrderActionButtons/)
    assert.match(src, /aoa__chevron|onToggle/)
    assert.doesNotMatch(src, /кнопка с текстом/)
  })
})

describe("openOrderReceipt (#37 step 3)", () => {
  it("toggles accordion expand and keeps isLoading false", () => {
    const state = createActiveOrdersAccordionState([
      { id: "o1", order_number: "1", status: "preparing" }
    ])
    const ui = { isLoading: false }
    const result = openOrderReceipt(state, "o1", ui)

    assert.equal(state.activeExpandedOrderId, "o1")
    assert.equal(result.isLoading, false)
    assert.equal(ui.isLoading, false)
  })

  it("second click collapses without loading", () => {
    const state = createActiveOrdersAccordionState([{ id: "o1" }])
    openOrderReceipt(state, "o1", { isLoading: false })
    const result = openOrderReceipt(state, "o1", { isLoading: false })

    assert.equal(state.activeExpandedOrderId, null)
    assert.equal(result.isLoading, false)
  })

  it("ActiveOrdersAccordion wires receipt toggle via chevron", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /toggleExpandedOrder|onToggle/)
    assert.match(src, /aoa__chevron|active-order-receipt/)
  })
})
