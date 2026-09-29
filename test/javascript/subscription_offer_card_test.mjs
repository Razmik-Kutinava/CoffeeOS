/**
 * TASK_96 [TDD][RED] Subtask 7–11, 13, 26–27, 30: карточка оффера в ЛК + push deep link.
 *
 * node --test test/javascript/subscription_offer_card_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

import {
  lkCardView,
  loadHasActiveSubscription,
  markOfferViewed,
  readOfferParams
} from "../../app/frontend/lib/subscriptionOffer.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const read = (p) => readFileSync(join(root, p), "utf8")

function httpError(status) {
  const e = new Error(`HTTP ${status}`)
  e.httpStatus = status
  return e
}

describe("TASK_96 — lkCardView", () => {
  const eligible = { eligible_for_subscription_offer: true, has_unread_offer_in_lk: false }

  it("eligible + no active subscription → card visible", () => {
    assert.deepEqual(lkCardView({ profile: eligible, hasActiveSubscription: false }), { visible: true, unread: false })
  })

  it("unread flag → indicator", () => {
    assert.deepEqual(
      lkCardView({ profile: { ...eligible, has_unread_offer_in_lk: true }, hasActiveSubscription: false }),
      { visible: true, unread: true }
    )
  })

  it("not eligible → no card", () => {
    assert.equal(
      lkCardView({ profile: { eligible_for_subscription_offer: false, has_unread_offer_in_lk: true }, hasActiveSubscription: false }).visible,
      false
    )
  })

  it("purchased (active subscription) → no card, no indicator", () => {
    assert.deepEqual(
      lkCardView({ profile: { ...eligible, has_unread_offer_in_lk: true }, hasActiveSubscription: true }),
      { visible: false, unread: false }
    )
  })

  it("state unavailable (profile null or subscription unknown) → no card", () => {
    assert.equal(lkCardView({ profile: null, hasActiveSubscription: false }).visible, false)
    assert.equal(lkCardView({ profile: eligible, hasActiveSubscription: null }).visible, false)
  })
})

describe("TASK_96 — loadHasActiveSubscription", () => {
  it("200 → true", async () => {
    assert.equal(await loadHasActiveSubscription(async () => ({ id: "s1", status: "active" })), true)
  })

  it("404 → false", async () => {
    assert.equal(
      await loadHasActiveSubscription(async () => {
        throw httpError(404)
      }),
      false
    )
  })

  it("other errors → null (unknown)", async () => {
    assert.equal(
      await loadHasActiveSubscription(async () => {
        throw httpError(500)
      }),
      null
    )
    assert.equal(
      await loadHasActiveSubscription(async () => {
        throw new Error("offline")
      }),
      null
    )
  })

  it("calls /subscriptions/current", async () => {
    const paths = []
    await loadHasActiveSubscription(async (p) => {
      paths.push(p)
      return {}
    })
    assert.deepEqual(paths, ["/subscriptions/current"])
  })
})

describe("TASK_96 — markOfferViewed", () => {
  it("POSTs viewed; error swallowed", async () => {
    const calls = []
    await assert.doesNotReject(() =>
      markOfferViewed(async (path, opts = {}) => {
        calls.push([opts.method, path])
        throw new Error("500")
      })
    )
    assert.deepEqual(calls, [["POST", "/subscription_offer/viewed"]])
  })
})

describe("TASK_96 — readOfferParams (push deep link)", () => {
  it("parses channel + utm + push_notification_id from hash query", () => {
    const p = readOfferParams(
      "#/profile?offer_channel=push&utm_campaign=subscription_offer&utm_content=push_v1&push_notification_id=pn-9"
    )
    assert.deepEqual(p, {
      channel: "push",
      utm_campaign: "subscription_offer",
      utm_content: "push_v1",
      push_notification_id: "pn-9"
    })
  })

  it("no offer params → null", () => {
    assert.equal(readOfferParams("#/profile"), null)
    assert.equal(readOfferParams(""), null)
  })
})

describe("TASK_96 — SubscriptionOfferCard.svelte wiring", () => {
  const src = read("app/frontend/components/SubscriptionOfferCard.svelte")

  it("uses module helpers", () => {
    for (const fn of ["lkCardView", "loadOfferProfile", "loadHasActiveSubscription", "markOfferViewed", "trackOfferOpened", "buildOfferLink", "readOfferParams"]) {
      assert.match(src, new RegExp(fn), fn)
    }
  })

  it("opens with lk channel and tracks push opens", () => {
    assert.match(src, /trackOfferOpened\("lk"/)
    assert.match(src, /buildOfferLink\("lk"\)/)
    assert.match(src, /trackOfferOpened\("push"/)
  })

  it("has card + unread indicator testids", () => {
    assert.match(src, /data-testid="subscription-offer-card"/)
    assert.match(src, /data-testid="subscription-offer-unread"/)
  })
})

describe("TASK_96 — Profile mount point only", () => {
  const src = read("app/frontend/routes/Profile.svelte")

  it("imports and mounts the card after PLG slots, before history", () => {
    assert.match(src, /import SubscriptionOfferCard from "..\/components\/SubscriptionOfferCard.svelte"/)
    const plg = src.indexOf("<PlgBlockSection />")
    const card = src.indexOf("<SubscriptionOfferCard />")
    const history = src.indexOf('data-testid="shop-lk-order-history"')
    assert.ok(plg > 0 && card > plg && history > card, { plg, card, history })
  })

  it("history + repeat stay wired (TASK_94)", () => {
    assert.match(src, /data-testid="shop-lk-repeat-btn"/)
    assert.match(src, /onRepeatHistory\(order\)/)
  })
})

describe("TASK_96 — service worker opens offer_url for offer push", () => {
  const sw = read("app/views/shop/firebase_sw/show.js.erb")

  it("offer_url branch runs before order_id guard; order branches untouched", () => {
    const offer = sw.indexOf("data.offer_url")
    const guard = sw.indexOf("if (!orderId) return;")
    assert.ok(offer > 0 && guard > offer, { offer, guard })
    assert.match(sw, /openClient\(String\(data\.offer_url\)\)/)
    assert.match(sw, /action === "cancel" \|\| action === "chat" \|\| action === "tips"/)
  })
})
