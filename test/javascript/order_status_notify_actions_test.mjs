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
  notifyActionsView
} from "../../app/frontend/lib/orderStatusNotifyActions.js"

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

describe("ActiveOrdersAccordion wires notify CTAs (#37 step 2)", () => {
  it("imports notifyActionsView and drops stub placeholders", () => {
    const src = readFileSync(accordionPath, "utf8")
    assert.match(src, /orderStatusNotifyActions/)
    assert.match(src, /notifyActionsView/)
    assert.match(src, /Состав заказа/)
    assert.match(src, /aoa__cta/)
    assert.doesNotMatch(src, /кнопка с текстом/)
    assert.match(src, /#ff8c42/)
  })
})
