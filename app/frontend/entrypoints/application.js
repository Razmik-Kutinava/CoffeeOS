import { mount } from "svelte"
import App from "../App.svelte"
import "../styles/app.css"
import { initShopPwa } from "../lib/shopPwa.js"
import { initShopNetwork } from "../lib/shopNetwork.js"
import { flushOrderQueue } from "../lib/shopOfflineQueue.js"
import { flushCartQueue } from "../lib/shopOfflineCart.js"
import { api } from "../lib/api.js"

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
