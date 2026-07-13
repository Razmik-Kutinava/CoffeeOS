/** B1.12-R3 — подписи способов оплаты (макет 8924). */

export function panFromCard(card) {
  if (card?.pan) return card.pan
  const digits = String(card?.masked_pan || "").replace(/\D/g, "")
  if (digits.length >= 4) return `*${digits.slice(-4)}`
  return "*????"
}

/** «Карта *5953» как на макете 8924. */
export function formatCardListLabel(card) {
  return `Карта ${panFromCard(card)}`
}

/** «Картой *1594» — checkout sheet s06 / ТЗ Шаг 2. */
export function formatCardMethodLabel(card) {
  return `Картой ${panFromCard(card)}`
}

export function cardBrandShort(brand) {
  const b = String(brand || "").toUpperCase()
  if (b.includes("MIR") || b.includes("МИР")) return "MIR"
  if (b.includes("MASTER")) return "MC"
  if (b.includes("VISA")) return "VISA"
  return b || "CARD"
}
