/**
 * #41 Шаг 1 [TDD-RED] — SupportChatAdapter: openSupportChat.
 *
 * node --test test/javascript/support_chat_adapter_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import { openSupportChat } from "../../app/frontend/lib/supportChatAdapter.js"

describe("openSupportChat (#41 step 1)", () => {
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

  it("logs pending integration when chatUrl is missing", () => {
    const logs = []
    const opened = []
    const result = openSupportChat("ord-99", undefined, {
      openWindow: (url, target) => {
        opened.push({ url, target })
      },
      log: (msg) => logs.push(msg)
    })

    assert.equal(result.opened, false)
    assert.equal(result.pending, true)
    assert.equal(opened.length, 0)
    assert.equal(logs.length, 1)
    assert.equal(logs[0], "[Chat Integration Pending] Order: ord-99")
  })

  it("treats empty string chatUrl as missing (pending log)", () => {
    const logs = []
    const result = openSupportChat("ord-empty", "", {
      openWindow: () => {
        throw new Error("should not open")
      },
      log: (msg) => logs.push(msg)
    })

    assert.equal(result.opened, false)
    assert.equal(result.pending, true)
    assert.equal(logs[0], "[Chat Integration Pending] Order: ord-empty")
  })
})
