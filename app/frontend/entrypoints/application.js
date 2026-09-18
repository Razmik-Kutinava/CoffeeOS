import { mount } from "svelte"
import App from "../App.svelte"
import "../styles/app.css"
import { initShopPwa } from "../lib/shopPwa.js"
import { initShopNetwork } from "../lib/shopNetwork.js"
import { flushOrderQueue } from "../lib/shopOfflineQueue.js"
import { flushCartQueue } from "../lib/shopOfflineCart.js"
import { api } from "../lib/api.js"
import { handleCoffeeosNavigateMessage, handleCoffeeosHashBoot } from "../lib/swNotificationActions.js"
import { openSupportChat } from "../lib/supportChatAdapter.js"
import { SUPPORT_TELEGRAM_URL } from "../lib/supportConfig.js"
import { openTipsService } from "../lib/tipsAdapter.js"
import { TIPS_SERVICE_URL } from "../lib/tipsConfig.js"

function showShopBootError(err) {
  const el = document.getElementById("app")
  if (!el) return
  const msg = err && err.message ? String(err.message) : ""
  el.innerHTML =
    '<div class="shop-boot-error" style="padding:3rem 1rem;text-align:center;font-family:system-ui,sans-serif">' +
    '<p style="color:#ff8c42;font-weight:600">Не удалось загрузить меню</p>' +
    (msg ? '<p style="color:#a0a0a0;font-size:0.9rem">' + msg.replace(/[<>&]/g, "") + "</p>" : "") +
    '<p><button type="button" id="shop-boot-error-reload" style="background:#ff8c42;color:#1a1a1a;border:0;border-radius:8px;padding:0.6rem 1rem;font:inherit;cursor:pointer">Обновить</button></p>' +
    "</div>"
  const btn = document.getElementById("shop-boot-error-reload")
  if (btn) btn.onclick = function () { window.location.reload() }
}

function coffeeosNavigateDeps() {
  return {
    openSupportChat: (orderId) => openSupportChat(orderId, SUPPORT_TELEGRAM_URL),
    openTipsService: (orderId) => openTipsService(orderId, "", TIPS_SERVICE_URL),
    assignLocation: (url) => {
      window.location.assign(url)
    },
    chatUrl: SUPPORT_TELEGRAM_URL,
    tipsUrl: TIPS_SERVICE_URL
  }
}

try {
  initShopPwa()
  initShopNetwork()
} catch (err) {
  console.warn("[shop-boot] init", err)
}

window.addEventListener("online", () => {
  flushCartQueue(api).catch(() => {})
  flushOrderQueue(api).catch(() => {})
})

// #94: FCM SW postMessage { type: "coffeeos_navigate", url } → chat / deep link
if (typeof navigator !== "undefined" && navigator.serviceWorker) {
  navigator.serviceWorker.addEventListener("message", (event) => {
    handleCoffeeosNavigateMessage(event.data, coffeeosNavigateDeps())
  })
}

// #94 cold-start: openWindow deep link without postMessage
try {
  handleCoffeeosHashBoot(
    typeof window !== "undefined" ? window.location : { hash: "" },
    coffeeosNavigateDeps()
  )
} catch (err) {
  console.warn("[shop-boot] hash navigate", err)
}

try {
  const el = document.getElementById("app")
  if (el) {
    el.replaceChildren()
    mount(App, { target: el })
  }
} catch (err) {
  console.error("[shop-boot]", err)
  showShopBootError(err)
}
