/** Ретрай списка сохранённых карт после 3DS / soft webhook. */

/**
 * @param {() => Promise<unknown[]>} loadOnce — один GET списка
 * @param {{ attempts?: number, delayMs?: number }} [opts]
 * @returns {Promise<unknown[]>}
 */
export async function loadSavedCardsWithRetry(
  loadOnce,
  { attempts = 5, delayMs = 400 } = {}
) {
  let cards = []
  const max = Math.max(1, Number(attempts) || 1)
  for (let i = 0; i < max; i += 1) {
    const next = await loadOnce()
    cards = Array.isArray(next) ? next : []
    if (cards.length > 0) return cards
    if (i < max - 1) {
      await new Promise((resolve) => setTimeout(resolve, delayMs))
    }
  }
  return cards
}
