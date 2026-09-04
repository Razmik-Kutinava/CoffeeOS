/**
 * #77: load point subscription_offer + profile eligibility for CTA machine.
 * Failures → safe defaults (offer off / not eligible).
 */
import { api } from "./api.js"

/** @type {null | {
 *   subscriptionOfferEnabled: boolean,
 *   secondCtaMode: "tips"|"subscription",
 *   eligibleForSubscriptionOffer: boolean
 * }} */
let cache = null
/** @type {Promise<typeof cache> | null} */
let inflight = null

export function subscriptionOfferCtaDefaults() {
  return {
    subscriptionOfferEnabled: false,
    secondCtaMode: /** @type {"tips"|"subscription"} */ ("tips"),
    eligibleForSubscriptionOffer: false
  }
}

export async function loadSubscriptionOfferCta() {
  if (cache) return cache
  if (inflight) return inflight

  inflight = (async () => {
    const next = subscriptionOfferCtaDefaults()
    try {
      const cfg = await api("/config")
      const offer = cfg?.subscription_offer || {}
      next.subscriptionOfferEnabled = Boolean(offer.enabled)
      next.secondCtaMode = offer.second_cta_mode === "subscription" ? "subscription" : "tips"
    } catch {
      /* keep defaults */
    }
    try {
      const profile = await api("/profile")
      next.eligibleForSubscriptionOffer = Boolean(profile?.eligible_for_subscription_offer)
    } catch {
      /* unauth → not eligible */
    }
    cache = next
    return cache
  })()

  try {
    return await inflight
  } finally {
    inflight = null
  }
}

/** Test/helper: drop cache after settings change. */
export function clearSubscriptionOfferCtaCache() {
  cache = null
}
