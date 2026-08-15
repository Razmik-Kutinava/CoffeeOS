/**
 * #67 Telegram WebView mobile UI layout (not Mini App, not bot, not auth).
 * node --test test/javascript/shop_telegram_webview_ui_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import {
  applyShopWebViewLayout,
  capSheetHeightPx,
  catalogPadBottomPx,
  installShopWebViewLayout,
  isShopKeyboardOpen,
  keepUiStateOnViewportChange,
  pageScrollLockedBySheet,
  sheetHeightPx,
  shopVisualViewportHeight,
  stickyOffsetTopPx,
  subscribeShopViewport
} from "../../app/frontend/lib/shopWebViewLayout.js"

function rootStub() {
  const props = {}
  return {
    props,
    el: { style: { setProperty: (k, v) => { props[k] = v } } }
  }
}

describe("visual viewport (not physical 100vh)", () => {
  it("prefers visualViewport.height over innerHeight", () => {
    const h = shopVisualViewportHeight({
      innerHeight: 800,
      visualViewport: { height: 540 }
    })
    assert.equal(h, 540)
  })

  it("falls back to innerHeight when visualViewport is missing", () => {
    assert.equal(shopVisualViewportHeight({ innerHeight: 700 }), 700)
  })

  it("does not throw without document or visualViewport", () => {
    const teardown = installShopWebViewLayout({ innerHeight: 640 })
    assert.equal(typeof teardown, "function")
    teardown()
  })
})

describe("sheet height in visual viewport", () => {
  it("converts vh percent against visualViewport, not innerHeight", () => {
    const env = { innerHeight: 900, visualViewport: { height: 500 } }
    assert.equal(sheetHeightPx(50, env), 250)
  })

  it("caps checkout-sized sheet so it stays inside available height", () => {
    const env = { innerHeight: 800, visualViewport: { height: 300 } }
    assert.ok(sheetHeightPx(92, env) <= 300)
    assert.equal(capSheetHeightPx(400, env), 300)
  })

  it("catalog bottom padding matches sheet px so last cards are reachable", () => {
    const env = { visualViewport: { height: 640 } }
    assert.equal(catalogPadBottomPx(42, env), sheetHeightPx(42, env))
  })
})

describe("keyboard open / close", () => {
  it("detects keyboard when visualViewport shrinks vs innerHeight", () => {
    assert.equal(
      isShopKeyboardOpen({
        innerHeight: 800,
        visualViewport: { height: 420, offsetTop: 0 }
      }),
      true
    )
  })

  it("detects keyboard via offsetTop", () => {
    assert.equal(
      isShopKeyboardOpen({
        innerHeight: 700,
        visualViewport: { height: 700, offsetTop: 80 }
      }),
      true
    )
  })

  it("keyboard close restores --shop-vvh without leftover inset", () => {
    const { el, props } = rootStub()
    const env = { innerHeight: 800, visualViewport: { height: 400, offsetTop: 0 } }
    applyShopWebViewLayout(el, env)
    assert.equal(props["--shop-vvh"], "400px")
    assert.ok(Number.parseInt(props["--shop-keyboard-inset"], 10) > 0)

    env.visualViewport = { height: 800, offsetTop: 0 }
    applyShopWebViewLayout(el, env)
    assert.equal(props["--shop-vvh"], "800px")
    assert.equal(props["--shop-keyboard-inset"], "0px")
  })
})

describe("safe-area / sticky / scroll-lock / state", () => {
  it("writes top and bottom safe-area CSS vars", () => {
    const { el, props } = rootStub()
    applyShopWebViewLayout(el, {
      innerHeight: 640,
      visualViewport: { height: 640 },
      safeAreaInsetTop: 44,
      safeAreaInsetBottom: 34
    })
    assert.equal(props["--shop-safe-top"], "44px")
    assert.equal(props["--shop-safe-bottom"], "34px")
    assert.equal(stickyOffsetTopPx({ safeAreaInsetTop: 44 }), 44)
  })

  it("does not lock page scroll because catalog uses window scroll", () => {
    assert.equal(pageScrollLockedBySheet(), false)
  })

  it("viewport change keeps cart/sheet mode state", () => {
    const state = { mode: "peek", count: 2 }
    assert.equal(keepUiStateOnViewportChange(state), state)
    assert.equal(state.mode, "peek")
  })

  it("resize listener updates --shop-vvh", () => {
    const { el, props } = rootStub()
    const vv = {
      height: 600,
      listeners: {},
      addEventListener(type, fn) {
        this.listeners[type] = fn
      },
      removeEventListener(type) {
        delete this.listeners[type]
      }
    }
    const env = { document: { documentElement: el }, visualViewport: vv, innerHeight: 600 }
    const teardown = installShopWebViewLayout(env)
    assert.equal(props["--shop-vvh"], "600px")
    vv.height = 420
    vv.listeners.resize()
    assert.equal(props["--shop-vvh"], "420px")
    teardown()
  })

  it("subscribeShopViewport notifies on layout apply", () => {
    const seen = []
    const unsub = subscribeShopViewport((h) => seen.push(h))
    const { el } = rootStub()
    applyShopWebViewLayout(el, { visualViewport: { height: 511 } })
    unsub()
    assert.ok(seen.includes(511))
  })
})
