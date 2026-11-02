/**
 * TASK_117 — FE: подтверждение смены сессии по SMS-ссылке [TDD].
 *
 * node --test test/javascript/sms_session_transition_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  SMS_TRANSITION_TITLE,
  SMS_TRANSITION_CART_WARNING,
  SMS_TRANSITION_CONFIRM_LABEL,
  SMS_TRANSITION_DECLINE_LABEL,
  parseSmsTransitionToken,
  bumpSessionGeneration,
  currentSessionGeneration,
  isStaleGeneration,
  beginSmsTransition,
  endSmsTransition,
  smsTransitionBusy,
  clearClientCachesAfterSmsConfirm,
  confirmSmsTransition,
  declineSmsTransition,
  profilePathAfterConfirm,
  stripSmsTransitionFromSearch
} from "../../app/frontend/lib/smsSessionTransition.js"
import { clearSubscriptionOfferCtaCache } from "../../app/frontend/lib/subscriptionOfferCta.js"
import { pushRegisteredStorageKey } from "../../app/frontend/lib/orderStatusNotifyActions.js"
import { renderSvelte } from "./svelte_ssr_helper.mjs"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const dialogPath = join(root, "app/frontend/components/SmsSessionTransitionDialog.svelte")
const read = (p) => readFileSync(join(root, p), "utf8")

describe("TASK_117 тексты окна", () => {
  it("предупреждение про корзину (R2) и кнопки", () => {
    assert.match(SMS_TRANSITION_TITLE, /сесс|аккаунт|профил/i)
    assert.match(SMS_TRANSITION_CART_WARNING, /корзин/i)
    assert.ok(SMS_TRANSITION_CONFIRM_LABEL.length > 0)
    assert.ok(SMS_TRANSITION_DECLINE_LABEL.length > 0)
  })

  it("диалог SSR содержит предупреждение о корзине", async () => {
    const html = await renderSvelte(dialogPath, {
      open: true,
      busy: false
    })
    assert.match(html, /корзин/i)
    assert.match(html, new RegExp(SMS_TRANSITION_CONFIRM_LABEL))
    assert.match(html, new RegExp(SMS_TRANSITION_DECLINE_LABEL))
  })
})

describe("TASK_117 Subtask 9 — token из query", () => {
  it("parseSmsTransitionToken читает sms_transition и не трогает reconnect_token", () => {
    const token = parseSmsTransitionToken(
      "?tenant_id=t1&sms_transition=abc%2Bdef&reconnect_token=should-ignore"
    )
    assert.equal(token, "abc+def")
  })

  it("stripSmsTransitionFromSearch убирает sms_transition из строки", () => {
    const next = stripSmsTransitionFromSearch(
      "?tenant_id=t1&sms_transition=tok&x=1"
    )
    assert.equal(next, "?tenant_id=t1&x=1")
    assert.doesNotMatch(next, /sms_transition/)
  })
})

describe("TASK_117 Subtask 5 — generation / stale", () => {
  beforeEach(() => {
    bumpSessionGeneration()
  })

  it("ответы со старым generation игнорируются", () => {
    const g0 = currentSessionGeneration()
    bumpSessionGeneration()
    assert.equal(isStaleGeneration(g0), true)
    assert.equal(isStaleGeneration(currentSessionGeneration()), false)
  })
})

describe("TASK_117 Subtask 7 — одна обработка", () => {
  it("beginSmsTransition блокирует вторую, пока первая не завершена", () => {
    endSmsTransition()
    assert.equal(beginSmsTransition("tok-a"), true)
    assert.equal(smsTransitionBusy(), true)
    assert.equal(beginSmsTransition("tok-b"), false)
    endSmsTransition()
  })
})

describe("TASK_117 Subtask 4 — clear caches on confirm", () => {
  it("clearClientCachesAfterSmsConfirm снимает push key и CTA cache", () => {
    const store = new Map()
    const storage = {
      getItem: (k) => (store.has(k) ? store.get(k) : null),
      setItem: (k, v) => store.set(k, String(v)),
      removeItem: (k) => store.delete(k)
    }
    storage.setItem(pushRegisteredStorageKey(), "true")
    clearSubscriptionOfferCtaCache()
    clearClientCachesAfterSmsConfirm({ storage })
    assert.equal(storage.getItem(pushRegisteredStorageKey()), null)
  })
})

describe("TASK_117 confirm/decline API + navigation", () => {
  it("confirm вызывает POST и возвращает путь истории с order", async () => {
    const calls = []
    const api = async (path, opts = {}) => {
      calls.push({ path, method: opts.method || "GET", body: opts.body })
      return { ok: true, order_id: "ord-9" }
    }
    const gen = currentSessionGeneration()
    const res = await confirmSmsTransition("pend-1", { api, generation: gen })
    assert.equal(res.ok, true)
    assert.equal(calls[0].path, "/session/sms_transition")
    assert.equal(calls[0].method, "POST")
    assert.match(calls[0].body, /pend-1/)
    assert.equal(profilePathAfterConfirm("ord-9"), "/profile?order=ord-9")
  })

  it("stale generation после confirm не считается успехом для UI", async () => {
    const gen = currentSessionGeneration()
    bumpSessionGeneration()
    const api = async () => ({ ok: true, order_id: "ord-9" })
    const res = await confirmSmsTransition("pend-1", { api, generation: gen })
    assert.equal(res.ok, false)
    assert.equal(res.reason, "stale")
  })

  it("decline вызывает DELETE и не чистит push key", async () => {
    const store = new Map([[pushRegisteredStorageKey(), "true"]])
    const storage = {
      getItem: (k) => (store.has(k) ? store.get(k) : null),
      setItem: (k, v) => store.set(k, String(v)),
      removeItem: (k) => store.delete(k)
    }
    const calls = []
    const api = async (path, opts = {}) => {
      calls.push({ path, method: opts.method || "GET" })
      return { ok: true }
    }
    const res = await declineSmsTransition("pend-2", { api, storage })
    assert.equal(res.ok, true)
    assert.equal(calls[0].path, "/session/sms_transition")
    assert.equal(calls[0].method, "DELETE")
    assert.equal(storage.getItem(pushRegisteredStorageKey()), "true")
  })
})

describe("TASK_117 App wiring guards", () => {
  it("App импортирует диалог и smsSessionTransition, порядок onMount с reportSessionOpenOnce сохранён", () => {
    const src = read("app/frontend/App.svelte")
    assert.match(src, /smsSessionTransition/)
    assert.match(src, /SmsSessionTransitionDialog/)
    const mount = src.slice(src.indexOf("onMount("))
    const restoreIdx = mount.indexOf("restoreGuestSession")
    const bootstrapIdx = mount.indexOf("bootstrapShopTenant")
    const reportIdx = mount.indexOf("reportSessionOpenOnce")
    assert.ok(restoreIdx >= 0 && bootstrapIdx > restoreIdx && reportIdx > bootstrapIdx)
  })

  it("OrderStatus не авто-push при pending SMS transition", () => {
    const src = read("app/frontend/routes/OrderStatus.svelte")
    assert.match(src, /smsTransitionPending|smsSessionTransition/)
  })
})
