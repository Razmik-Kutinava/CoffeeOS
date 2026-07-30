/**
 * «Оплатить в клик»: позиция → корзина → новый pending_payment заказ → order_id для widget/inline.
 * Без импорта frequentRepeatStore (svelte-spa-router) — ключ qty совпадает с frequentCardKey.
 */
import { addToCart } from "./shopCartAdd.js"
import { loadGuestProfile } from "./shopGuestProfile.js"

function qtyKey(item) {
  return `${item.product_id}:${JSON.stringify(item.modifier_options || {})}`
}

/**
 * @param {object} item — frequent card
 * @param {object} opts
 * @param {(path: string, opts?: object) => Promise<object>} opts.api
 * @param {Record<string, number>} [opts.quantities]
 */
export async function createRepeatInlineOrder(item, { api, quantities = {} } = {}) {
  if (!item?.product_id) throw Object.assign(new Error("Нет товара"), { httpStatus: 400 })

  const profile = loadGuestProfile()
  if (!profile?.email || !profile?.name) {
    const err = new Error("Укажите имя и email в профиле")
    err.httpStatus = 422
    err.code = "profile_required"
    throw err
  }

  const qty = quantities[qtyKey(item)] || 1
  // Только позиция «повторить» — иначе leftover в корзине уйдёт в заказ
  await api("/cart", { method: "DELETE" })
  await addToCart({
    product_id: item.product_id,
    quantity: qty,
    selected_modifiers: item.modifier_options?.selected_modifiers || []
  })

  const res = await api("/orders", {
    method: "POST",
    body: JSON.stringify({
      name: profile.name,
      email: profile.email,
      payment_method: "card",
      client_order_uuid: crypto.randomUUID()
    })
  })

  const orderId = res?.order_id || res?.id
  if (!orderId) throw Object.assign(new Error("Не удалось создать заказ"), { httpStatus: 500 })
  return { orderId: String(orderId), order: res }
}
