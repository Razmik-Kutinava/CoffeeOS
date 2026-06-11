import { mount } from "svelte"
import App from "../App.svelte"
import "../styles/app.css"
import { initShopPwa } from "../lib/shopPwa.js"
import { initShopNetwork } from "../lib/shopNetwork.js"
import { flushOrderQueue } from "../lib/shopOfflineQueue.js"
import { api } from "../lib/api.js"

initShopPwa()
initShopNetwork()

window.addEventListener("online", () => {
  flushOrderQueue(api).catch(() => {})
})

const el = document.getElementById("app")
if (el) {
  el.replaceChildren()
  mount(App, { target: el })
}
