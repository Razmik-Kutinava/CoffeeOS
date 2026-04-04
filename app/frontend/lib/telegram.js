export function initTelegram() {
  if (typeof window === "undefined") return null
  const tg = window.Telegram?.WebApp
  if (!tg) return null
  try {
    tg.ready()
    tg.expand()
  } catch {
    /* ignore */
  }
  return tg
}

import { onMount, onDestroy } from "svelte"

export function useTelegramBack(callback) {
  onMount(() => {
    if (window.Telegram?.WebApp) {
      const tg = window.Telegram.WebApp
      tg.BackButton.show()
      tg.BackButton.onClick(callback)
    }
  })

  onDestroy(() => {
    if (window.Telegram?.WebApp) {
      window.Telegram.WebApp.BackButton.hide()
    }
  })
}
