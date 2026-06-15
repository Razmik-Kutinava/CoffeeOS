/** API: required/optional; legacy UI: radio/checkbox */
export function isRadioModifierGroup(group) {
  const t = group?.modifier_type
  return t === "radio" || t === "required"
}

export function isCheckboxModifierGroup(group) {
  return !isRadioModifierGroup(group)
}

export function defaultSelectionForGroup(_group) {
  return []
}

export function selectedModifierIdsForGroup(group, selected) {
  const value = selected[group.id]
  if (Array.isArray(value)) return value
  if (value) return [value]
  return []
}

/** selected + removed (все опции товара минус выбранные) для корзины и табло бариста. */
export function buildModifierPayload(modifierGroups, selected) {
  const selected_modifiers = []
  for (const g of modifierGroups || []) {
    for (const mid of selectedModifierIdsForGroup(g, selected)) {
      const m = g.modifiers.find((x) => x.id === mid)
      if (m) selected_modifiers.push({ id: m.id, name: m.name, price: Number(m.price_change) })
    }
  }

  const selectedIds = new Set(selected_modifiers.map((m) => m.id))
  const removed_modifiers = []
  for (const g of modifierGroups || []) {
    for (const m of g.modifiers || []) {
      if (!selectedIds.has(m.id)) {
        removed_modifiers.push({ id: m.id, name: m.name, price: Number(m.price_change) })
      }
    }
  }

  return { selected_modifiers, removed_modifiers }
}
