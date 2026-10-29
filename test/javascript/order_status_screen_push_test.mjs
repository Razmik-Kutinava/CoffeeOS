/**
 * TASK_109 — push на экране заказа `#/order/:id` и показ push-CTA по окружению [TDD].
 *
 * Экран грузит заказ в onMount — при SSR дальше скелета не идёт, поэтому экран
 * проверяется по исходнику (прецедент TASK_90 Патч 2 / TASK_108), машина — вызовом.
 *
 * node --test test/javascript/order_status_screen_push_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import { orderStatusCtas } from "../../app/frontend/lib/orderStatusCtaMachine.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const screenSrc = () => readFileSync(join(root, "app/frontend/routes/OrderStatus.svelte"), "utf8")
const kinds = (view) => view.buttons.map((b) => b.kind)

function ctaCall(src) {
  return src.match(/orderStatusCtas\(\{[\s\S]*?\}\)/)?.[0] || ""
}

describe("Subtask 0 — текущий push-сценарий экрана заказа", () => {
  it("кнопка: экран не передаёт машине подписку → в preparing/ready push-CTA есть всегда", () => {
    assert.doesNotMatch(ctaCall(screenSrc()), /hasPushSubscription/)
    assert.deepEqual(kinds(orderStatusCtas({ status: "preparing", os: "android" })), ["chat", "push"])
    assert.deepEqual(kinds(orderStatusCtas({ status: "ready", os: "android" })), ["chat", "push"])
  })

  it("баннер «Разрешить уведомления» и «Уведомления включены» после подписки", () => {
    const src = screenSrc()
    assert.match(src, /Разрешить уведомления/)
    assert.match(src, /\{:else if pushState === "registered"\}\s*<p class="push-ok" role="status">Уведомления включены<\/p>/)
  })

  it("баннер виден, пока push не подключён в этой сессии (окружение и подписка не учитываются)", () => {
    assert.match(screenSrc(), /\{#if pushAvailable && !progress\.cancelled && pushState !== "registered"\}/)
  })

  it("denied: экран переходит в состояние denied без блока восстановления", () => {
    const src = screenSrc()
    assert.match(src, /result\.reason === "denied"\)\s*\{\s*pushState = "denied"/)
    assert.doesNotMatch(src, /PUSH_OPEN_SETTINGS_CTA|openNotificationSettings/)
  })

  it("автоподписка при granted на открытии экрана — с пометкой auto", () => {
    assert.match(
      screenSrc(),
      /Notification\.permission === "granted"\)\s*\{\s*enablePushNotifications\(\{ auto: true \}\)/
    )
  })

  it("ошибка по нажатию — одно сообщение PUSH_FAILED_TOAST (без флага диагностики)", () => {
    assert.match(screenSrc(), /PUSH_FAILED_TOAST/)
  })

  it("push-CTA и баннер ведут в один обработчик enablePushNotifications", () => {
    const src = screenSrc()
    assert.match(src, /kind === "push"\)\s*\{\s*await enablePushNotifications\(\)/)
    assert.match(src, /onclick=\{\(\) => enablePushNotifications\(\)\}/)
  })
})
