/**
 * TASK-TELEGRAM-SUPPORT: Telegram Support Channel Tests [RED / TDD]
 *
 * node --test test/javascript/telegram_support_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, mock } from "node:test"

import {
  SUPPORT_CHANNELS,
  DEFAULT_SUPPORT_CHANNEL,
  getSupportChannel,
  getAvailableSupportChannels
} from "../../app/frontend/lib/supportConfig.js"

import {
  openDeepLink,
  isValidDeepLink,
  cleanDeepLinkUrl
} from "../../app/frontend/lib/deepLink.js"

describe("Support Config (TASK-TELEGRAM-SUPPORT)", () => {
  it("SUPPORT_CHANNELS.TELEGRAM has correct URL without parameters", () => {
    const url = SUPPORT_CHANNELS.TELEGRAM.url;
    assert.equal(url, "https://t.me/code_black_support_bot");
    // Verify no user_id, phone, order_id in URL
    assert(!url.includes("user_id"));
    assert(!url.includes("phone"));
    assert(!url.includes("order_id"));
    assert(!url.includes("customer_key"));
  });

  it("SUPPORT_CHANNELS.TELEGRAM.id is 'telegram'", () => {
    assert.equal(SUPPORT_CHANNELS.TELEGRAM.id, "telegram");
  });

  it("SUPPORT_CHANNELS.EMAIL is placeholder (null URL, reserved for future)", () => {
    assert.equal(SUPPORT_CHANNELS.EMAIL.id, "email");
    assert.equal(SUPPORT_CHANNELS.EMAIL.url, null);
  });

  it("DEFAULT_SUPPORT_CHANNEL is TELEGRAM", () => {
    assert.equal(DEFAULT_SUPPORT_CHANNEL.id, SUPPORT_CHANNELS.TELEGRAM.id);
    assert.equal(DEFAULT_SUPPORT_CHANNEL.url, SUPPORT_CHANNELS.TELEGRAM.url);
  });

  it("getSupportChannel returns TELEGRAM channel by id", () => {
    const channel = getSupportChannel("telegram");
    assert.equal(channel.id, "telegram");
    assert.equal(channel.url, "https://t.me/code_black_support_bot");
  });

  it("getSupportChannel returns EMAIL channel by id", () => {
    const channel = getSupportChannel("email");
    assert.equal(channel.id, "email");
    assert.equal(channel.url, null);
  });

  it("getSupportChannel returns null for unknown channel id", () => {
    const channel = getSupportChannel("unknown");
    assert.equal(channel, null);
  });

  it("getAvailableSupportChannels returns array of all channels", () => {
    const channels = getAvailableSupportChannels();
    assert(Array.isArray(channels));
    assert.equal(channels.length, 2);
    assert.equal(channels[0].id, "telegram");
    assert.equal(channels[1].id, "email");
  });
});

describe("Deep Link Utilities (TASK-TELEGRAM-SUPPORT)", () => {
  it("openDeepLink calls window.open with URL and default target '_blank'", () => {
    const mockOpen = mock.fn();
    global.window = { open: mockOpen };

    openDeepLink("https://t.me/code_black_support_bot");

    assert.equal(mockOpen.mock.calls.length, 1);
    assert.deepEqual(mockOpen.mock.calls[0].arguments, [
      "https://t.me/code_black_support_bot",
      "_blank"
    ]);
  });

  it("openDeepLink calls window.open with custom target", () => {
    const mockOpen = mock.fn();
    global.window = { open: mockOpen };

    openDeepLink("https://t.me/code_black_support_bot", { target: "_self" });

    assert.equal(mockOpen.mock.calls.length, 1);
    assert.deepEqual(mockOpen.mock.calls[0].arguments, [
      "https://t.me/code_black_support_bot",
      "_self"
    ]);
  });

  it("openDeepLink does nothing if URL is empty", () => {
    const mockOpen = mock.fn();
    global.window = { open: mockOpen };

    openDeepLink("");
    openDeepLink(null);
    openDeepLink(undefined);

    assert.equal(mockOpen.mock.calls.length, 0);
  });

  it("isValidDeepLink returns true for valid https URL", () => {
    const result = isValidDeepLink("https://t.me/code_black_support_bot");
    assert.equal(result, true);
  });

  it("isValidDeepLink returns true for valid http URL", () => {
    const result = isValidDeepLink("http://example.com");
    assert.equal(result, true);
  });

  it("isValidDeepLink returns false for invalid URL", () => {
    const result = isValidDeepLink("not a url");
    assert.equal(result, false);
  });

  it("isValidDeepLink returns false for empty string", () => {
    const result = isValidDeepLink("");
    assert.equal(result, false);
  });

  it("cleanDeepLinkUrl removes query parameters", () => {
    const urlWithParams = "https://t.me/code_black_support_bot?user_id=123&phone=555";
    const cleaned = cleanDeepLinkUrl(urlWithParams);
    assert.equal(cleaned, "https://t.me/code_black_support_bot");
    assert(!cleaned.includes("user_id"));
    assert(!cleaned.includes("phone"));
  });

  it("cleanDeepLinkUrl removes hash fragments", () => {
    const urlWithHash = "https://example.com/path#section";
    const cleaned = cleanDeepLinkUrl(urlWithHash);
    assert.equal(cleaned, "https://example.com/path");
  });

  it("cleanDeepLinkUrl preserves pathname", () => {
    const url = "https://t.me/code_black_support_bot?param=value";
    const cleaned = cleanDeepLinkUrl(url);
    assert(cleaned.includes("code_black_support_bot"));
  });

  it("cleanDeepLinkUrl returns original URL if parsing fails", () => {
    const invalidUrl = "not a url";
    const result = cleanDeepLinkUrl(invalidUrl);
    assert.equal(result, invalidUrl);
  });
});

describe("Support Sheet Component Requirements (TASK-TELEGRAM-SUPPORT)", () => {
  it("TODO: SupportContactSheet component should render bottom sheet", () => {
    // [TDD RED] This test will pass once SupportContactSheet.svelte is implemented
    assert.fail("SupportContactSheet not yet implemented");
  });

  it("TODO: SupportContactSheet should show Email and Telegram options", () => {
    // [TDD RED] This test will pass once component displays both options
    assert.fail("SupportContactSheet not yet implemented");
  });

  it("TODO: SupportContactSheet should handle Telegram click without user data", () => {
    // [TDD RED] Verify no user_id, phone, order_id passed to openDeepLink
    assert.fail("SupportContactSheet not yet implemented");
  });

  it("TODO: Header should have support chat icon that opens sheet", () => {
    // [TDD RED] Header.svelte integration test
    assert.fail("Header support icon not yet implemented");
  });

  it("TODO: Profile should have 'Write us' button that opens sheet", () => {
    // [TDD RED] Profile.svelte integration test
    assert.fail("Profile support button not yet implemented");
  });

  it("TODO: Same sheet component used from both Header and Profile", () => {
    // [TDD RED] Verify unified experience across entry points
    assert.fail("Unified support sheet not yet implemented");
  });

  it("TODO: No Telegram Web App or iframe created", () => {
    // [TDD RED] Verify no tg:// scheme or initData passed
    assert.fail("Deep link validation not yet implemented");
  });

  it("TODO: Mobile deep link test: Telegram installed", () => {
    // [TDD RED] Simulate Android/iOS with native Telegram
    assert.fail("Mobile Telegram detection not yet tested");
  });

  it("TODO: Mobile deep link test: Telegram not installed", () => {
    // [TDD RED] Simulate mobile browser without Telegram
    assert.fail("Fallback to web.telegram not yet tested");
  });

  it("TODO: Desktop deep link test: opens new tab", () => {
    // [TDD RED] Simulate desktop browser
    assert.fail("Desktop deep link test not yet implemented");
  });

  it("TODO: Profile page regression: form, avatar, logout visible", () => {
    // [TDD RED] Ensure profile functionality not broken
    assert.fail("Profile regression test not yet implemented");
  });

  it("TODO: Header regression: logo, tenant switch, navigation intact", () => {
    // [TDD RED] Ensure header functionality not broken
    assert.fail("Header regression test not yet implemented");
  });
});
