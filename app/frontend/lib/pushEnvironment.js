/**
 * TASK_112: снимок окружения при открытии витрины — одно событие session_open на вкладку.
 * Только читает возможности браузера: requestPermission, регистрацию Service Worker
 * и registerShopPush не вызывает. Метка встроенного браузера — эвристика для статистики,
 * логика витрины по ней не ветвится.
 */
import { withTenantQuery } from "./api.js"
import { getDeviceOS } from "./deviceDetect.js"
import { isTelegramInAppBrowser } from "./shopWebView.js"

export const ENVIRONMENT_EVENTS_URL = "/shop/api/environment_events"
export const ENV_PROBE_KEY = "__coffeeos_env_probe__"
export const SESSION_OPEN_GUARD_KEY = "coffeeos_env_session_open_v1"

const UA_SNIPPET_MAX = 300
const NOTIFICATION_STATES = ["default", "granted", "denied"]

let sessionOpenReported = false

export function resetSessionOpenGuardForTests() {
  sessionOpenReported = false
}

/** Своя проба (не probeStorage из shopWebView.js): геттер, запись и удаление пробного ключа. */
export function storageAvailable(getStorage) {
  let storage = null
  try {
    storage = getStorage()
    if (!storage) return "unavailable"
    storage.setItem(ENV_PROBE_KEY, "1")
    return storage.getItem(ENV_PROBE_KEY) === "1" ? "available" : "unavailable"
  } catch {
    return "unavailable"
  } finally {
    try {
      storage?.removeItem(ENV_PROBE_KEY)
    } catch {
      /* ignore */
    }
  }
}

export function inAppLabel(ua) {
  const s = String(ua || "")
  if (!s) return "none"
  if (isTelegramInAppBrowser(s)) return "telegram"
  if (/Instagram/i.test(s)) return "instagram"
  if (/FBAN|FBAV|FBIOS|FB_IAB/i.test(s)) return "facebook"
  if (/Android/i.test(s) && /;\s*wv\)/.test(s)) return "other_inapp"
  if (/iPhone|iPad|iPod/i.test(s) && /Mobile\//.test(s) && !/Safari\//.test(s)) return "other_inapp"
  return "none"
}

/** Конец строки важнее начала: там имя приложения. */
export function uaSnippet(ua, label) {
  if (label !== "other_inapp") return null
  const s = String(ua || "")
  return s ? s.slice(-UA_SNIPPET_MAX) : null
}

function standaloneState(env) {
  try {
    const nav = env.navigator || {}
    if (nav.standalone === true) return "standalone"
    if (typeof env.matchMedia !== "function") {
      return typeof nav.standalone === "boolean" ? "browser" : "unavailable"
    }
    return env.matchMedia("(display-mode: standalone)")?.matches ? "standalone" : "browser"
  } catch {
    return "unavailable"
  }
}

function notificationState(env) {
  try {
    if (!("Notification" in env) || !env.Notification) return "unavailable"
    const permission = env.Notification.permission
    return NOTIFICATION_STATES.includes(permission) ? permission : "unavailable"
  } catch {
    return "unavailable"
  }
}

function availability(check) {
  try {
    return check() ? "available" : "unavailable"
  } catch {
    return "unavailable"
  }
}

function osFamily(nav) {
  try {
    const os = getDeviceOS({
      userAgent: nav?.userAgent,
      platform: nav?.platform,
      maxTouchPoints: nav?.maxTouchPoints,
      hasWindow: true
    })
    return os === "ios" || os === "android" ? os : "other"
  } catch {
    return "other"
  }
}

export function collectPushEnvironment(env = globalThis) {
  let nav = null
  try {
    nav = env.navigator || null
  } catch {
    nav = null
  }
  let ua = ""
  try {
    ua = String(nav?.userAgent || "")
  } catch {
    ua = ""
  }
  const label = inAppLabel(ua)

  return {
    event_kind: "session_open",
    os_family: osFamily(nav),
    standalone: standaloneState(env),
    notification_state: notificationState(env),
    push_manager: availability(() => "PushManager" in env && Boolean(env.PushManager)),
    service_worker: availability(() => Boolean(nav) && "serviceWorker" in nav),
    storage_local: storageAvailable(() => env.localStorage),
    storage_session: storageAvailable(() => env.sessionStorage),
    inapp_label: label,
    ua_snippet: uaSnippet(ua, label)
  }
}

function guardStorage(env) {
  try {
    const s = env.sessionStorage
    return s && typeof s.getItem === "function" ? s : null
  } catch {
    return null
  }
}

function alreadyReportedInTab(env) {
  try {
    return guardStorage(env)?.getItem(SESSION_OPEN_GUARD_KEY) === "1"
  } catch {
    return false
  }
}

function markReportedInTab(env) {
  try {
    guardStorage(env)?.setItem(SESSION_OPEN_GUARD_KEY, "1")
  } catch {
    /* защита остаётся в памяти страницы */
  }
}

function nativeBeacon(env) {
  try {
    const nav = env.navigator
    return nav && typeof nav.sendBeacon === "function" ? nav.sendBeacon.bind(nav) : null
  } catch {
    return null
  }
}

function nativeFetch(env) {
  try {
    return typeof env.fetch === "function" ? env.fetch.bind(env) : null
  } catch {
    return null
  }
}

function send(body, opts, env) {
  const beacon = "beacon" in opts ? opts.beacon : nativeBeacon(env)
  const fetchFn = "fetchFn" in opts ? opts.fetchFn : nativeFetch(env)
  const resolveUrl = opts.resolveUrl || withTenantQuery

  let url = ENVIRONMENT_EVENTS_URL
  try {
    url = resolveUrl(ENVIRONMENT_EVENTS_URL)
  } catch {
    /* без tenant query — сервер определит точку сам */
  }

  try {
    if (beacon && beacon(url, new Blob([body], { type: "application/json" }))) return
  } catch {
    /* fallback ниже */
  }

  if (!fetchFn) return
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
    /* ignore */
  }
}

/** TASK_110: события воронки согласия на push уходят тем же способом. */
export { send as sendEnvironmentEvent }

/**
 * Одно событие session_open за вкладку (sessionStorage), при недоступном хранилище — за жизнь страницы.
 * Флаг ставится до отправки: при сбое сети повтора нет.
 * @returns {boolean} true — отправка запущена
 */
export function reportSessionOpenOnce(opts = {}) {
  const env = opts.env || globalThis
  if (sessionOpenReported) return false
  sessionOpenReported = true
  if (alreadyReportedInTab(env)) return false
  markReportedInTab(env)

  let body
  try {
    body = JSON.stringify(collectPushEnvironment(env))
  } catch {
    return false
  }
  send(body, opts, env)
  return true
}
