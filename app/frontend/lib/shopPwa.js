import { api } from "./api.js"
import { isStandaloneEnv, reportInstallEvent } from "./shopInstallBanner.js"

export const PWA_FIRST_LAUNCH_KEY = "coffeeos_pwa_first_launch_v1"
export const PWA_INSTALL_REPORTED_KEY = "coffeeos_pwa_install_reported_v1"
const PWA_FIRST_LAUNCH_SESSION_KEY = "coffeeos_pwa_first_launch_session_v1"
const PWA_INSTALL_TRIED_KEY = "coffeeos_pwa_install_tried_v1"

let deferredInstallPrompt = null
let standaloneLaunchHandled = false

export function __resetShopPwaForTests() {
  standaloneLaunchHandled = false
}

export function installPromptAvailable() {
  return deferredInstallPrompt != null
}

export async function promptPwaInstall() {
  if (!deferredInstallPrompt) return false
  deferredInstallPrompt.prompt()
  const { outcome } = await deferredInstallPrompt.userChoice
  deferredInstallPrompt = null
  return outcome === "accepted"
}

/** #77: best-effort telemetry — never throw into UI. */
function reportPwaInstalled() {
  try {
    api("/pwa_install", { method: "POST" }).catch((err) => {
      console.warn("[shop-pwa] appinstalled report failed", err)
    })
  } catch (err) {
    console.warn("[shop-pwa] appinstalled report failed", err)
  }
}

function storageOf(env, name) {
  try {
    const s = env[name]
    return s && typeof s.getItem === "function" ? s : null
  } catch {
    return null
  }
}

/** true — метка поставлена сейчас, false — уже стояла, null — хранилище недоступно. */
function markOnce(storage, key) {
  if (!storage) return null
  try {
    if (storage.getItem(key) === "1") return false
    storage.setItem(key, "1")
    return true
  } catch {
    return null
  }
}

/** TASK_111 Subtask 6: первый запуск с иконки на устройстве; без localStorage — раз за сессию. */
function reportFirstLaunch(env, eventOpts) {
  let fresh = markOnce(storageOf(env, "localStorage"), PWA_FIRST_LAUNCH_KEY)
  if (fresh === null) fresh = markOnce(storageOf(env, "sessionStorage"), PWA_FIRST_LAUNCH_SESSION_KEY)
  if (fresh === false) return
  reportInstallEvent("pwa_first_launch", { ...eventOpts, env })
}

/**
 * TASK_111 Subtask 7: отметка установки с иконки (на iPhone appinstalled не приходит).
 * Невошедшему сервер отвечает 401 — метки нет, попытка в следующей сессии.
 */
function reportInstallMark(env, apiFn) {
  const local = storageOf(env, "localStorage")
  try {
    if (local?.getItem(PWA_INSTALL_REPORTED_KEY) === "1") return
  } catch {
    /* хранилище недоступно — попытка раз за сессию */
  }
  if (markOnce(storageOf(env, "sessionStorage"), PWA_INSTALL_TRIED_KEY) === false) return
  Promise.resolve()
    .then(() => apiFn("/pwa_install", { method: "POST" }))
    .then(() => {
      try {
        local?.setItem(PWA_INSTALL_REPORTED_KEY, "1")
      } catch {
        /* повтор в следующей сессии, сервер идемпотентен */
      }
    })
    .catch(() => {})
}

/**
 * Запуск с иконки (standalone): событие первого запуска и отметка установки.
 * Не блокирует: ничего не ждёт и не бросает.
 * @returns {boolean} true — витрина открыта в standalone
 */
export function reportStandaloneLaunch(opts = {}) {
  if (standaloneLaunchHandled) return false
  standaloneLaunchHandled = true
  const { env = globalThis, apiFn = api, ...eventOpts } = opts
  try {
    if (!isStandaloneEnv(env)) return false
    reportFirstLaunch(env, eventOpts)
    reportInstallMark(env, apiFn)
    return true
  } catch {
    return false
  }
}

export function initShopPwa() {
  if (!("serviceWorker" in navigator)) return

  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault()
    deferredInstallPrompt = event
    window.dispatchEvent(new CustomEvent("shop:pwa-installable"))
  })

  window.addEventListener("appinstalled", () => {
    deferredInstallPrompt = null
    reportPwaInstalled()
  })

  const register = () => {
    navigator.serviceWorker
      .register("/shop/service-worker.js", { scope: "/shop/" })
      .catch((err) => console.warn("[shop-pwa] SW register failed", err))
  }

  if (document.readyState === "complete") {
    register()
  } else {
    window.addEventListener("load", register, { once: true })
  }
}
