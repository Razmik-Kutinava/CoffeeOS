import { api } from "./api.js"
import { isOfflineError } from "./shopNetwork.js"
import { getCatalogCache } from "./stores/catalog.js"
import { enqueueCartAdd } from "./shopOfflineCart.js"

const CART_CACHE_KEY = "coffeeos_shop_cart_v1"

function readCartCache() {
  try {
    const raw = localStorage.getItem(CART_CACHE_KEY)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

function writeCartCache(data) {
  try {
    localStorage.setItem(CART_CACHE_KEY, JSON.stringify(data))
  } catch {
    /* quota */
  }
}

function findProduct(productId) {
  const cats = getCatalogCache() || []
  for (const cat of cats) {
    const product = (cat.products || []).find((p) => String(p.id) === String(productId))
    if (product) return product
  }
  return null
}

function modifiersKey(selected_modifiers) {
  return JSON.stringify(selected_modifiers || [])
}

function modifierExtra(selected_modifiers) {
  return (selected_modifiers || []).reduce((sum, m) => sum + Number(m.price || 0), 0)
}

function applyOptimisticAdd(product, quantity, selected_modifiers) {
  const cached = readCartCache() || { items: [], total: 0 }
  const items = [...(cached.items || [])]
  const key = modifiersKey(selected_modifiers)
  const unitTotal = Number(product.price || 0) + modifierExtra(selected_modifiers)
  const existing = items.find(
    (line) =>
      String(line.product_id) === String(product.id) &&
      modifiersKey(line.selected_modifiers) === key
  )

  if (existing) {
    existing.quantity += quantity
    existing.line_total = existing.unit_total * existing.quantity
  } else {
    items.push({
      index: items.length,
      product_id: product.id,
      product_name: product.name,
      quantity,
      price: Number(product.price || 0),
      image_url: product.image_url,
      selected_modifiers: selected_modifiers || [],
      removed_modifiers: [],
      unit_total: unitTotal,
      line_total: unitTotal * quantity
    })
  }

  items.forEach((line, idx) => {
    line.index = idx
  })
  const total = items.reduce((sum, line) => sum + Number(line.line_total || 0), 0)
  const data = { items, total }
  writeCartCache(data)
  return data
}

/**
 * POST /cart/add с офлайн-очередью и оптимистичным localStorage.
 */
export async function addToCart(payload, { product = null } = {}) {
  const body = {
    product_id: payload.product_id,
    quantity: payload.quantity ?? 1,
    selected_modifiers: payload.selected_modifiers || []
  }

  try {
    const res = await api("/cart/add", {
      method: "POST",
      body: JSON.stringify(body)
    })
    const data = { items: res.cart || res.items || [], total: res.total ?? 0 }
    writeCartCache(data)
    return data
  } catch (e) {
    if (!isOfflineError(e) && navigator.onLine) throw e

    const prod = product || findProduct(body.product_id)
    if (!prod) throw new Error("Товар не найден в офлайн-кэше")

    await enqueueCartAdd(body)
    const data = applyOptimisticAdd(prod, body.quantity, body.selected_modifiers)
    window.dispatchEvent(new CustomEvent("shop:offline-cart-queued"))
    return data
  }
}
