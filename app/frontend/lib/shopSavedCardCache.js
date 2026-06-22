import { readShopLocalStorage, removeShopLocalStorage, writeShopLocalStorage } from "./shopLocalStorage.js"

function cacheKey(email) {
  const q = new URLSearchParams(window.location.search).get("tenant_id")
  const tid =
    (q && String(q).trim()) ||
    document.querySelector('meta[name="shop-tenant-id"]')?.getAttribute("content") ||
    "default"
  const normalized = String(email || "")
    .trim()
    .toLowerCase()
  return `shop_saved_card:${tid}:${normalized}`
}

/** Кэш primary-карты после finalize / one-click — пока API saved_cards догоняет webhook. */
export function loadCachedSavedCard(email) {
  const normalized = String(email || "")
    .trim()
    .toLowerCase()
  if (!normalized) return null

  const data = readShopLocalStorage(cacheKey(normalized))
  if (!data?.id) return null
  return {
    id: data.id,
    payment_system: data.payment_system || "Card",
    masked_pan: data.masked_pan || "",
    is_primary: data.is_primary !== false,
    last_used_at: data.last_used_at || null
  }
}

export function saveCachedSavedCard(email, card) {
  const normalized = String(email || "")
    .trim()
    .toLowerCase()
  if (!normalized || !card?.id) return

  writeShopLocalStorage(cacheKey(normalized), {
    id: card.id,
    payment_system: card.payment_system,
    masked_pan: card.masked_pan,
    is_primary: card.is_primary !== false,
    last_used_at: card.last_used_at || null
  })
}

export function clearCachedSavedCard(email) {
  const normalized = String(email || "")
    .trim()
    .toLowerCase()
  if (!normalized) return
  removeShopLocalStorage(cacheKey(normalized))
}
