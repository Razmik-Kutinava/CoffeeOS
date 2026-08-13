/**
 * Состояние inline «оплатить в клик» — переживает remount RepeatSection
 * (empty full → cart peek/embedded после addToCart).
 */
import { writable } from "svelte/store"
import { createWidgetPayFsm } from "./shopWidgetPayFsm.js"

function blank() {
  return {
    activeKey: null,
    fsm: createWidgetPayFsm(),
    statusText: "",
    errorText: "",
    showFallbackMethods: false,
    showRetry: false,
    showExpandedCards: false,
    showNewCardForm: false,
    savedCards: [],
    busy: false
  }
}

export const repeatInlinePayUi = writable(blank())

export function patchRepeatInlinePayUi(partial) {
  repeatInlinePayUi.update((s) => ({ ...s, ...partial }))
}

export function resetRepeatInlinePayUi() {
  repeatInlinePayUi.set(blank())
}
