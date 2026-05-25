/** API: required/optional; legacy UI: radio/checkbox */
export function isRadioModifierGroup(group) {
  const t = group?.modifier_type
  return t === "radio" || t === "required"
}

export function isCheckboxModifierGroup(group) {
  return !isRadioModifierGroup(group)
}

export function defaultSelectionForGroup(group) {
  if (isRadioModifierGroup(group)) {
    return group.modifiers[0]?.id ?? null
  }
  return []
}
