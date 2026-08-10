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
 * Запрос разрешения + регистрация FCM-токена на сервере.
 * @returns {Promise<{ok:boolean, reason?:string, registered?:boolean}>}
 */
export async function registerShopPush() {
  if (!(await isSupported())) {
    return { ok: false, reason: "unsupported" }
  }
  if (!firebaseClientConfigured()) {
    return { ok: false, reason: "no_config" }
  }
  if (!("Notification" in window)) {
    return { ok: false, reason: "no_notification_api" }
  }

  const permission = await Notification.requestPermission()
  if (permission !== "granted") {
    return { ok: false, reason: "denied", permission }
  }

  const swReg = await serviceWorkerRegistration()
  const app = initializeApp(firebaseConfigFromMeta())
  const messaging = getMessaging(app)
  const token = await getToken(messaging, {
    vapidKey: meta("firebase-vapid-key"),
    serviceWorkerRegistration: swReg
  })

  if (!token) {
    return { ok: false, reason: "no_token" }
  }

  await api("/push/register", {
    method: "POST",
    body: JSON.stringify({ push_token: token, push_enabled: true })
  })

  try {
    globalThis.localStorage?.setItem("coffeeos_shop_push_registered_v1", "true")
  } catch {
    /* private mode */
  }

  return { ok: true, registered: true, token }
}
