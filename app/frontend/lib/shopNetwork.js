import { writable } from "svelte/store"

export const shopOnline = writable(typeof navigator !== "undefined" ? navigator.onLine : true)

export function initShopNetwork() {
  if (typeof window === "undefined") return

  const sync = () => shopOnline.set(navigator.onLine)
  window.addEventListener("online", sync)
  window.addEventListener("offline", sync)
  sync()
}

export function isOfflineError(error) {
  if (typeof navigator !== "undefined" && !navigator.onLine) return true
  if (error instanceof TypeError) return true
  const msg = String(error?.message || "")
  return /failed to fetch|network|offline/i.test(msg)
}

/** Каталог: network vs HTTP. Пустой список — не ошибка (ветка UI «нет товаров»). */
export function catalogErrorKind(error, { online } = {}) {
  if (error == null) return null
  const isOnline =
    online ?? (typeof navigator === "undefined" ? true : navigator.onLine)
  if (isOnline === false) return "network"
  if (error instanceof TypeError) return "network"
  const msg = String(error?.message || "")
  if (/failed to fetch|network|offline/i.test(msg)) return "network"
  if (Number(error.httpStatus) >= 400) return "server"
  return "server"
}
