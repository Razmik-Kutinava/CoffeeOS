import { get } from "svelte/store"
import { addToCart } from "./shopCartAdd.js"
import { bumpCartLine, cartItems, refreshCartSheet } from "./cartSheetStore.js"
import {
  frequentCardKey,
  frequentQuantities,
  setFrequentQty,
  repeatFeedback
} from "./frequentRepeatStore.js"

function selectedMods(item) {
  return item?.modifier_options?.selected_modifiers || []
}

function modsKey(mods) {
  return JSON.stringify(mods || [])
}

function findMatchingLine(item) {
  const pid = String(item.product_id)
  const key = modsKey(selectedMods(item))
  return get(cartItems).find(
    (line) =>
      String(line.product_id) === pid &&
      modsKey(line.selected_modifiers) === key
  )
}

/** Peek/embedded: «+»/«−» на карточке повтора синхронизируют текущий заказ. */
export async function repeatBumpEmbeddedToCart(item, delta) {
  if (!item?.product_id) return false
  const key = frequentCardKey(item)
  const qtyMap = get(frequentQuantities) || {}
  const current = Number(qtyMap[key]) || 1
  const d = Number(delta) || 0

  if (d > 0) {
    try {
      await addToCart({
        product_id: item.product_id,
        quantity: 1,
        selected_modifiers: selectedMods(item)
      })
      setFrequentQty(key, current + 1)
      await refreshCartSheet().catch(() => {})
      return true
    } catch (_e) {
      repeatFeedback.set({ type: "error", message: "Не удалось добавить в заказ" })
      return false
    }
  }

  if (d < 0) {
    const line = findMatchingLine(item)
    if (line) await bumpCartLine(line.index, -1)
    setFrequentQty(key, Math.max(1, current - 1))
    return true
  }

  return false
}
