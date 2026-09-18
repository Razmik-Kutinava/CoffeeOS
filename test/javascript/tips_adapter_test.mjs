/**
 * #41 Шаг 2 [TDD-RED] — TipsAdapter (нетмонет): openTipsService.
 *
 * node --test test/javascript/tips_adapter_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import { openTipsService } from "../../app/frontend/lib/tipsAdapter.js"

describe("openTipsService (#41 step 2)", () => {
  it("opens tipsUrl in a new tab when URL is provided", () => {
    const opened = []
    const result = openTipsService("ord-42", "tenant-a", "https://tips.example/o/ord-42", {
      openWindow: (url, target) => {
        opened.push({ url, target })
        return { ok: true }
      }
    })

    assert.equal(result.opened, true)
    assert.equal(result.pending, false)
    assert.deepEqual(opened, [
      { url: "https://tips.example/o/ord-42", target: "_blank" }
    ])
  })

  it("opens default tips URL when tipsUrl is missing", () => {
    const opened = []
    const result = openTipsService("ord-99", "tenant-b", undefined, {
      openWindow: (url, target) => {
        opened.push({ url, target })
        return { ok: true }
      }
    })

    assert.equal(result.opened, true)
    assert.equal(result.pending, false)
    assert.equal(opened.length, 1)
    assert.match(opened[0].url, /ord-99/)
    assert.equal(opened[0].target, "_blank")
  })

  it("logs pending integration when default URL is also empty", () => {
    const logs = []
    const opened = []
    const result = openTipsService("ord-99", "tenant-b", undefined, {
      defaultUrl: "",
      openWindow: (url, target) => {
        opened.push({ url, target })
      },
      log: (msg) => logs.push(msg)
    })

    assert.equal(result.opened, false)
    assert.equal(result.pending, true)
    assert.equal(opened.length, 0)
    assert.equal(logs.length, 1)
    assert.equal(logs[0], "[Tips Integration Pending] Order: ord-99")
  })

  it("treats empty string tipsUrl as default (opens)", () => {
    const opened = []
    const result = openTipsService("ord-empty", "tenant-c", "", {
      openWindow: (url, target) => {
        opened.push({ url, target })
        return { ok: true }
      }
    })

    assert.equal(result.opened, true)
    assert.equal(result.pending, false)
    assert.equal(opened.length, 1)
  })

  it("falls back to assignLocation when window.open blocked", () => {
    const assigned = []
    const result = openTipsService("ord-42", "t", "https://tips.example/o/x", {
      openWindow: () => null,
      assignLocation: (url) => assigned.push(url)
    })
    assert.equal(result.opened, true)
    assert.equal(result.fallback, true)
    assert.deepEqual(assigned, ["https://tips.example/o/x"])
  })
})
