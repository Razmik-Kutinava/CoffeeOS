/**
 * TASK_109 Subtask 1 — класс окружения A–E и pushPossible поверх снимка TASK_112 [TDD].
 *
 * node --test test/javascript/push_environment_class_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

const mod = await import("../../app/frontend/lib/pushEnvironmentClass.js").catch(() => ({}))

function classify(flags) {
  assert.equal(typeof mod.classifyPushEnvironment, "function", "classifyPushEnvironment не экспортирован")
  return mod.classifyPushEnvironment(flags)
}

/** Поля collectPushEnvironment: Android Chrome, вкладка, всё доступно. */
function flags(overrides = {}) {
  return {
    os_family: "android",
    standalone: "browser",
    notification_state: "default",
    push_manager: "available",
    service_worker: "available",
    inapp_label: "none",
    ...overrides
  }
}

const NO_PUSH = {
  notification_state: "unavailable",
  push_manager: "unavailable",
  service_worker: "available"
}

describe("TASK_109 Subtask 1 — classifyPushEnvironment", () => {
  it("A — установленное PWA с поддержкой push", () => {
    assert.deepEqual(classify(flags({ standalone: "standalone" })), { pushClass: "A", pushPossible: true })
  })

  it("A — iPhone на главном экране с поддержкой push", () => {
    assert.deepEqual(classify(flags({ os_family: "ios", standalone: "standalone" })), {
      pushClass: "A",
      pushPossible: true
    })
  })

  it("B — вкладка браузера с поддержкой push", () => {
    assert.deepEqual(classify(flags()), { pushClass: "B", pushPossible: true })
  })

  it("метка встроенного браузера при наличии push кнопку не скрывает (B)", () => {
    assert.deepEqual(classify(flags({ inapp_label: "telegram" })), { pushClass: "B", pushPossible: true })
  })

  it("Notification с любым разрешением (granted / denied) считается доступным", () => {
    assert.equal(classify(flags({ notification_state: "granted" })).pushPossible, true)
    assert.equal(classify(flags({ notification_state: "denied" })).pushPossible, true)
  })

  it("pushPossible требует все три: Notification, PushManager, serviceWorker", () => {
    assert.equal(classify(flags({ notification_state: "unavailable" })).pushPossible, false)
    assert.equal(classify(flags({ push_manager: "unavailable" })).pushPossible, false)
    assert.equal(classify(flags({ service_worker: "unavailable" })).pushPossible, false)
  })

  it("C — iPhone вне главного экрана без поддержки", () => {
    assert.deepEqual(classify(flags({ os_family: "ios", ...NO_PUSH })), { pushClass: "C", pushPossible: false })
  })

  it("D — встроенный браузер на iPhone без поддержки", () => {
    assert.deepEqual(classify(flags({ os_family: "ios", inapp_label: "instagram", ...NO_PUSH })), {
      pushClass: "D",
      pushPossible: false
    })
  })

  it("E — встроенный браузер на Android без поддержки", () => {
    assert.deepEqual(classify(flags({ inapp_label: "telegram", ...NO_PUSH })), {
      pushClass: "E",
      pushPossible: false
    })
  })

  it("вне A–E без push (решение владельца) — класса нет, pushPossible = false", () => {
    assert.deepEqual(classify(flags({ os_family: "other", ...NO_PUSH })), { pushClass: null, pushPossible: false })
    assert.deepEqual(classify(flags({ ...NO_PUSH })), { pushClass: null, pushPossible: false })
    assert.deepEqual(classify(flags({ os_family: "ios", standalone: "standalone", ...NO_PUSH })), {
      pushClass: null,
      pushPossible: false
    })
  })

  it("пустой снимок — без исключения, pushPossible = false", () => {
    assert.deepEqual(classify({}), { pushClass: null, pushPossible: false })
    assert.deepEqual(classify(undefined), { pushClass: null, pushPossible: false })
  })
})

describe("TASK_109 Subtask 1 — currentPushPossible(env)", () => {
  function env(overrides = {}) {
    return {
      navigator: { userAgent: "Mozilla/5.0 (Linux; Android 14; Pixel 6) Chrome/126.0.0.0 Mobile", serviceWorker: {} },
      matchMedia: () => ({ matches: false }),
      Notification: { permission: "default" },
      PushManager: function PushManager() {},
      ...overrides
    }
  }

  it("окружение с push → true", () => {
    assert.equal(typeof mod.currentPushPossible, "function", "currentPushPossible не экспортирован")
    assert.equal(mod.currentPushPossible(env()), true)
  })

  it("без Notification → false", () => {
    assert.equal(typeof mod.currentPushPossible, "function", "currentPushPossible не экспортирован")
    assert.equal(mod.currentPushPossible(env({ Notification: undefined })), false)
  })
})
