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
  if (!navigator.onLine) return true
  if (error instanceof TypeError) return true
  const msg = String(error?.message || "")
  return /failed to fetch|network|offline/i.test(msg)
}
