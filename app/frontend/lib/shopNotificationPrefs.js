import { readShopLocalStorage, writeShopLocalStorage } from "./shopLocalStorage.js"

const KEY = "shop_notifications_enabled"

export function loadNotificationPref(defaultEnabled = true) {
  const raw = readShopLocalStorage(KEY)
  if (raw === null || raw === undefined || raw === "") return defaultEnabled
  return raw === true || raw === "true" || raw === 1 || raw === "1"
}

/** @returns {{ ok: boolean, value: boolean }} */
export function saveNotificationPref(enabled) {
  try {
    writeShopLocalStorage(KEY, !!enabled)
    return { ok: true, value: !!enabled }
  } catch {
    return { ok: false, value: loadNotificationPref() }
  }
}
