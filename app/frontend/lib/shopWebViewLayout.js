/**
 * #67 Telegram WebView UI layout. Visual viewport, not physical 100vh.
 * Not Mini App, not bot, not auth. UA is not used.
 */
import { applyShopVisualViewport } from "./shopWebView.js"

const KEYBOARD_GAP_PX = 100
const subs = new Set()

export function shopVisualViewportHeight(env = globalThis) {
  const h = Number(env.visualViewport?.height || env.innerHeight || 0)
  return h > 0 ? Math.round(h) : 0
}

export function capSheetHeightPx(px, env = globalThis) {
  const avail = shopVisualViewportHeight(env)
  const n = Math.max(0, Math.round(Number(px) || 0))
  if (!avail) return n
  return Math.min(n, avail)
}

export function sheetHeightPx(vhPercent, env = globalThis) {
  const avail = shopVisualViewportHeight(env)
  if (!avail) return 0
  return capSheetHeightPx((Number(vhPercent) / 100) * avail, env)
}

export function catalogPadBottomPx(sheetVh, env = globalThis) {
  return sheetHeightPx(sheetVh, env)
}

export function stickyOffsetTopPx(env = globalThis) {
  return Math.max(0, Math.round(Number(env.safeAreaInsetTop || 0)))
}

export function isShopKeyboardOpen(env = globalThis) {
  const inner = Number(env.innerHeight || 0)
  const vv = env.visualViewport
  if (!vv || !inner) return false
  const h = Number(vv.height || 0)
  const top = Number(vv.offsetTop || 0)
  return top > 0 || inner - h >= KEYBOARD_GAP_PX
}

export function keepUiStateOnViewportChange(state) {
  return state
}

export function pageScrollLockedBySheet() {
  return false
}

export function subscribeShopViewport(cb) {
  if (typeof cb !== "function") return () => {}
  subs.add(cb)
  return () => subs.delete(cb)
}

function emitViewport(h) {
  for (const cb of subs) {
    try {
      cb(h)
    } catch {
      /* listener must not break layout */
    }
  }
}

export function applyShopWebViewLayout(rootEl, env = globalThis) {
  const h = shopVisualViewportHeight(env)
  if (rootEl?.style?.setProperty) {
    applyShopVisualViewport(rootEl, { height: h })
    if (env.safeAreaInsetTop != null) {
      rootEl.style.setProperty("--shop-safe-top", `${Math.round(Number(env.safeAreaInsetTop) || 0)}px`)
    }
    if (env.safeAreaInsetBottom != null) {
      rootEl.style.setProperty("--shop-safe-bottom", `${Math.round(Number(env.safeAreaInsetBottom) || 0)}px`)
    }
    const kb = isShopKeyboardOpen(env)
    const kbInset = kb ? Math.max(0, Math.round(Number(env.innerHeight || 0) - h)) : 0
    rootEl.style.setProperty("--shop-keyboard-inset", `${kbInset}px`)
  }
  emitViewport(h)
  return { height: h, keyboardOpen: isShopKeyboardOpen(env) }
}

export function installShopWebViewLayout(env = globalThis) {
  const root = env.document?.documentElement
  applyShopWebViewLayout(root, env)
  const onChange = () => applyShopWebViewLayout(root, env)
  const vv = env.visualViewport
  const unsubs = []
  if (vv && typeof vv.addEventListener === "function") {
    vv.addEventListener("resize", onChange)
    vv.addEventListener("scroll", onChange)
    unsubs.push(() => {
      vv.removeEventListener("resize", onChange)
      vv.removeEventListener("scroll", onChange)
    })
  }
  if (typeof env.addEventListener === "function") {
    env.addEventListener("resize", onChange)
    unsubs.push(() => env.removeEventListener("resize", onChange))
  }
  return () => {
    for (const u of unsubs) u()
  }
}
