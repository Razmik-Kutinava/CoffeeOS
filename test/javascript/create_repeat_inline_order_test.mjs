/**
 * createRepeatInlineOrder — unit smoke
 * node --test test/javascript/create_repeat_inline_order_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import { createRepeatInlineOrder } from "../../app/frontend/lib/createRepeatInlineOrder.js"

describe("createRepeatInlineOrder", () => {
  it("throws when product_id missing", async () => {
    await assert.rejects(
      () => createRepeatInlineOrder({}, { api: async () => ({}) }),
      /Нет товара/
    )
  })

  it("throws profile_required when guest profile empty", async () => {
    // loadGuestProfile reads DOM/localStorage — in node it returns null
    await assert.rejects(
      () => createRepeatInlineOrder({ product_id: "p1" }, { api: async () => ({}) }),
      (err) => err.code === "profile_required" || /email|профил/i.test(err.message)
    )
  })
})
