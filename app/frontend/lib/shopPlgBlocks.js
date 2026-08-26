/**
 * PLG-блоки ЛК (#69): только конфиг-интерфейс, без запросов и бизнес-логики.
 * @typedef {{ id: string, imageUrl?: string, ctaLabel?: string, href?: string }} PlgBlockConfig
 */

/** @returns {PlgBlockConfig[]} */
export function loadPlgBlockConfigs() {
  // Контент подставится позже через config/API; сейчас — пустые слоты.
  return [
    { id: "plg-slot-a" },
    { id: "plg-slot-b" }
  ]
}

/** @param {PlgBlockConfig} block */
export function plgBlockHasContent(block) {
  return !!(block?.imageUrl?.trim() || block?.ctaLabel?.trim() || block?.href?.trim())
}
