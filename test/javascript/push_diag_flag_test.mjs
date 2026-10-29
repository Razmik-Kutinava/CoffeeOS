/**
 * TASK_108 — диагностика push только по флагу [TDD].
 *
 * node --test test/javascript/push_diag_flag_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, afterEach } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import { registerShopPush } from "../../app/frontend/lib/firebasePush.js"
import * as notifyActions from "../../app/frontend/lib/orderStatusNotifyActions.js"

const { subscribeOrderPush, PUSH_DENIED_TOAST, PUSH_NOT_ENABLED_TOAST } = notifyActions
const flag = await import("../../app/frontend/lib/pushDiagFlag.js").catch(() => ({}))

const FAILED_TEXT = "Не удалось включить уведомления. Попробуйте ещё раз"
const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const orderStatusSrc = () => readFileSync(join(root, "app/frontend/routes/OrderStatus.svelte"), "utf8")
const accordionSrc = () =>
  readFileSync(join(root, "app/frontend/components/ActiveOrdersAccordion.svelte"), "utf8")

function memoryStorage(initial = {}) {
  const data = { ...initial }
  return {
    data,
    getItem: (k) => (Object.prototype.hasOwnProperty.call(data, k) ? data[k] : null),
    setItem: (k, v) => {
      data[k] = String(v)
    },
    removeItem: (k) => {
      delete data[k]
    }
  }
}

function brokenStorage() {
  return {
    getItem: () => {
      throw new Error("SecurityError")
    },
    setItem: () => {
      throw new Error("QuotaExceededError")
    },
    removeItem: () => {
      throw new Error("SecurityError")
    }
  }
}

function installNotification(permission, calls = []) {
  const Notification = {
    permission: "default",
    requestPermission: () => {
      calls.push("requestPermission")
      return Promise.resolve(permission)
    }
  }
  globalThis.window = { Notification }
  globalThis.Notification = Notification
}

function removeNotification() {
  delete globalThis.window
  delete globalThis.Notification
}

function deps(calls, overrides = {}) {
  return {
    isSupported: async () => {
      calls.push("isSupported")
      return true
    },
    firebaseClientConfigured: () => {
      calls.push("firebaseClientConfigured")
      return true
    },
    getToken: async () => {
      calls.push("getToken")
      return "tok-108"
    },
    registerToken: async (token) => {
      calls.push(`registerToken:${token}`)
    },
    ...overrides
  }
}

const isTechnical = (msg) => /registerShopPush|requestPermission|шаг|getToken|isSupported|^\d+:/m.test(msg)

afterEach(() => {
  removeNotification()
  if (typeof flag.setPushDiagEnabled === "function") flag.setPushDiagEnabled(false)
})

describe("pushDiagFlag — флаг и хранилище (Subtask 5–7)", () => {
  it("по умолчанию выключен", () => {
    assert.equal(typeof flag.isPushDiagEnabled, "function")
    assert.equal(flag.isPushDiagEnabled({ storage: memoryStorage() }), false)
  })

  it("Subtask 6: включённый флаг переживает перезапуск (читается из того же localStorage)", () => {
    const storage = memoryStorage()
    flag.setPushDiagEnabled(true, { storage })
    assert.equal(storage.data[flag.PUSH_DIAG_STORAGE_KEY], "1")
    assert.equal(flag.isPushDiagEnabled({ storage: memoryStorage(storage.data) }), true)
  })

  it("Subtask 5/6: togglePushDiag включает и выключает", () => {
    const storage = memoryStorage()
    assert.equal(flag.togglePushDiag({ storage }), true)
    assert.equal(flag.isPushDiagEnabled({ storage }), true)
    assert.equal(flag.togglePushDiag({ storage }), false)
    assert.equal(flag.isPushDiagEnabled({ storage }), false)
  })

  it("Subtask 6/7: недоступное хранилище — без исключений, флаг живёт в памяти страницы", () => {
    const storage = brokenStorage()
    assert.doesNotThrow(() => flag.isPushDiagEnabled({ storage }))
    assert.equal(flag.isPushDiagEnabled({ storage }), false)
    assert.doesNotThrow(() => flag.togglePushDiag({ storage }))
    assert.equal(flag.isPushDiagEnabled({ storage }), true)
    assert.equal(flag.togglePushDiag({ storage }), false)
  })

  it("Subtask 7: без localStorage в окружении — без исключений", () => {
    assert.doesNotThrow(() => flag.isPushDiagEnabled())
    assert.doesNotThrow(() => flag.setPushDiagEnabled(true))
    assert.equal(flag.isPushDiagEnabled(), true)
  })

  it("Subtask 5: короткое подтверждение для обоих состояний", () => {
    assert.equal(flag.pushDiagToggleText(true), "Диагностика уведомлений включена")
    assert.equal(flag.pushDiagToggleText(false), "Диагностика уведомлений выключена")
  })
})

describe("pushDiagFlag — скрытый жест (Subtask 5, 8)", () => {
  function clock() {
    let t = 1_000
    return { now: () => t, advance: (ms) => (t += ms) }
  }

  it("решение владельца: 7 нажатий за 3 секунды", () => {
    assert.deepEqual({ ...flag.PUSH_DIAG_GESTURE }, { taps: 7, windowMs: 3000 })
  })

  it("срабатывает на 7-м нажатии в окне и сбрасывает счётчик", () => {
    const c = clock()
    const g = flag.createTapGesture({ ...flag.PUSH_DIAG_GESTURE, now: c.now })
    const out = []
    for (let i = 0; i < 7; i += 1) {
      out.push(g.tap())
      c.advance(300)
    }
    assert.deepEqual(out, [false, false, false, false, false, false, true])
    assert.equal(g.tap(), false)
  })

  it("Subtask 8: обычные нажатия не включают — 6 нажатий или 7 дольше 3 с", () => {
    const c = clock()
    const g = flag.createTapGesture({ ...flag.PUSH_DIAG_GESTURE, now: c.now })
    for (let i = 0; i < 6; i += 1) assert.equal(g.tap(), false)
    c.advance(5000)
    const slow = flag.createTapGesture({ ...flag.PUSH_DIAG_GESTURE, now: c.now })
    const out = []
    for (let i = 0; i < 7; i += 1) {
      out.push(slow.tap())
      c.advance(600)
    }
    assert.ok(!out.includes(true))
  })
})

describe("registerShopPush — лог шагов только по флагу (Subtask 1, 3, 9)", () => {
  it("Subtask 1: флаг выключен — onToast не получает технических строк", async () => {
    const calls = []
    const toasts = []
    installNotification("granted", calls)
    await assert.rejects(
      registerShopPush({
        onToast: (m) => toasts.push(m),
        deps: deps(calls, {
          getToken: async () => {
            throw new Error("boom")
          }
        })
      })
    )
    assert.deepEqual(toasts, [])
  })

  it("Subtask 3: флаг включён — многострочный лог шагов и шаг ошибки, как сейчас", async () => {
    flag.setPushDiagEnabled(true)
    const calls = []
    const toasts = []
    installNotification("granted", calls)
    await assert.rejects(
      registerShopPush({
        onToast: (m) => toasts.push(m),
        deps: deps(calls, {
          getToken: async () => {
            throw new Error("boom")
          }
        })
      })
    )
    const last = toasts.at(-1)
    assert.match(last, /^1: старт registerShopPush/)
    assert.match(last, /\n4: результат requestPermission = granted/)
    assert.match(last, /ОШИБКА на шаге 7: boom/)
  })

  it("Subtask 9: с флагом и без — те же вызовы и reason, requestPermission синхронно первым", async () => {
    for (const on of [false, true]) {
      flag.setPushDiagEnabled(on)
      const calls = []
      installNotification("granted", calls)
      const pending = registerShopPush({ onToast: () => {}, deps: deps(calls) })
      assert.deepEqual(calls, ["requestPermission"])
      const result = await pending
      assert.equal(result.ok, true)
      assert.deepEqual(calls, [
        "requestPermission",
        "isSupported",
        "firebaseClientConfigured",
        "getToken",
        "registerToken:tok-108"
      ])
      removeNotification()
    }
  })
})

describe("subscribeOrderPush — реальный registerShopPush, подмена только deps (Subtask 4, 10)", () => {
  it("копия сообщения об ошибке — решение владельца 2026-10-15", () => {
    assert.equal(notifyActions.PUSH_FAILED_TOAST, FAILED_TEXT)
  })

  for (const [name, override, err] of [
    ["getToken падает", { getToken: async () => Promise.reject(new Error("fcm down")) }, "network"],
    ["POST /push/register падает", { registerToken: async () => Promise.reject(new Error("500")) }, "network"],
    ["Firebase не поддерживается", { isSupported: async () => false }, "unsupported"],
    ["нет токена", { getToken: async () => "" }, "no_token"]
  ]) {
    it(`Subtask 4: флаг выключен, ${name} → одно сообщение, CTA доступен`, async () => {
      const calls = []
      const toasts = []
      installNotification("granted", calls)
      const result = await subscribeOrderPush({
        onToast: (m) => toasts.push(m),
        storage: null,
        deps: deps(calls, override)
      })
      assert.equal(calls[0], "requestPermission", "работает реальная registerShopPush")
      assert.deepEqual(toasts, [FAILED_TEXT])
      assert.ok(!toasts.some(isTechnical))
      assert.equal(result.ok, false)
      assert.equal(result.error, err)
      assert.match(result.primaryLabel, /Уведомление о готовности/)
      assert.notEqual(result.openSettings, true)
    })
  }

  it("Subtask 4: флаг выключен, denied и default — как Патч 2 TASK_90", async () => {
    for (const [permission, toast, error] of [
      ["denied", PUSH_DENIED_TOAST, "denied"],
      ["default", PUSH_NOT_ENABLED_TOAST, "dismissed"]
    ]) {
      const toasts = []
      installNotification(permission)
      const result = await subscribeOrderPush({
        onToast: (m) => toasts.push(m),
        storage: null,
        deps: deps([])
      })
      assert.deepEqual(toasts, [toast])
      assert.equal(result.error, error)
      removeNotification()
    }
  })

  it("Subtask 1: флаг выключен, успех — ни одной строки", async () => {
    const toasts = []
    installNotification("granted")
    const result = await subscribeOrderPush({
      onToast: (m) => toasts.push(m),
      storage: null,
      deps: deps([])
    })
    assert.equal(result.ok, true)
    assert.deepEqual(toasts, [])
  })

  it("Subtask 3: флаг включён — лог шагов вместо итогового сообщения, как сейчас", async () => {
    flag.setPushDiagEnabled(true)
    const toasts = []
    installNotification("granted")
    const result = await subscribeOrderPush({
      onToast: (m) => toasts.push(m),
      storage: null,
      deps: deps([], { getToken: async () => Promise.reject(new Error("fcm down")) })
    })
    assert.equal(result.error, "network")
    assert.ok(!toasts.includes(FAILED_TEXT))
    assert.match(toasts.at(-1), /ОШИБКА на шаге 7: fcm down/)
  })

  it("инвариант TASK_99: путь аккордеона с флагом — requestPermission синхронно", async () => {
    flag.setPushDiagEnabled(true)
    const calls = []
    installNotification("granted", calls)
    const pending = subscribeOrderPush({ onToast: () => {}, storage: null, deps: deps(calls) })
    assert.deepEqual(calls, ["requestPermission"])
    await pending
  })
})

describe("OrderStatus.svelte — вывод и жест (Subtask 1–3, 5, 8)", () => {
  it("модуль флага импортируется статически (без динамического импорта)", () => {
    const src = orderStatusSrc()
    assert.match(src, /import \{[^}]*\} from "\.\.\/lib\/pushDiagFlag\.js"/)
    assert.doesNotMatch(src, /import\(\s*["'][^"']*pushDiagFlag/)
  })

  it("Subtask 2: автовызов при granted помечен auto и без флага ничего не показывает", () => {
    const src = orderStatusSrc()
    assert.match(src, /Notification\.permission === "granted"\)\s*\{\s*enablePushNotifications\(\{ auto: true \}\)/)
    assert.match(src, /if \(!diagOn && !auto\) pushErr = PUSH_FAILED_TOAST/)
  })

  it("Subtask 1/4: лог в pushErr/ctaToast — только при флаге, без флага одно сообщение у кнопки", () => {
    const src = orderStatusSrc()
    assert.match(src, /registerShopPush\(\{ onToast, diag: diagOn \}\)/)
    assert.match(src, /PUSH_FAILED_TOAST/)
    assert.doesNotMatch(src, /TEMP DIAG/)
  })

  it("Subtask 9: ветки denied / else → error сохранены (охрана Патча 2)", () => {
    const src = orderStatusSrc()
    assert.match(src, /result\.reason === "denied"\)\s*\{\s*pushState = "denied"/)
    assert.match(src, /\}\s*else\s*\{\s*pushState = "error"/)
  })

  it("Subtask 8: жест — на заголовке «Заказ», не на «Назад», с подтверждением", () => {
    const src = orderStatusSrc()
    assert.match(src, /<span class="page-title"[^>]*onpointerup=\{onTitleTap\}[^>]*>Заказ<\/span>/)
    assert.doesNotMatch(src, /class="back-btn"[^>]*onTitleTap/)
    assert.match(src, /createTapGesture\(PUSH_DIAG_GESTURE\)/)
    assert.match(src, /data-testid="push-diag-notice"/)
  })
})

describe("ActiveOrdersAccordion.svelte — переносы строк лога (Subtask 3)", () => {
  it(".aoa__toast — white-space: pre-line", () => {
    const block = accordionSrc().match(/\.aoa__toast \{[^}]*\}/)?.[0] || ""
    assert.match(block, /white-space:\s*pre-line/)
  })
})
