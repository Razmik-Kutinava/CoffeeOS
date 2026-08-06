import { writable, get } from "svelte/store"

/**
 * CTA карточки товара → внутри CartSheet (не отдельный fixed-слой).
 * Product публикует состояние; при уходе со страницы — clear.
 */
const EMPTY = Object.freeze({
  active: false,
  price: 0,
  qty: 1,
  adding: false,
  editMode: false,
  stockOk: true,
  outOfStockProductId: null,
  onAdd: null,
  onQtyDelta: null,
  onMore: null
})

export const productPageCta = writable({ ...EMPTY })

export function publishProductPageCta( partial ) {
  productPageCta.set({
    ...EMPTY,
    ...partial,
    active: true
  })
}

export function clearProductPageCta() {
  productPageCta.set({ ...EMPTY })
}

export function isProductPageCtaActive() {
  return Boolean(get(productPageCta)?.active)
}

export function isProductRoute(hash = null) {
  const h = (hash ?? (typeof window !== "undefined" ? window.location.hash : "")).replace("#", "") || "/"
  return h.startsWith("/product/")
}
