/**
 * TASK_110 — предварительный экран перед системным запросом уведомлений [TDD].
 *
 * Модуль `pushPrePrompt.js` — вызовами; карточка — SSR-рендером; панель и экран заказа —
 * по исходнику (экран грузит заказ в onMount, прецедент TASK_108 / TASK_109).
 *
 * node --test test/javascript/push_preprompt_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  PUSH_PREPROMPT_TITLE,
  PUSH_PREPROMPT_TEXT,
  PUSH_PREPROMPT_ACCEPT,
  PUSH_PREPROMPT_LATER,
  PUSH_PREPROMPT_MAX_DISMISSALS,
  PUSH_PREPROMPT_STORAGE_KEY,
  PUSH_CONSENT_EVENT_KINDS,
  isPrePromptStatus,
  shouldAutoShowPrePrompt,
  readPrePromptState,
  recordPrePromptDismissal,
  claimAutoPrePrompt,
  releaseAutoPrePrompt,
  currentNotificationPermission,
  permissionEventKind,
  reportPushConsentEvent,
  finishPrePromptAccept,
  __resetPrePromptForTests
} from "../../app/frontend/lib/pushPrePrompt.js"
import { renderSvelte } from "./svelte_ssr_helper.mjs"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const read = (p) => readFileSync(join(root, p), "utf8")
const accordionSrc = () => read("app/frontend/components/ActiveOrdersAccordion.svelte")
const screenSrc = () => read("app/frontend/routes/OrderStatus.svelte")
const cardPath = join(root, "app/frontend/components/PushPrePrompt.svelte")

function fnBody(src, signature) {
  const start = src.indexOf(signature)
  assert.ok(start > -1, `нет ${signature}`)
  return src.slice(start, src.indexOf("\n  }\n", start))
}

function memoryStorage(initial = {}) {
  const data = { ...initial }
  return {
    data,
    getItem: (k) => (k in data ? data[k] : null),
    setItem: (k, v) => {
      data[k] = String(v)
    },
    removeItem: (k) => {
      delete data[k]
    }
  }
}

const throwingStorage = {
  getItem() {
    throw new Error("SecurityError")
  },
  setItem() {
    throw new Error("SecurityError")
  }
}

const BASE = Object.freeze({
  status: "accepted",
  pushCtaShown: true,
  permission: "default",
  subscribed: false,
  recovery: false,
  orderId: "o-1",
  state: { dismissals: 0, lastDismissedOrderId: null }
})

function beaconSpy() {
  const sent = []
  return {
    sent,
    opts: {
      env: { navigator: { userAgent: "Mozilla/5.0 (Linux; Android 14)" } },
      resolveUrl: (u) => u,
      beacon: (url, blob) => {
        sent.push({ url, blob })
        return true
      }
    },
    async bodies() {
      return Promise.all(sent.map(async (s) => JSON.parse(await s.blob.text())))
    }
  }
}

beforeEach(() => {
  __resetPrePromptForTests()
})

describe("Subtask 13 — тексты константами", () => {
  it("точные строки заказчика", () => {
    assert.equal(PUSH_PREPROMPT_TITLE, "Уведомим, когда заказ будет готов")
    assert.equal(PUSH_PREPROMPT_TEXT, "Пришлём уведомление, как только бариста его соберёт")
    assert.equal(PUSH_PREPROMPT_ACCEPT, "Включить")
    assert.equal(PUSH_PREPROMPT_LATER, "Не сейчас")
  })

  it("лимит 3 и ключ хранилища — константы", () => {
    assert.equal(PUSH_PREPROMPT_MAX_DISMISSALS, 3)
    assert.equal(PUSH_PREPROMPT_STORAGE_KEY, "coffeeos_shop_push_preprompt_v1")
  })
})

describe("Subtask 1, 5, 7, 9, 10 — правило автопоказа", () => {
  it("accepted / paid / preparing, push-CTA есть, default, не подписан → показываем", () => {
    for (const status of ["accepted", "paid", "preparing"]) {
      assert.equal(shouldAutoShowPrePrompt({ ...BASE, status }), true, status)
    }
  })

  it("pending_payment, ready и прочие статусы — нет (Subtask 7, решение владельца)", () => {
    for (const status of ["pending_payment", "ready", "completed", "cancelled", ""]) {
      assert.equal(shouldAutoShowPrePrompt({ ...BASE, status }), false, status)
      assert.equal(isPrePromptStatus(status), false, status)
    }
    for (const status of ["accepted", "paid", "preparing"]) assert.equal(isPrePromptStatus(status), true)
  })

  it("permission granted / denied / unavailable — нет", () => {
    for (const permission of ["granted", "denied", "unavailable", undefined]) {
      assert.equal(shouldAutoShowPrePrompt({ ...BASE, permission }), false, String(permission))
    }
  })

  it("подписан, push-CTA не показан (pushPossible=false или Wallet), виден recovery — нет", () => {
    assert.equal(shouldAutoShowPrePrompt({ ...BASE, subscribed: true }), false)
    assert.equal(shouldAutoShowPrePrompt({ ...BASE, pushCtaShown: false }), false)
    assert.equal(shouldAutoShowPrePrompt({ ...BASE, recovery: true }), false)
  })

  it("на этом заказе уже закрывали — нет; на другом — да", () => {
    const state = { dismissals: 1, lastDismissedOrderId: "o-1" }
    assert.equal(shouldAutoShowPrePrompt({ ...BASE, state }), false)
    assert.equal(shouldAutoShowPrePrompt({ ...BASE, orderId: "o-2", state }), true)
  })

  it("Subtask 5: закрытий не меньше 3 — автопоказа нет", () => {
    const at = (dismissals) => ({ dismissals, lastDismissedOrderId: "old" })
    assert.equal(shouldAutoShowPrePrompt({ ...BASE, state: at(2) }), true)
    assert.equal(shouldAutoShowPrePrompt({ ...BASE, state: at(3) }), false)
    assert.equal(shouldAutoShowPrePrompt({ ...BASE, state: at(7) }), false)
  })
})

describe("Subtask 4, 6 — «Не сейчас» на устройстве", () => {
  it("запись: счётчик +1, id заказа; переживает перезагрузку (то же хранилище)", () => {
    const storage = memoryStorage()
    assert.deepEqual(readPrePromptState(storage), { dismissals: 0, lastDismissedOrderId: null })
    recordPrePromptDismissal("o-1", storage)
    __resetPrePromptForTests()
    assert.deepEqual(readPrePromptState(storage), { dismissals: 1, lastDismissedOrderId: "o-1" })
    assert.deepEqual(JSON.parse(storage.data[PUSH_PREPROMPT_STORAGE_KEY]), {
      dismissals: 1,
      lastDismissedOrderId: "o-1"
    })
  })

  it("три заказа «Не сейчас» → на четвёртом автопоказа нет", () => {
    const storage = memoryStorage()
    for (const id of ["o-1", "o-2", "o-3"]) {
      assert.equal(shouldAutoShowPrePrompt({ ...BASE, orderId: id, state: readPrePromptState(storage) }), true, id)
      recordPrePromptDismissal(id, storage)
    }
    assert.equal(shouldAutoShowPrePrompt({ ...BASE, orderId: "o-4", state: readPrePromptState(storage) }), false)
  })

  it("испорченная запись — как пустое состояние", () => {
    const storage = memoryStorage({ [PUSH_PREPROMPT_STORAGE_KEY]: "{oops" })
    assert.deepEqual(readPrePromptState(storage), { dismissals: 0, lastDismissedOrderId: null })
  })

  it("Subtask 6: хранилище бросает — не падает, состояние в памяти страницы", () => {
    assert.doesNotThrow(() => readPrePromptState(throwingStorage))
    assert.doesNotThrow(() => recordPrePromptDismissal("o-1", throwingStorage))
    assert.deepEqual(readPrePromptState(throwingStorage), { dismissals: 1, lastDismissedOrderId: "o-1" })
    assert.deepEqual(readPrePromptState(null), { dismissals: 1, lastDismissedOrderId: "o-1" })
  })

  it("Subtask 6: заблокированный геттер localStorage — без исключения", () => {
    const desc = Object.getOwnPropertyDescriptor(globalThis, "localStorage")
    Object.defineProperty(globalThis, "localStorage", {
      configurable: true,
      get() {
        throw new Error("SecurityError")
      }
    })
    try {
      assert.doesNotThrow(() => recordPrePromptDismissal("o-9"))
      assert.equal(readPrePromptState().lastDismissedOrderId, "o-9")
    } finally {
      if (desc) Object.defineProperty(globalThis, "localStorage", desc)
      else delete globalThis.localStorage
    }
  })
})

describe("Subtask 1 — одна карточка на экран при нескольких заказах", () => {
  it("автопоказ занимает первая строка, вторая ждёт, пока первая не размонтирована", () => {
    assert.equal(claimAutoPrePrompt("o-1"), true)
    assert.equal(claimAutoPrePrompt("o-2"), false)
    assert.equal(claimAutoPrePrompt("o-1"), true)
    releaseAutoPrePrompt("o-2")
    assert.equal(claimAutoPrePrompt("o-2"), false)
    releaseAutoPrePrompt("o-1")
    assert.equal(claimAutoPrePrompt("o-2"), true)
  })
})

describe("Subtask 12 — события воронки согласия", () => {
  it("6 видов событий", () => {
    assert.deepEqual([...PUSH_CONSENT_EVENT_KINDS], [
      "push_preprompt_shown",
      "push_preprompt_accept",
      "push_preprompt_later",
      "push_permission_granted",
      "push_permission_denied",
      "push_permission_default"
    ])
  })

  it("permission → вид события; без Notification — события нет", () => {
    assert.equal(permissionEventKind("granted"), "push_permission_granted")
    assert.equal(permissionEventKind("denied"), "push_permission_denied")
    assert.equal(permissionEventKind("default"), "push_permission_default")
    assert.equal(permissionEventKind("unavailable"), null)
  })

  it("currentNotificationPermission: нет API или геттер бросает → unavailable", () => {
    assert.equal(currentNotificationPermission({}), "unavailable")
    assert.equal(currentNotificationPermission({ Notification: { permission: "default" } }), "default")
    const env = {}
    Object.defineProperty(env, "Notification", {
      get() {
        throw new Error("boom")
      }
    })
    assert.equal(currentNotificationPermission(env), "unavailable")
  })

  it("отправка: снимок окружения с event_kind, без данных гостя", async () => {
    const spy = beaconSpy()
    assert.equal(reportPushConsentEvent("push_preprompt_shown", spy.opts), true)
    const [body] = await spy.bodies()
    assert.equal(spy.sent[0].url, "/shop/api/environment_events")
    assert.equal(body.event_kind, "push_preprompt_shown")
    assert.equal(body.os_family, "android")
    for (const key of ["customer_id", "user_id", "phone", "order_id", "orderId", "guest_id"]) {
      assert.equal(key in body, false, key)
    }
  })

  it("неизвестный вид — не отправляется; ошибка отправки работу не ломает", () => {
    const spy = beaconSpy()
    assert.equal(reportPushConsentEvent("session_open", spy.opts), false)
    assert.equal(spy.sent.length, 0)
    assert.doesNotThrow(() =>
      reportPushConsentEvent("push_preprompt_later", {
        ...spy.opts,
        beacon: () => {
          throw new Error("beacon boom")
        },
        fetchFn: () => {
          throw new Error("fetch boom")
        }
      })
    )
  })
})

describe("Subtask 3 — итог «Включить»", () => {
  it("default (окно закрыто) → как «Не сейчас» + событие push_permission_default", async () => {
    const storage = memoryStorage()
    const spy = beaconSpy()
    finishPrePromptAccept(
      { ok: false, error: "dismissed", notice: "Уведомления не включены" },
      { orderId: "o-1", storage, ...spy.opts, env: { ...spy.opts.env, Notification: { permission: "default" } } }
    )
    assert.deepEqual(readPrePromptState(storage), { dismissals: 1, lastDismissedOrderId: "o-1" })
    assert.deepEqual((await spy.bodies()).map((b) => b.event_kind), ["push_permission_default"])
  })

  it("denied → событие, «Не сейчас» не записывается (дальше recovery)", async () => {
    const storage = memoryStorage()
    const spy = beaconSpy()
    finishPrePromptAccept(
      { ok: false, error: "denied", openSettings: true },
      { orderId: "o-1", storage, ...spy.opts, env: { ...spy.opts.env, Notification: { permission: "denied" } } }
    )
    assert.equal(readPrePromptState(storage).dismissals, 0)
    assert.deepEqual((await spy.bodies()).map((b) => b.event_kind), ["push_permission_denied"])
  })

  it("granted → событие push_permission_granted; без Notification API — без события", async () => {
    const spy = beaconSpy()
    finishPrePromptAccept(
      { ok: true },
      { orderId: "o-1", storage: memoryStorage(), ...spy.opts, env: { ...spy.opts.env, Notification: { permission: "granted" } } }
    )
    finishPrePromptAccept({ ok: false, error: "network" }, { orderId: "o-1", storage: memoryStorage(), ...spy.opts })
    assert.deepEqual((await spy.bodies()).map((b) => b.event_kind), ["push_permission_granted"])
  })
})

describe("Subtask 2, 3, 11, 13 — карточка PushPrePrompt.svelte", () => {
  it("SSR: заголовок, пояснение, «Включить», «Не сейчас»", async () => {
    const html = await renderSvelte(cardPath, {})
    assert.match(html, /data-testid="push-preprompt"/)
    for (const text of [PUSH_PREPROMPT_TITLE, PUSH_PREPROMPT_TEXT, PUSH_PREPROMPT_ACCEPT, PUSH_PREPROMPT_LATER]) {
      assert.ok(html.includes(text), text)
    }
    assert.match(html, /data-testid="push-preprompt-accept"/)
    assert.match(html, /data-testid="push-preprompt-later"/)
  })

  it("SSR: состояние ожидания — кнопки заблокированы, «Подключаем…»", async () => {
    const html = await renderSvelte(cardPath, { pending: true })
    assert.match(html, /Подключаем…/)
    assert.equal((html.match(/disabled/g) || []).length >= 2, true)
  })

  it("встроенный блок: без fixed / absolute / z-index и без модального окна", () => {
    const src = readFileSync(cardPath, "utf8")
    assert.doesNotMatch(src, /position:\s*(fixed|absolute|sticky)|z-index|role="dialog"|aria-modal/)
    assert.match(src, /from "\.\.\/lib\/pushPrePrompt\.js"/)
  })
})

describe("Subtask 1–4, 9, 10 — панель заказов (ActiveOrdersAccordion)", () => {
  it("подключает карточку и модуль", () => {
    const src = accordionSrc()
    assert.match(src, /import PushPrePrompt from "\.\/PushPrePrompt\.svelte"/)
    assert.match(src, /from "\.\.\/lib\/pushPrePrompt\.js"/)
  })

  it("Subtask 2: push-CTA открывает карточку, системный запрос из onAction не вызывается", () => {
    const body = fnBody(accordionSrc(), "async function onAction")
    assert.match(body, /kind === "push"\)\s*\{\s*openPrePrompt\(\)\s*return\s*\}/)
    assert.doesNotMatch(body, /subscribeOrderPush/)
  })

  it("Subtask 3: «Включить» синхронно запускает прежний путь, событие — после запуска", () => {
    const src = accordionSrc()
    const accept = fnBody(src, "function onPrePromptAccept")
    const callAt = accept.indexOf('notify("push")')
    assert.ok(callAt > -1, "нет notify(\"push\")")
    assert.doesNotMatch(accept.slice(0, callAt), /await |setTimeout|import\(/)
    assert.ok(accept.indexOf('reportPushConsentEvent("push_preprompt_accept")') > callAt)
    const notify = fnBody(src, "async function notify")
    const beforeCall = notify.slice(0, notify.indexOf("await subscribeOrderPush("))
    assert.doesNotMatch(beforeCall.replace(/await downloadWalletPass\(/, ""), /await |setTimeout|import\(/)
    assert.match(notify, /finishPrePromptAccept\(result/)
  })

  it("Subtask 4: «Не сейчас» — запись на устройстве и событие", () => {
    const later = fnBody(accordionSrc(), "function onPrePromptLater")
    assert.match(later, /recordPrePromptDismissal\(orderId\)/)
    assert.match(later, /reportPushConsentEvent\("push_preprompt_later"\)/)
    assert.match(later, /prePromptOpen = false/)
  })

  it("Subtask 1: автопоказ по правилу, одна строка на экран, освобождение при размонтировании", () => {
    const src = accordionSrc()
    assert.match(src, /shouldAutoShowPrePrompt\(\{/)
    assert.match(src, /claimAutoPrePrompt\(orderId\)/)
    assert.match(src, /releaseAutoPrePrompt\(/)
    assert.match(src, /recovery: pushRecovery/)
  })

  it("Subtask 1: событие показа — при открытии карточки", () => {
    assert.match(fnBody(accordionSrc(), "function openPrePrompt"), /reportPushConsentEvent\("push_preprompt_shown"\)/)
  })

  it("Subtask 10: порядок — recovery, затем карточка, затем тост", () => {
    const src = accordionSrc()
    const recovery = src.indexOf("{#if pushRecovery}")
    const card = src.indexOf("{:else if prePromptOpen}")
    const toast = src.indexOf("{:else if toastMsg}")
    assert.ok(recovery > -1 && card > recovery && toast > card, `${recovery} ${card} ${toast}`)
    assert.match(src.slice(card, toast), /<PushPrePrompt/)
  })
})

describe("Subtask 2, 3, 8 — экран заказа (OrderStatus.svelte)", () => {
  it("баннера «Разрешить уведомления» больше нет, карточка подключена", () => {
    const src = screenSrc()
    assert.doesNotMatch(src, /Разрешить уведомления|Получайте статус заказа/)
    assert.match(src, /import PushPrePrompt from "\.\.\/components\/PushPrePrompt\.svelte"/)
  })

  it("Subtask 2: push-CTA открывает карточку", () => {
    assert.match(fnBody(screenSrc(), "async function onCtaClick"), /kind === "push"\)\s*\{\s*openPrePrompt\(\)\s*return\s*\}/)
  })

  it("Subtask 3: «Включить» синхронно вызывает enablePushNotifications, событие — после", () => {
    const accept = fnBody(screenSrc(), "function onPrePromptAccept")
    const callAt = accept.indexOf("enablePushNotifications()")
    assert.ok(callAt > -1)
    assert.doesNotMatch(accept.slice(0, callAt), /await |setTimeout|import\(/)
    assert.ok(accept.indexOf('reportPushConsentEvent("push_preprompt_accept")') > callAt)
  })

  it("Subtask 8: карточка только в accepted / paid / preparing, не при отмене", () => {
    const src = screenSrc()
    assert.match(src, /\{:else if prePromptOpen && isPrePromptStatus\(order\.status\) && !progress\.cancelled\}\s*<PushPrePrompt/)
  })

  it("Subtask 8: автопоказ по правилу при доступном push и одна карточка на экран", () => {
    const src = screenSrc()
    assert.match(src, /shouldAutoShowPrePrompt\(\{/)
    assert.match(src, /claimAutoPrePrompt\(/)
    assert.match(src, /releaseAutoPrePrompt\(/)
  })

  it("Subtask 8: итог «Включить» — через finishPrePromptAccept, автовызов при granted карточку не трогает", () => {
    const enable = fnBody(screenSrc(), "async function enablePushNotifications")
    assert.match(enable, /if \(!auto\)\s*\{[\s\S]*?finishPrePromptAccept\(result/)
  })

  it("Subtask 4: «Не сейчас» на экране — запись и событие", () => {
    const later = fnBody(screenSrc(), "function onPrePromptLater")
    assert.match(later, /recordPrePromptDismissal\(order\.id\)/)
    assert.match(later, /reportPushConsentEvent\("push_preprompt_later"\)/)
  })
})
