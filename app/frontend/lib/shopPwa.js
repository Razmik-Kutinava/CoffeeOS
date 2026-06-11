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

export function initShopPwa() {
  if (!("serviceWorker" in navigator)) return

  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault()
    deferredInstallPrompt = event
    window.dispatchEvent(new CustomEvent("shop:pwa-installable"))
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
