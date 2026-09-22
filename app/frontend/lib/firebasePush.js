import { initializeApp } from "firebase/app"
import { getMessaging, getToken, isSupported } from "firebase/messaging"
import { api } from "./api.js"

function meta(name) {
  return document.querySelector(`meta[name="${name}"]`)?.getAttribute("content") || ""
}

export function firebaseClientConfigured() {
  return Boolean(meta("firebase-api-key") && meta("firebase-project-id") && meta("firebase-vapid-key"))
}

function firebaseConfigFromMeta() {
  return {
    apiKey: meta("firebase-api-key"),
    authDomain: meta("firebase-auth-domain"),
    projectId: meta("firebase-project-id"),
    storageBucket: meta("firebase-storage-bucket"),
    messagingSenderId: meta("firebase-messaging-sender-id"),
    appId: meta("firebase-app-id")
  }
}

async function serviceWorkerRegistration() {
  if (!("serviceWorker" in navigator)) return null
  return navigator.serviceWorker.register("/firebase-messaging-sw.js", { scope: "/" })
}

/**
 * TEMP DIAG (#81 iOS push): видимый лог шагов через onToast.
 * Убрать отдельным коммитом после on-device диагностики.
 * Без setTimeout до requestPermission — иначе iOS теряет user gesture.
 *
 * @param {{ onToast?: (msg: string) => void }} [opts]
 * @returns {Promise<{ok:boolean, reason?:string, registered?:boolean, permission?:string, token?:string}>}
 */
export async function registerShopPush(opts = {}) {
  const { onToast } = opts
  const lines = []
  const diag = (msg) => {
    lines.push(String(msg))
    if (typeof onToast === "function") onToast(lines.join("\n"))
  }
  const stepCatch = (n, err) => {
    const m = err?.message || String(err)
    diag(`ОШИБКА на шаге ${n}: ${m}`)
  }

  try {
    diag("1: старт registerShopPush")
  } catch (err) {
    stepCatch(1, err)
    throw err
  }

  let supported = false
  try {
    supported = await isSupported()
    diag(`2: isSupported = ${supported}`)
  } catch (err) {
    stepCatch(2, err)
    throw err
  }
  if (!supported) {
    return { ok: false, reason: "unsupported" }
  }

  try {
    // Конфиг читается из meta firebase-api-key / project-id / vapid-key (не одного firebase-config).
    const found = firebaseClientConfigured()
    diag(`3: meta firebase-config найден = ${found}`)
  } catch (err) {
    stepCatch(3, err)
    throw err
  }
  if (!firebaseClientConfigured()) {
    return { ok: false, reason: "no_config" }
  }

  try {
    const hasNotification = "Notification" in window
    diag(`4: Notification в window = ${hasNotification}`)
    if (!hasNotification) {
      return { ok: false, reason: "no_notification_api" }
    }
  } catch (err) {
    stepCatch(4, err)
    throw err
  }

  let permission
  try {
    diag("5: перед requestPermission()")
    permission = await Notification.requestPermission()
    diag(`6: результат requestPermission = ${permission}`)
  } catch (err) {
    stepCatch(5, err)
    throw err
  }
  if (permission !== "granted") {
    return { ok: false, reason: "denied", permission }
  }

  let token
  try {
    diag("7: перед getToken()")
    const swReg = await serviceWorkerRegistration()
    const app = initializeApp(firebaseConfigFromMeta())
    const messaging = getMessaging(app)
    token = await getToken(messaging, {
      vapidKey: meta("firebase-vapid-key"),
      serviceWorkerRegistration: swReg
    })
    diag(`8: токен получен, длина = ${token ? String(token).length : 0}`)
  } catch (err) {
    stepCatch(7, err)
    throw err
  }

  if (!token) {
    return { ok: false, reason: "no_token" }
  }

  try {
    await api("/push/register", {
      method: "POST",
      body: JSON.stringify({ push_token: token, push_enabled: true })
    })
    // api() возвращает данные только при res.ok → фактический 2xx
    diag("9: POST /push/register статус = 200")
  } catch (err) {
    const status = err?.httpStatus != null ? err.httpStatus : "?"
    diag(`ОШИБКА на шаге 9: статус=${status} ${err?.message || err}`)
    throw err
  }

  try {
    globalThis.localStorage?.setItem("coffeeos_shop_push_registered_v1", "true")
  } catch {
    /* private mode */
  }

  diag("10: registerShopPush OK")
  return { ok: true, registered: true, token }
}
