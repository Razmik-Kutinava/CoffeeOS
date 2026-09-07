/**
 * #41 / #81 — SupportChatAdapter: openSupportChat + default Telegram URL.
 *
 * node --test test/javascript/support_chat_adapter_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import { openSupportChat } from "../../app/frontend/lib/supportChatAdapter.js"
import { SUPPORT_TELEGRAM_URL } from "../../app/frontend/lib/supportConfig.js"

describe("openSupportChat (#41 / #81)", () => {
  it("opens chatUrl in a new tab when URL is provided", () => {
    const opened = []
    const result = openSupportChat("ord-42", "https://support.example/chat?o=ord-42", {
      openWindow: (url, target) => {
        opened.push({ url, target })
        return { ok: true }
      }
    })

    assert.equal(result.opened, true)
    assert.equal(result.pending, false)
    assert.deepEqual(opened, [
      { url: "https://support.example/chat?o=ord-42", target: "_blank" }
    ])
  })

  it("defaults to SUPPORT_TELEGRAM_URL when chatUrl is missing", () => {
    const logs = []
    const opened = []
    const result = openSupportChat("ord-99", undefined, {
      openWindow: (url, target) => {
        opened.push({ url, target })
      },
      log: (msg) => logs.push(msg)
    })

    assert.equal(result.opened, true)
    assert.equal(result.pending, false)
    assert.deepEqual(opened, [{ url: SUPPORT_TELEGRAM_URL, target: "_blank" }])
    assert.equal(logs.length, 0)
  })

  it("defaults to SUPPORT_TELEGRAM_URL when chatUrl is empty string", () => {
    const opened = []
    const result = openSupportChat("ord-empty", "", {
      openWindow: (url, target) => {
        opened.push({ url, target })
      },
      log: () => {
        throw new Error("should not log pending")
      }
    })

    assert.equal(result.opened, true)
    assert.equal(result.pending, false)
    assert.deepEqual(opened, [{ url: SUPPORT_TELEGRAM_URL, target: "_blank" }])
  })

  it("logs pending only when defaultUrl is explicitly empty", () => {
    const logs = []
    const result = openSupportChat("ord-no-default", undefined, {
      defaultUrl: "",
      openWindow: () => {
        throw new Error("should not open")
      },
      log: (msg) => logs.push(msg)
    })

    assert.equal(result.opened, false)
    assert.equal(result.pending, true)
    assert.equal(logs[0], "[Chat Integration Pending] Order: ord-no-default")
  })
})
