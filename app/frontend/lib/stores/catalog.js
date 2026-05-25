import { api } from "../api.js"

let inflight = null

/** Каждый заход на витрину — свежий каталог (изменения из УК видны сразу после перезагрузки страницы). */
export async function loadCatalog() {
  if (inflight) return inflight
  inflight = (async () => {
    try {
      const res = await api("/categories")
      return Array.isArray(res) ? res : (res.data ?? [])
    } finally {
      inflight = null
    }
  })()
  return inflight
}

export function getCatalogCache() {
  return null
}

/** После изменений в админке можно вызвать с клиента (по кнопке «обновить» и т.п.). */
export function invalidateCatalog() {
  inflight = null
}
