/** Подписи способов оплаты — макет 1000008925. */

export function panFromCard(card) {
  if (card?.pan) return card.pan
  const digits = String(card?.masked_pan || "").replace(/\D/g, "")
  if (digits.length >= 4) return `*${digits.slice(-4)}`
  return "*????"
}

/** Текст «Карта *5953» рядом с иконкой бренда. */
export function formatCardListLabel(card) {
  return `Карта ${panFromCard(card)}`
}

/**
 * Полная подпись как в примерах ТЗ:
 * «МИР Карта *5953», «Mastercard Карта *8339»
 */
export function formatCardFullLabel(card) {
  const brand = brandDisplayName(card?.payment_system || card?.card_type)
  return `${brand} ${formatCardListLabel(card)}`
}

export function brandDisplayName(brand) {
  const b = String(brand || "").toUpperCase()
  if (b.includes("MIR") || b.includes("МИР")) return "МИР"
  if (b.includes("MASTER") || b === "MC") return "Mastercard"
  if (b.includes("VISA")) return "Visa"
  return b || "Карта"
}

export function cardBrandShort(brand) {
  const b = String(brand || "").toUpperCase()
  if (b.includes("MIR") || b.includes("МИР")) return "MIR"
  if (b.includes("MASTER")) return "MC"
  if (b.includes("VISA")) return "VISA"
  return b || "CARD"
}
