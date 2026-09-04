import { api } from "./api.js"

let deferredInstallPrompt = null

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
