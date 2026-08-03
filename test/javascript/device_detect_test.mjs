/**
 * #37 Шаг 1 — getDeviceOS [RED / TDD].
 *
 * node --test test/javascript/device_detect_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"

import { getDeviceOS } from "../../app/frontend/lib/deviceDetect.js"

describe("getDeviceOS (#37 step 1)", () => {
  it("returns ios for iPhone userAgent", () => {
    assert.equal(
      getDeviceOS({
        userAgent:
          "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
        platform: "iPhone",
        maxTouchPoints: 5,
        hasWindow: true
      }),
      "ios"
    )
  })

  it("returns ios for iPod userAgent", () => {
    assert.equal(
      getDeviceOS({
        userAgent:
          "Mozilla/5.0 (iPod touch; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15",
        platform: "iPod",
        maxTouchPoints: 5,
        hasWindow: true
      }),
      "ios"
    )
  })

  it("returns ios for iPadOS 13+ (MacIntel + maxTouchPoints > 1)", () => {
    assert.equal(
      getDeviceOS({
        userAgent:
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15",
        platform: "MacIntel",
        maxTouchPoints: 5,
        hasWindow: true
      }),
      "ios"
    )
  })

  it("returns android for Android userAgent", () => {
    assert.equal(
      getDeviceOS({
        userAgent:
          "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36",
        platform: "Linux armv8l",
        maxTouchPoints: 5,
        hasWindow: true
      }),
      "android"
    )
  })

  it("returns desktop for typical desktop Chrome", () => {
    assert.equal(
      getDeviceOS({
        userAgent:
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
        platform: "Win32",
        maxTouchPoints: 0,
        hasWindow: true
      }),
      "desktop"
    )
  })

  it("returns desktop for MacIntel without multi-touch (real Mac)", () => {
    assert.equal(
      getDeviceOS({
        userAgent:
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
        platform: "MacIntel",
        maxTouchPoints: 0,
        hasWindow: true
      }),
      "desktop"
    )
  })

  it("returns desktop when hasWindow is false (SSR / no window)", () => {
    assert.equal(
      getDeviceOS({
        userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)",
        platform: "iPhone",
        maxTouchPoints: 5,
        hasWindow: false
      }),
      "desktop"
    )
  })
})
