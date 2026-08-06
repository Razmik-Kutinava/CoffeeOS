/**
 * userCardsApiPath — email query from guest profile
 * node --test test/javascript/user_cards_api_path_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach, afterEach } from "node:test"
import { userCardsApiPath } from "../../app/frontend/lib/userCardsApiPath.js"

describe("userCardsApiPath", () => {
  const store = new Map()
  const originalWindow = globalThis.window
  const originalDocument = globalThis.document
  const originalLocalStorage = globalThis.localStorage

  beforeEach(() => {
    store.clear()
    globalThis.window = {
      location: { search: "?tenant_id=t-test" }
    }
    globalThis.document = {
      querySelector: () => ({ getAttribute: () => "t-test" })
    }
    globalThis.localStorage = {
      getItem: (k) => store.get(k) ?? null,
      setItem: (k, v) => store.set(k, String(v)),
      removeItem: (k) => store.delete(k)
    }
  })

  afterEach(() => {
    globalThis.window = originalWindow
    globalThis.document = originalDocument
    globalThis.localStorage = originalLocalStorage
  })

  it("returns plain path when profile empty", () => {
    assert.equal(userCardsApiPath(), "/user/cards")
  })

  it("appends email when guest profile has valid email", () => {
    const key = "shop_guest_profile:t-test"
    store.set(
      key,
      JSON.stringify({
        savedAt: new Date().toISOString(),
        ttlMs: 90 * 24 * 60 * 60 * 1000,
        payload: {
          name: "Aram",
          email: "aramfifa100@gmail.com",
          emailVerified: true
        }
      })
    )
    const path = userCardsApiPath()
    assert.match(path, /\/user\/cards\?email=/)
    assert.match(path, /aramfifa100%40gmail\.com/)
  })
})
