import { api } from "../api.js"

let inflight = null

/** Каждый заход на витрину — свежий каталог (изменения из УК видны сразу после перезагрузки страницы). */
export async function loadCatalog() {
  if (inflight) return inflight
  inflight = (async () => {
    try {
      return await api("/categories")
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
