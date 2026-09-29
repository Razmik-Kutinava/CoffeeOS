/**
 * TASK_96: оффер подписки — баннер на статусе заказа, карточка в ЛК, UTM deep link, события воронки.
 * Решение о показе принимает backend (профиль); frontend только читает флаги.
 * Любая ошибка сети → оффер скрыт, экраны статуса/ЛК не ломаются.
 */
import { api, withTenantQuery } from "./api.js"

/** Экрана оформления подписки ещё нет (billing UI, Задача-3) — синхронно с OfferPushNotifier::TARGET_URL. */
export const OFFER_TARGET_PATH = "/profile"
export const OFFER_UTM_CAMPAIGN = "subscription_offer"
export const OFFER_CREATIVE_VERSION = "v1"

const OPENED_URL = "/shop/api/subscription_offer/opened"

/** @param {"banner"|"lk"|"push"} channel */
export function offerUtm(channel) {
  return {
    utm_campaign: OFFER_UTM_CAMPAIGN,
    utm_content: `${channel}_${OFFER_CREATIVE_VERSION}`,
    offer_channel: channel
  }
}

/** @param {"banner"|"lk"} channel */
export function buildOfferLink(channel) {
  const utm = offerUtm(channel)
  const q = new URLSearchParams({
    offer_channel: utm.offer_channel,
    utm_campaign: utm.utm_campaign,
    utm_content: utm.utm_content
  })
  return `${OFFER_TARGET_PATH}?${q.toString()}`
}

export function bannerVisible({ order, profile }) {
  return order?.status === "ready" && profile?.should_show_banner === true
}

/**
 * @param {{ profile: any, hasActiveSubscription: boolean|null }} input
 * hasActiveSubscription === null — состояние неизвестно → карточку не показываем.
 */
export function lkCardView({ profile, hasActiveSubscription }) {
  const visible =
    Boolean(profile?.eligible_for_subscription_offer) && hasActiveSubscription === false
  return { visible, unread: visible && profile?.has_unread_offer_in_lk === true }
}

export async function loadOfferProfile(apiFn = api) {
  try {
    return (await apiFn("/profile")) || null
  } catch {
    return null
  }
}

/** true — есть активная подписка, false — нет (404), null — не удалось узнать. */
export async function loadHasActiveSubscription(apiFn = api) {
  try {
    await apiFn("/subscriptions/current")
    return true
  } catch (e) {
    return e?.httpStatus === 404 ? false : null
  }
}

const shownOrderIds = new Set()

/** Фиксирует показ баннера один раз на заказ за жизнь страницы. */
export async function markShownOnce(orderId, apiFn = api) {
  const key = String(orderId || "")
  if (!key || shownOrderIds.has(key)) return false
  shownOrderIds.add(key)
  try {
    await apiFn("/subscription_offer/shown", { method: "POST" })
  } catch {
    /* показ уже отрисован — без retry */
  }
  return true
}

export async function dismissOffer(apiFn = api) {
  try {
    await apiFn("/subscription_offer/dismiss", { method: "POST" })
  } catch {
    /* баннер уже скрыт локально — без retry */
  }
}

export async function markOfferViewed(apiFn = api) {
  try {
    await apiFn("/subscription_offer/viewed", { method: "POST" })
  } catch {
    /* индикатор уже погашен оптимистично */
  }
}

/**
 * Неблокирующее событие открытия оффера: sendBeacon, иначе fetch keepalive без await.
 * @returns {boolean} true — ушло через beacon
 */
export function trackOfferOpened(channel, opts = {}) {
  const beacon =
    "beacon" in opts
      ? opts.beacon
      : typeof navigator !== "undefined" && typeof navigator.sendBeacon === "function"
        ? navigator.sendBeacon.bind(navigator)
        : null
  const fetchFn = opts.fetchFn || (typeof fetch === "function" ? fetch : null)
  const resolveUrl = opts.resolveUrl || withTenantQuery
  const utm = offerUtm(channel)
  const body = JSON.stringify({
    channel,
    utm_campaign: utm.utm_campaign,
    utm_content: utm.utm_content,
    ...(opts.extra || {})
  })

  let url = OPENED_URL
  try {
    url = resolveUrl(OPENED_URL)
  } catch {
    /* без tenant query — сервер возьмёт точку из сессии/meta */
  }

  try {
    if (beacon && beacon(url, new Blob([body], { type: "application/json" }))) return true
  } catch {
    /* fallback ниже */
  }

  if (fetchFn) {
    try {
      Promise.resolve(
        fetchFn(url, {
          method: "POST",
          keepalive: true,
          credentials: "same-origin",
          headers: { "Content-Type": "application/json", Accept: "application/json" },
          body
        })
      ).catch(() => {})
    } catch {
      /* аналитика не блокирует навигацию */
    }
  }
  return false
}

/** Параметры оффера из hash deep link (`#/profile?offer_channel=push&…`). */
export function readOfferParams(hash) {
  const query = String(hash || "").split("?")[1]
  if (!query) return null
  const q = new URLSearchParams(query)
  const channel = q.get("offer_channel")
  if (!channel) return null
  return {
    channel,
    utm_campaign: q.get("utm_campaign") || "",
    utm_content: q.get("utm_content") || "",
    push_notification_id: q.get("push_notification_id") || ""
  }
}
