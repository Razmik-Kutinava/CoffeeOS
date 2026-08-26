/**
 * #70 Telegram bot support ЛК
 *
 * node --test test/javascript/telegram_support_test.mjs
 */
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { describe, it, mock } from "node:test"
import { fileURLToPath } from "node:url"

import {
  SUPPORT_CHANNELS,
  DEFAULT_SUPPORT_CHANNEL,
  getSupportChannel,
  getAvailableSupportChannels,
  SUPPORT_TELEGRAM_URL
} from "../../app/frontend/lib/supportConfig.js"

import { shopSupportTelegramUrl } from "../../app/frontend/lib/shopAboutConfig.js"

import {
  openDeepLink,
  isValidDeepLink,
  cleanDeepLinkUrl
} from "../../app/frontend/lib/deepLink.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const CANON = "https://t.me/code_black_support_bot"

function readFront(rel) {
  return readFileSync(join(root, "app/frontend", rel), "utf8")
}

describe("Support Config (#70)", () => {
  it("SUPPORT_TELEGRAM_URL is canon without PII params", () => {
    assert.equal(SUPPORT_TELEGRAM_URL, CANON)
    assert.equal(SUPPORT_CHANNELS.TELEGRAM.url, CANON)
    assert(!CANON.includes("user_id"))
    assert(!CANON.includes("phone"))
    assert(!CANON.includes("order_id"))
    assert(!CANON.includes("CustomerKey"))
  })

  it("SUPPORT_CHANNELS.EMAIL is stub (null URL)", () => {
    assert.equal(SUPPORT_CHANNELS.EMAIL.id, "email")
    assert.equal(SUPPORT_CHANNELS.EMAIL.url, null)
  })

  it("DEFAULT_SUPPORT_CHANNEL is TELEGRAM", () => {
    assert.equal(DEFAULT_SUPPORT_CHANNEL.url, CANON)
  })

  it("getSupportChannel / getAvailableSupportChannels", () => {
    assert.equal(getSupportChannel("telegram").url, CANON)
    assert.equal(getSupportChannel("email").url, null)
    assert.equal(getSupportChannel("unknown"), null)
    const channels = getAvailableSupportChannels()
    assert.equal(channels.length, 2)
    assert.equal(channels[0].id, "telegram")
    assert.equal(channels[1].id, "email")
  })
})

describe("Unified URL both entry points (#70 Subtask 11) [RED]", () => {
  it("shopSupportTelegramUrl matches SUPPORT_TELEGRAM_URL by default", () => {
    const lk = shopSupportTelegramUrl()
    assert.equal(lk, SUPPORT_TELEGRAM_URL)
    assert.equal(lk, CANON)
  })

  it("Header sheet uses supportConfig; LK sheet uses shopSupportTelegramUrl", () => {
    const headerSheet = readFront("components/SupportContactSheet.svelte")
    const lkSheet = readFront("components/ContactSupportSheet.svelte")
    assert.match(headerSheet, /supportConfig/)
    assert.match(lkSheet, /shopSupportTelegramUrl/)
  })

  it("Profile hub and AccountSettings open ContactSupportSheet", () => {
    const profile = readFront("routes/Profile.svelte")
    const settings = readFront("routes/AccountSettings.svelte")
    assert.match(profile, /ContactSupportSheet/)
    assert.match(profile, /Написать нам/)
    assert.match(settings, /ContactSupportSheet/)
    assert.match(settings, /написать нам/i)
    assert.match(settings, /shop-write-us/)
  })

  it("LK Telegram open uses openDeepLink (no iframe / WebApp)", () => {
    const lkSheet = readFront("components/ContactSupportSheet.svelte")
    assert.match(lkSheet, /openDeepLink/)
    assert.doesNotMatch(lkSheet, /iframe|Telegram\.WebApp|tg\.WebApp/i)
    const headerSheet = readFront("components/SupportContactSheet.svelte")
    assert.match(headerSheet, /openDeepLink/)
    assert.doesNotMatch(headerSheet, /iframe|Telegram\.WebApp/i)
  })

  it("opened URL cleaned of query/hash PII", () => {
    const dirty = `${CANON}?user_id=1&phone=9#order_id=2`
    const cleaned = cleanDeepLinkUrl(dirty)
    assert.equal(cleaned, CANON)
    assert.doesNotMatch(cleaned, /user_id|phone|order_id/)
  })
})

describe("Deep Link Utilities (#70)", () => {
  it("openDeepLink calls window.open with URL and default target '_blank'", () => {
    const mockOpen = mock.fn()
    global.window = { open: mockOpen }

    openDeepLink(CANON)

    assert.equal(mockOpen.mock.calls.length, 1)
    assert.deepEqual(mockOpen.mock.calls[0].arguments, [CANON, "_blank"])
  })

  it("openDeepLink respects custom target; ignores empty", () => {
    const mockOpen = mock.fn()
    global.window = { open: mockOpen }

    openDeepLink(CANON, { target: "_self" })
    openDeepLink("")
    openDeepLink(null)

    assert.equal(mockOpen.mock.calls.length, 1)
    assert.deepEqual(mockOpen.mock.calls[0].arguments, [CANON, "_self"])
  })

  it("isValidDeepLink", () => {
    assert.equal(isValidDeepLink(CANON), true)
    assert.equal(isValidDeepLink("http://example.com"), true)
    assert.equal(isValidDeepLink("not a url"), false)
    assert.equal(isValidDeepLink(""), false)
  })

  it("cleanDeepLinkUrl edge cases", () => {
    assert.equal(cleanDeepLinkUrl("https://example.com/path#section"), "https://example.com/path")
    assert.equal(cleanDeepLinkUrl("not a url"), "not a url")
  })
})
