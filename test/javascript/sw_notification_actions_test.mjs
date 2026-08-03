/**
 * #38 Шаг 2 [TDD-RED] — SW notificationclick: cancel / chat / tips.
 *
 * node --test test/javascript/sw_notification_actions_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import {
  CANCEL_ERROR_MESSAGE,
  buildShowNotificationOptions,
  handleNotificationAction,
  orderDeepLink,
  parseNotificationActions
} from "../../app/frontend/lib/swNotificationActions.js"

describe("parseNotificationActions (#38 step 2)", () => {
  it("parses JSON string from FCM data", () => {
    assert.deepEqual(parseNotificationActions('["cancel"]'), ["cancel"])
    assert.deepEqual(parseNotificationActions('["chat","tips"]'), ["chat", "tips"])
  })

  it("accepts array already", () => {
    assert.deepEqual(parseNotificationActions(["chat", "tips"]), ["chat", "tips"])
  })

  it("returns empty on garbage", () => {
    assert.deepEqual(parseNotificationActions(null), [])
    assert.deepEqual(parseNotificationActions("nope"), [])
  })
})

describe("buildShowNotificationOptions (#38 step 2)", () => {
  it("sets tag and Notification actions with Russian titles", () => {
    const opts = buildShowNotificationOptions({
      body: "🟩⬜⬜ Заказ оплачен",
      data: {
        order_id: "abc",
        tag: "order-abc",
        actions: '["cancel"]'
      }
    })

    assert.equal(opts.tag, "order-abc")
    assert.equal(opts.body, "🟩⬜⬜ Заказ оплачен")
    assert.deepEqual(opts.actions, [{ action: "cancel", title: "Отменить" }])
    assert.equal(opts.data.order_id, "abc")
  })

  it("maps chat and tips titles", () => {
    const opts = buildShowNotificationOptions({
      body: "ready",
      data: { order_id: "1", tag: "order-1", actions: ["chat", "tips"] }
    })
    assert.deepEqual(opts.actions, [
      { action: "chat", title: "Чат" },
      { action: "tips", title: "Чаевые" }
    ])
  })
})

describe("orderDeepLink (#38 step 2)", () => {
  it("builds shop hash deep links", () => {
    assert.equal(orderDeepLink("42", "chat"), "/shop/#/order/42?action=chat")
    assert.equal(orderDeepLink("42", "tips"), "/shop/#/order/42?action=tips")
  })
})

describe("handleNotificationAction (#38 step 2)", () => {
  it("cancel: POST /shop/api/orders/:id/cancel with credentials", async () => {
    const calls = []
    const result = await handleNotificationAction({
      action: "cancel",
      orderId: "ord-1",
      fetchImpl: async (url, opts) => {
        calls.push({ url, opts })
        return { ok: true, status: 200 }
      },
      openClient: async () => ({ opened: false }),
      showLocalNotification: async () => {}
    })

    assert.equal(result.kind, "cancel_ok")
    assert.equal(calls.length, 1)
    assert.equal(calls[0].url, "/shop/api/orders/ord-1/cancel")
    assert.equal(calls[0].opts.method, "POST")
    assert.equal(calls[0].opts.credentials, "include")
  })

  it("cancel: 400/500 shows local error notification and does not throw", async () => {
    const toasts = []
    const result = await handleNotificationAction({
      action: "cancel",
      orderId: "ord-2",
      fetchImpl: async () => ({ ok: false, status: 500 }),
      openClient: async () => ({}),
      showLocalNotification: async (title, body) => {
        toasts.push({ title, body })
      }
    })

    assert.equal(result.kind, "cancel_error")
    assert.equal(toasts.length, 1)
    assert.equal(toasts[0].body, CANCEL_ERROR_MESSAGE)
    assert.equal(CANCEL_ERROR_MESSAGE, "Не удалось отменить, проверьте сеть")
  })

  it("cancel: network throw shows same local error", async () => {
    const toasts = []
    const result = await handleNotificationAction({
      action: "cancel",
      orderId: "ord-3",
      fetchImpl: async () => {
        throw new TypeError("Failed to fetch")
      },
      openClient: async () => ({}),
      showLocalNotification: async (_t, body) => {
        toasts.push(body)
      }
    })

    assert.equal(result.kind, "cancel_error")
    assert.equal(toasts[0], CANCEL_ERROR_MESSAGE)
  })

  it("chat: opens deep link via openClient", async () => {
    const opened = []
    const result = await handleNotificationAction({
      action: "chat",
      orderId: "ord-4",
      fetchImpl: async () => ({ ok: true }),
      openClient: async (url) => {
        opened.push(url)
        return { opened: true }
      },
      showLocalNotification: async () => {}
    })

    assert.equal(result.kind, "navigate")
    assert.deepEqual(opened, ["/shop/#/order/ord-4?action=chat"])
  })

  it("tips: opens tips deep link", async () => {
    const opened = []
    const result = await handleNotificationAction({
      action: "tips",
      orderId: "ord-5",
      fetchImpl: async () => ({ ok: true }),
      openClient: async (url) => {
        opened.push(url)
        return { opened: true }
      },
      showLocalNotification: async () => {}
    })

    assert.equal(result.kind, "navigate")
    assert.deepEqual(opened, ["/shop/#/order/ord-5?action=tips"])
  })
})
