import { api } from "../api.js"

let cached = null
let inflight = null

/** Один запрос /categories на сессию (пока не invalidate); параллельные вызовы ждут тот же промис. */
export async function loadCatalog() {
  if (cached !== null) return cached
  if (inflight) return inflight
  inflight = (async () => {
    try {
      cached = await api("/categories")
      return cached
    } finally {
      inflight = null
    }
  })()
  return inflight
}

export function getCatalogCache() {
  return cached
}

/** После изменений в админке можно вызвать с клиента (по кнопке «обновить» и т.п.). */
export function invalidateCatalog() {
  cached = null
}
