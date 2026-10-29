/**
 * TASK_111: плашка установки на главный экран — кому показывать, память крестика,
 * «приложение установлено» по профилю и события воронки установки (таблица TASK_112).
 * Всё под try/catch: сбой хранилища или сети плашку скрывает или оставляет, но витрину не ломает.
 */
import { getDeviceOS } from "./deviceDetect.js"
import { collectPushEnvironment, inAppLabel, sendEnvironmentEvent } from "./pushEnvironment.js"
import { loadOfferProfile } from "./subscriptionOffer.js"

export const INSTALL_BANNER_TEXT = "Установить CoffeeOS на главный экран"
export const INSTALL_BANNER_HOW = "Как установить"
export const INSTALL_BANNER_INSTALL = "Установить"
export const INSTALL_BANNER_CLOSE_LABEL = "Закрыть"
export const IOS_INSTALL_TITLE = "Как установить CoffeeOS"
export const IOS_INSTALL_STEPS = Object.freeze([
  "Нажмите «Поделиться» в панели браузера",
  "Выберите «На экран «Домой»»",
  "Откройте CoffeeOS с иконки на главном экране"
])
export const IOS_INSTALL_DONE = "Понятно"

/** Когда закрытая крестиком плашка появляется снова. */
export const INSTALL_BANNER_REAPPEAR = "next_session"
const REAPPEAR_STORAGE = { next_session: "sessionStorage" }

export const INSTALL_BANNER_DISMISS_KEY = "coffeeos_shop_install_banner_dismissed_v1"
export const INSTALL_BANNER_SHOWN_KEY = "coffeeos_shop_install_banner_shown_v1"
export const INSTALL_PROFILE_KEY = "coffeeos_shop_install_profile_v1"

export const INSTALL_EVENT_KINDS = Object.freeze([
  "install_banner_shown",
  "install_banner_tap",
  "install_banner_dismiss",
  "pwa_first_launch"
])

function freshState() {
  return { dismissed: false, shown: false, installed: undefined, inflight: null }
}

let state = freshState()

export function __resetInstallBannerForTests() {
  state = freshState()
}

function storageOf(env, name) {
  try {
    const s = env[name]
    return s && typeof s.getItem === "function" ? s : null
  } catch {
    return null
  }
}

function readItem(storage, key) {
  try {
    return storage ? storage.getItem(key) : null
  } catch {
    return null
  }
}

function writeItem(storage, key, value) {
  try {
    storage?.setItem(key, value)
  } catch {
    /* остаётся память страницы */
  }
}

function deviceOs(env) {
  const nav = env.navigator
  return getDeviceOS({
    userAgent: nav?.userAgent,
    platform: nav?.platform,
    maxTouchPoints: nav?.maxTouchPoints,
    hasWindow: true
  })
}

export function isStandaloneEnv(env = globalThis) {
  try {
    if (env.navigator?.standalone === true) return true
    return typeof env.matchMedia === "function" && Boolean(env.matchMedia("(display-mode: standalone)")?.matches)
  } catch {
    return false
  }
}

/** iPhone в браузере (не с иконки, не во встроенном браузере — Subtask 5 отложен). */
export function iosInstallEligible(env = globalThis) {
  try {
    return deviceOs(env) === "ios" && !isStandaloneEnv(env) && inAppLabel(env.navigator?.userAgent) === "none"
  } catch {
    return false
  }
}

export function bannerDismissed(env = globalThis) {
  if (state.dismissed) return true
  return readItem(storageOf(env, REAPPEAR_STORAGE[INSTALL_BANNER_REAPPEAR]), INSTALL_BANNER_DISMISS_KEY) === "1"
}

export function dismissBanner(env = globalThis) {
  state.dismissed = true
  writeItem(storageOf(env, REAPPEAR_STORAGE[INSTALL_BANNER_REAPPEAR]), INSTALL_BANNER_DISMISS_KEY, "1")
}

/**
 * Установлено ли приложение по профилю вошедшего гостя: не больше одного запроса за сессию.
 * Нет профиля (не вошёл) или ошибка — «не установлено».
 * @returns {Promise<boolean>}
 */
export function resolveInstalled({ env = globalThis, loadProfile = loadOfferProfile } = {}) {
  if (state.installed !== undefined) return Promise.resolve(state.installed)
  const cached = readItem(storageOf(env, "sessionStorage"), INSTALL_PROFILE_KEY)
  if (cached === "1" || cached === "0") {
    state.installed = cached === "1"
    return Promise.resolve(state.installed)
  }
  if (!state.inflight) {
    const current = state
    current.inflight = Promise.resolve()
      .then(() => loadProfile())
      .then(
        (profile) => profile?.pwa_installed === true,
        () => false
      )
      .then((installed) => {
        current.installed = installed
        current.inflight = null
        writeItem(storageOf(env, "sessionStorage"), INSTALL_PROFILE_KEY, installed ? "1" : "0")
        return installed
      })
  }
  return state.inflight
}

/**
 * Какую плашку показать: "ios" | "android" | null.
 * Профиль запрашивается только там, где плашка иначе была бы показана.
 */
export async function decideBannerVariant({ installable = false, env = globalThis, loadProfile = loadOfferProfile } = {}) {
  if (isStandaloneEnv(env) || bannerDismissed(env)) return null
  let ios = false
  try {
    ios = deviceOs(env) === "ios"
  } catch {
    return null
  }
  const variant = ios ? (iosInstallEligible(env) ? "ios" : null) : installable ? "android" : null
  if (!variant) return null
  return (await resolveInstalled({ env, loadProfile })) ? null : variant
}

/**
 * Событие воронки установки: снимок окружения TASK_112 с подменой event_kind, без данных гостя.
 * @returns {boolean} true — отправка запущена
 */
export function reportInstallEvent(kind, opts = {}) {
  if (!INSTALL_EVENT_KINDS.includes(kind)) return false
  try {
    const env = opts.env || globalThis
    const body = JSON.stringify({ ...collectPushEnvironment(env), event_kind: kind })
    sendEnvironmentEvent(body, opts, env)
    return true
  } catch {
    return false
  }
}

export function reportBannerShownOnce(opts = {}) {
  if (state.shown) return false
  state.shown = true
  const session = storageOf(opts.env || globalThis, "sessionStorage")
  if (readItem(session, INSTALL_BANNER_SHOWN_KEY) === "1") return false
  writeItem(session, INSTALL_BANNER_SHOWN_KEY, "1")
  return reportInstallEvent("install_banner_shown", opts)
}
