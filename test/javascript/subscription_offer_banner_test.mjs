/**
 * TASK_96 [TDD][RED] Subtask 1–6, 12, 26–28: баннер оффера подписки на статусе заказа.
 *
 * node --test test/javascript/subscription_offer_banner_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

import {
  OFFER_TARGET_PATH,
  bannerVisible,
  buildOfferLink,
  dismissOffer,
  loadOfferProfile,
  markShownOnce,
  offerUtm,
  trackOfferOpened
} from "../../app/frontend/lib/subscriptionOffer.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const read = (p) => readFileSync(join(root, p), "utf8")

function recordingApi(impl = async () => ({})) {
  const calls = []
  const fn = async (path, opts = {}) => {
    calls.push({ path, method: opts.method || "GET", body: opts.body })
    return impl(path, opts)
  }
  fn.calls = calls
  return fn
}

describe("TASK_96 — bannerVisible", () => {
  const profile = { should_show_banner: true }

  it("ready + should_show_banner → visible", () => {
    assert.equal(bannerVisible({ order: { status: "ready" }, profile }), true)
  })

  it("other statuses → hidden", () => {
    for (const status of ["pending_payment", "accepted", "preparing", "issued", "cancelled"]) {
      assert.equal(bannerVisible({ order: { status }, profile }), false, status)
    }
  })

  it("should_show_banner false → hidden (no own reasoning on frontend)", () => {
    assert.equal(
      bannerVisible({ order: { status: "ready" }, profile: { should_show_banner: false, eligible_for_subscription_offer: true } }),
      false
    )
  })

  it("no session / profile error / missing fields → hidden", () => {
    assert.equal(bannerVisible({ order: { status: "ready" }, profile: null }), false)
    assert.equal(bannerVisible({ order: { status: "ready" }, profile: {} }), false)
    assert.equal(bannerVisible({ order: null, profile }), false)
  })
})

describe("TASK_96 — loadOfferProfile", () => {
  it("returns profile on success", async () => {
    const api = recordingApi(async () => ({ id: "c1", should_show_banner: true }))
    const p = await loadOfferProfile(api)
    assert.equal(p.should_show_banner, true)
    assert.equal(api.calls[0].path, "/profile")
  })

  it("401 / network error → null, never throws", async () => {
    const api = recordingApi(async () => {
      const e = new Error("Требуется авторизация")
      e.httpStatus = 401
      throw e
    })
    assert.equal(await loadOfferProfile(api), null)
  })
})

describe("TASK_96 — markShownOnce", () => {
  it("POSTs shown once per order view; repeat renders do not re-post", async () => {
    const api = recordingApi()
    assert.equal(await markShownOnce("ord-shown-1", api), true)
    assert.equal(await markShownOnce("ord-shown-1", api), false)
    assert.equal(await markShownOnce("ord-shown-1", api), false)
    assert.deepEqual(api.calls.map((c) => [c.method, c.path]), [["POST", "/subscription_offer/shown"]])
  })

  it("request error is swallowed", async () => {
    const api = recordingApi(async () => {
      throw new Error("500")
    })
    await assert.doesNotReject(() => markShownOnce("ord-shown-err", api))
  })
})

describe("TASK_96 — dismissOffer", () => {
  it("POSTs dismiss once; error does not retry or throw", async () => {
    const api = recordingApi(async () => {
      throw new Error("network")
    })
    await assert.doesNotReject(() => dismissOffer(api))
    assert.deepEqual(api.calls.map((c) => [c.method, c.path]), [["POST", "/subscription_offer/dismiss"]])
  })
})

describe("TASK_96 — UTM deep link", () => {
  it("offerUtm per channel", () => {
    assert.deepEqual(offerUtm("banner"), {
      utm_campaign: "subscription_offer",
      utm_content: "banner_v1",
      offer_channel: "banner"
    })
    assert.equal(offerUtm("lk").utm_content, "lk_v1")
  })

  it("buildOfferLink carries utm_campaign, utm_content and channel", () => {
    const link = buildOfferLink("banner")
    assert.ok(link.startsWith(`${OFFER_TARGET_PATH}?`), link)
    const q = new URLSearchParams(link.split("?")[1])
    assert.equal(q.get("offer_channel"), "banner")
    assert.equal(q.get("utm_campaign"), "subscription_offer")
    assert.equal(q.get("utm_content"), "banner_v1")
  })
})

describe("TASK_96 — trackOfferOpened (non-blocking)", () => {
  it("uses sendBeacon and returns synchronously", () => {
    const sent = []
    const beacon = (url, body) => {
      sent.push({ url, body })
      return true
    }
    const fetchFn = () => {
      throw new Error("fetch must not be used when beacon succeeds")
    }
    const result = trackOfferOpened("banner", { beacon, fetchFn, resolveUrl: (u) => u })
    assert.equal(result, true)
    assert.ok(!(result instanceof Promise))
    assert.equal(sent.length, 1)
    assert.equal(sent[0].url, "/shop/api/subscription_offer/opened")
  })

  it("beacon payload has channel + utm", async () => {
    let blob = null
    trackOfferOpened("lk", {
      beacon: (_u, b) => {
        blob = b
        return true
      },
      resolveUrl: (u) => u
    })
    const payload = JSON.parse(await blob.text())
    assert.equal(payload.channel, "lk")
    assert.equal(payload.utm_campaign, "subscription_offer")
    assert.equal(payload.utm_content, "lk_v1")
  })

  it("beacon unavailable/false → fetch keepalive fire-and-forget, rejection swallowed", async () => {
    const calls = []
    const fetchFn = (url, opts) => {
      calls.push({ url, opts })
      return Promise.reject(new Error("offline"))
    }
    const result = trackOfferOpened("banner", { beacon: () => false, fetchFn, resolveUrl: (u) => u })
    assert.equal(result, false)
    assert.equal(calls.length, 1)
    assert.equal(calls[0].opts.method, "POST")
    assert.equal(calls[0].opts.keepalive, true)
    await new Promise((r) => setTimeout(r, 0))
  })

  it("extra fields (push_notification_id) are passed through", async () => {
    let blob = null
    trackOfferOpened("push", {
      beacon: (_u, b) => {
        blob = b
        return true
      },
      resolveUrl: (u) => u,
      extra: { push_notification_id: "pn-1" }
    })
    const payload = JSON.parse(await blob.text())
    assert.equal(payload.channel, "push")
    assert.equal(payload.push_notification_id, "pn-1")
  })
})

describe("TASK_96 — SubscriptionOfferBanner.svelte wiring", () => {
  const src = read("app/frontend/components/SubscriptionOfferBanner.svelte")

  it("uses module helpers (visibility, shown, dismiss, opened, link)", () => {
    for (const fn of ["bannerVisible", "loadOfferProfile", "markShownOnce", "dismissOffer", "trackOfferOpened", "buildOfferLink"]) {
      assert.match(src, new RegExp(fn), fn)
    }
  })

  it("has testids, close control and swipe handling", () => {
    assert.match(src, /data-testid="subscription-offer-banner"/)
    assert.match(src, /data-testid="subscription-offer-banner-close"/)
    assert.match(src, /ontouchstart/)
    assert.match(src, /ontouchend/)
  })

  it("is not a fixed overlay (flows under the status widget)", () => {
    assert.doesNotMatch(src, /position:\s*fixed/)
  })
})

describe("TASK_96 — OrderStatus mount point only", () => {
  const src = read("app/frontend/routes/OrderStatus.svelte")

  it("imports and mounts SubscriptionOfferBanner with the order", () => {
    assert.match(src, /import SubscriptionOfferBanner from "..\/components\/SubscriptionOfferBanner.svelte"/)
    assert.match(src, /<SubscriptionOfferBanner\s+\{order\}\s*\/>/)
  })

  it("banner sits after the progress block and before «Состав заказа»", () => {
    const progress = src.indexOf('class="progress-wrap"')
    const banner = src.indexOf("<SubscriptionOfferBanner")
    const receipt = src.indexOf("Состав заказа")
    assert.ok(progress > 0 && banner > progress && receipt > banner, { progress, banner, receipt })
  })

  it("status widget structure is intact", () => {
    assert.match(src, /class="status-hero"/)
    assert.match(src, /class="progress-track"/)
    assert.match(src, /class="progress-steps"/)
  })
})
