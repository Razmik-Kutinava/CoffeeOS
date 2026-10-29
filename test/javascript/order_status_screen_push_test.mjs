/**
 * TASK_109 — push на экране заказа `#/order/:id` и показ push-CTA по окружению [TDD].
 *
 * Экран грузит заказ в onMount — при SSR дальше скелета не идёт, поэтому экран
 * проверяется по исходнику (прецедент TASK_90 Патч 2 / TASK_108), машина — вызовом,
 * OrderActionButtons — SSR-рендером.
 *
 * node --test test/javascript/order_status_screen_push_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import { orderStatusCtas } from "../../app/frontend/lib/orderStatusCtaMachine.js"
import {
  subscribeOrderPush,
  PUSH_FAILED_TOAST
} from "../../app/frontend/lib/orderStatusNotifyActions.js"
import { renderSvelte } from "./svelte_ssr_helper.mjs"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const screenSrc = () => readFileSync(join(root, "app/frontend/routes/OrderStatus.svelte"), "utf8")
const accordionSrc = () =>
  readFileSync(join(root, "app/frontend/components/ActiveOrdersAccordion.svelte"), "utf8")
const buttonsPath = join(root, "app/frontend/components/OrderActionButtons.svelte")
const kinds = (view) => view.buttons.map((b) => b.kind)

function ctaCall(src) {
  return src.match(/orderStatusCtas\(\{[\s\S]*?\}\)/)?.[0] || ""
}

function fnBody(src, signature) {
  const start = src.indexOf(signature)
  assert.ok(start > -1, `нет ${signature}`)
  return src.slice(start, src.indexOf("\n  }\n", start))
}

const OFFER = {
  subscriptionOfferEnabled: true,
  secondCtaMode: "subscription",
  eligibleForSubscriptionOffer: true
}

describe("Subtask 0 — текущий push-сценарий экрана заказа", () => {
  // Переписан на RED (Subtask 6–7): подписка выключает push через showPushCta,
  // hasPushSubscription экран по-прежнему не передаёт — «Оформить подписку» не появляется.
  it("кнопка: экран передаёт showPushCta, подписку в машину не передаёт", () => {
    const call = ctaCall(screenSrc())
    assert.doesNotMatch(call, /hasPushSubscription/)
    assert.match(call, /showPushCta/)
  })

  it("баннер «Разрешить уведомления» и «Уведомления включены» после подписки", () => {
    const src = screenSrc()
    assert.match(src, /Разрешить уведомления/)
    assert.match(src, /\{:else if pushState === "registered"\}\s*<p class="push-ok" role="status">Уведомления включены<\/p>/)
  })

  // Переписан на RED (Subtask 2, 6): баннер учитывает окружение и подписку.
  it("баннер виден только при pushPossible и без подписки", () => {
    assert.match(
      screenSrc(),
      /\{:else if pushAvailable && pushPossible && !progress\.cancelled && !pushSubscribed\}/
    )
  })

  // Переписан на RED (Subtask 5): denied → блок восстановления.
  it("denied: экран переходит в состояние denied и показывает блок восстановления", () => {
    const src = screenSrc()
    assert.match(src, /result\.openSettings\)\s*\{\s*pushState = "denied"/)
    assert.match(src, /\{#if pushState === "denied" && !progress\.cancelled\}/)
  })

  it("автоподписка при granted на открытии экрана — с пометкой auto", () => {
    assert.match(
      screenSrc(),
      /Notification\.permission === "granted"\)\s*\{\s*enablePushNotifications\(\{ auto: true \}\)/
    )
  })

  // Переписан на RED (Subtask 5): итоговое сообщение даёт общий вход, экран его показывает.
  it("ошибка по нажатию — одно сообщение PUSH_FAILED_TOAST из общего входа (без флага)", async () => {
    const toasts = []
    const result = await subscribeOrderPush({
      onToast: (m) => toasts.push(m),
      storage: null,
      registerShopPushImpl: async () => ({ ok: false, reason: "no_notification_api" })
    })
    assert.equal(result.ok, false)
    assert.deepEqual(toasts, [PUSH_FAILED_TOAST])
    assert.match(fnBody(screenSrc(), "async function enablePushNotifications"), /pushErr = msg/)
  })

  it("push-CTA и баннер ведут в один обработчик enablePushNotifications", () => {
    const src = screenSrc()
    assert.match(src, /kind === "push"\)\s*\{\s*await enablePushNotifications\(\)/)
    assert.match(src, /onclick=\{\(\) => enablePushNotifications\(\)\}/)
  })
})

describe("Subtask 2–4, 6–7 — машина: showPushCta", () => {
  it("Subtask 2: showPushCta=false — push-CTA нет, место не заполняется", () => {
    const off = { os: "android", showPushCta: false }
    assert.deepEqual(kinds(orderStatusCtas({ ...off, status: "accepted", canCancel: true })), ["cancel"])
    assert.deepEqual(kinds(orderStatusCtas({ ...off, status: "accepted" })), [])
    assert.deepEqual(kinds(orderStatusCtas({ ...off, status: "preparing" })), ["chat"])
    assert.deepEqual(kinds(orderStatusCtas({ ...off, status: "ready" })), ["chat"])
  })

  it("Subtask 3: showPushCta по умолчанию true — как сейчас", () => {
    assert.deepEqual(kinds(orderStatusCtas({ status: "preparing", os: "android" })), ["chat", "push"])
    assert.deepEqual(
      kinds(orderStatusCtas({ status: "accepted", os: "android", canCancel: true, showPushCta: true })),
      ["cancel", "push"]
    )
  })

  it("Subtask 4: Wallet на iPhone параметром не затрагивается", () => {
    const ios = { os: "ios", walletAvailable: true, showPushCta: false }
    assert.deepEqual(kinds(orderStatusCtas({ ...ios, status: "accepted", canCancel: true })), ["cancel", "wallet"])
    assert.deepEqual(kinds(orderStatusCtas({ ...ios, status: "preparing" })), ["chat", "wallet"])
  })

  it("iPhone без Wallet + showPushCta=false — push скрыт", () => {
    assert.deepEqual(
      kinds(orderStatusCtas({ status: "preparing", os: "ios", walletAvailable: false, showPushCta: false })),
      ["chat"]
    )
  })

  it("Subtask 6–7: showPushCta=false ветку подписки не включает", () => {
    assert.deepEqual(
      kinds(orderStatusCtas({ status: "ready", os: "android", showPushCta: false, ...OFFER })),
      ["chat"]
    )
  })

  it("ветка подписки (hasPushSubscription) от showPushCta не зависит", () => {
    assert.deepEqual(
      kinds(orderStatusCtas({ status: "ready", os: "android", hasPushSubscription: true, showPushCta: false, ...OFFER })),
      ["chat", "subscription"]
    )
  })
})

describe("Subtask 2 — панель заказов: OrderActionButtons + ActiveOrdersAccordion", () => {
  it("OrderActionButtons SSR: showPushCta=false — push-кнопки нет, чат остаётся", async () => {
    const html = await renderSvelte(buttonsPath, { status: "preparing", os: "android", showPushCta: false })
    assert.doesNotMatch(html, /data-kind="push"/)
    assert.match(html, /data-kind="chat"/)
  })

  it("OrderActionButtons SSR: по умолчанию push-кнопка есть", async () => {
    const html = await renderSvelte(buttonsPath, { status: "preparing", os: "android" })
    assert.match(html, /data-kind="push"/)
  })

  it("аккордеон передаёт showPushCta по pushPossible, подписку — как раньше", () => {
    const src = accordionSrc()
    assert.match(src, /import \{[^}]*currentPushPossible[^}]*\} from "\.\.\/lib\/pushEnvironmentClass\.js"/)
    assert.match(src, /showPushCta=\{pushPossible\}/)
    assert.match(src, /hasPushSubscription=\{hasPushSubscription\}/)
  })
})

describe("Subtask 5 — экран заказа: общий вход и блок восстановления", () => {
  it("вход — subscribeOrderPush (статический импорт), registerShopPush экран не зовёт", () => {
    const src = screenSrc()
    assert.match(src, /import \{[^}]*subscribeOrderPush[^}]*\} from "\.\.\/lib\/orderStatusNotifyActions\.js"/)
    assert.doesNotMatch(src, /registerShopPush/)
    assert.match(src, /await subscribeOrderPush\(\{ onToast \}\)/)
  })

  it("инвариант TASK_99: до subscribeOrderPush нет await, setTimeout и динамического импорта", () => {
    const src = screenSrc()
    const enable = fnBody(src, "async function enablePushNotifications")
    const beforeCall = enable.slice(0, enable.indexOf("await subscribeOrderPush("))
    assert.doesNotMatch(beforeCall, /await |setTimeout|import\(/)
    const click = fnBody(src, "async function onCtaClick")
    const beforePush = click.slice(0, click.indexOf('kind === "push"'))
    assert.doesNotMatch(beforePush, /await |setTimeout|import\(/)
    assert.doesNotMatch(src, /import\(\s*["'][^"']*(orderStatusNotifyActions|firebasePush)/)
  })

  it("блок восстановления: текст запрета, «Открыть настройки» + инструкция, без «Смотреть готовность»", () => {
    const src = screenSrc()
    const block = src.slice(src.indexOf('{#if pushState === "denied"'), src.indexOf("{:else if pushAvailable"))
    assert.match(block, /data-testid="order-push-recovery"/)
    assert.match(block, /\{PUSH_DENIED_TOAST\}/)
    assert.match(block, /\{PUSH_OPEN_SETTINGS_CTA\}/)
    assert.match(block, /\{settingsFallback\}/)
    assert.doesNotMatch(src, /PUSH_WATCH_READINESS_CTA|Смотреть готовность/)
    assert.match(fnBody(src, "function onOpenSettingsClick"), /openNotificationSettings\(\)/)
  })

  it("dismissed (решение владельца) — «Уведомления не включены» у кнопки, без блока восстановления", () => {
    const enable = fnBody(screenSrc(), "async function enablePushNotifications")
    assert.match(enable, /\}\s*else\s*\{\s*pushState = "error"\s*if \(result\.notice\) pushErr = result\.notice/)
  })

  it("автоподписки после возврата из настроек на экране нет (Патч 1 TASK_90 — не scope)", () => {
    assert.doesNotMatch(screenSrc(), /resumePushAfterSettings|visibilitychange/)
  })
})

describe("Subtask 6, 8 — подписанный гость и автовызов", () => {
  it("Subtask 6: подписка = registered в сессии или флаг+granted (Android/desktop), push выключается", () => {
    const src = screenSrc()
    assert.match(src, /const pushPossible = currentPushPossible\(\)/)
    assert.match(src, /pushState === "registered"[\s\S]{0,120}resolveNotifyPrimaryInit\(/)
    assert.match(src, /showPushCta: pushPossible && !pushSubscribed/)
  })

  it("Subtask 8: автовызов без флага — без onToast (ничего не показывает), с флагом — лог", () => {
    assert.match(
      fnBody(screenSrc(), "async function enablePushNotifications"),
      /const onToast = auto && !diagOn\s*\?\s*undefined/
    )
  })

  it("Subtask 8: subscribeOrderPush без onToast при ошибке ничего не бросает и не показывает", async () => {
    const result = await subscribeOrderPush({
      storage: null,
      registerShopPushImpl: async () => Promise.reject(new Error("fcm down"))
    })
    assert.equal(result.ok, false)
    assert.equal(result.error, "network")
  })
})
