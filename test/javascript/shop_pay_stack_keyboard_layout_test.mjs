/**
 * TASK_105: шторка оплаты (pay-стек) под цифровой клавиатурой — высота и низ от visual viewport.
 * node --test test/javascript/shop_pay_stack_keyboard_layout_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import {
  applyShopWebViewLayout,
  payStackBottomPx,
  payStackHeightPx,
  shouldHideCartCheckoutCta
} from "../../app/frontend/lib/shopWebViewLayout.js"
import { CHECKOUT_PAY_STACK_VH } from "../../app/frontend/lib/cartSheetThresholds.js"

const KEYBOARD_PX = 365

function env(width, height, { keyboard = 0, offsetTop = 0 } = {}) {
  return {
    innerWidth: width,
    innerHeight: height,
    visualViewport: { height: height - keyboard, offsetTop }
  }
}

function rootStub() {
  const props = {}
  return { props, el: { style: { setProperty: (k, v) => { props[k] = v } } } }
}

/** Верх шторки в координатах layout viewport не выше верха видимой области. */
function fitsVisual(e) {
  const top = e.innerHeight - payStackBottomPx(e) - payStackHeightPx(e)
  const visualBottom = e.visualViewport.offsetTop + e.visualViewport.height
  return top >= e.visualViewport.offsetTop && e.innerHeight - payStackBottomPx(e) <= visualBottom
}

describe("pay-стек без клавиатуры — прежняя высота", () => {
  it("412×915: 92% экрана, низ у края", () => {
    const e = env(412, 915)
    assert.equal(payStackHeightPx(e), Math.round((CHECKOUT_PAY_STACK_VH / 100) * 915))
    assert.equal(payStackBottomPx(e), 0)
  })

  it("без visualViewport — от innerHeight, низ 0", () => {
    const e = { innerHeight: 800 }
    assert.equal(payStackHeightPx(e), Math.round((CHECKOUT_PAY_STACK_VH / 100) * 800))
    assert.equal(payStackBottomPx(e), 0)
  })
})

describe("pay-стек с цифровой клавиатурой — над клавиатурой", () => {
  for (const [w, h] of [[412, 915], [390, 844], [360, 640]]) {
    it(`${w}×${h}: низ = клавиатура, высота от видимой области`, () => {
      const e = env(w, h, { keyboard: KEYBOARD_PX })
      const visual = h - KEYBOARD_PX
      assert.equal(payStackBottomPx(e), KEYBOARD_PX)
      assert.equal(payStackHeightPx(e), Math.round((CHECKOUT_PAY_STACK_VH / 100) * visual))
      assert.ok(fitsVisual(e), "шторка целиком в видимой области над клавиатурой")
    })
  }

  it("видимая область сдвинута браузером (offsetTop) — низ шторки = низ видимой области", () => {
    const e = env(412, 915, { keyboard: KEYBOARD_PX, offsetTop: 100 })
    assert.equal(payStackBottomPx(e), 915 - 100 - (915 - KEYBOARD_PX))
    assert.ok(fitsVisual(e))
  })

  it("закрыли клавиатуру — обратно низ 0 и полная высота", () => {
    const open = env(412, 915, { keyboard: KEYBOARD_PX })
    const closed = env(412, 915)
    assert.notEqual(payStackHeightPx(open), payStackHeightPx(closed))
    assert.equal(payStackBottomPx(closed), 0)
    assert.equal(payStackHeightPx(closed), Math.round((CHECKOUT_PAY_STACK_VH / 100) * 915))
  })
})

describe("applyShopWebViewLayout пишет CSS-переменные pay-стека", () => {
  it("с клавиатурой", () => {
    const { props, el } = rootStub()
    applyShopWebViewLayout(el, env(412, 915, { keyboard: KEYBOARD_PX }))
    assert.equal(props["--shop-pay-stack-h"], `${Math.round((CHECKOUT_PAY_STACK_VH / 100) * 550)}px`)
    assert.equal(props["--shop-pay-stack-bottom"], `${KEYBOARD_PX}px`)
    assert.equal(props["--shop-keyboard-inset"], `${KEYBOARD_PX}px`)
  })

  it("без клавиатуры", () => {
    const { props, el } = rootStub()
    applyShopWebViewLayout(el, env(412, 915))
    assert.equal(props["--shop-pay-stack-h"], `${Math.round((CHECKOUT_PAY_STACK_VH / 100) * 915)}px`)
    assert.equal(props["--shop-pay-stack-bottom"], "0px")
    assert.equal(props["--shop-keyboard-inset"], "0px")
  })
})

describe("#80 / TASK_89-UI-EXT не изменились", () => {
  it("shouldHideCartCheckoutCta", () => {
    assert.equal(shouldHideCartCheckoutCta({ onCheckout: true, keyboardOpen: true }), true)
    assert.equal(shouldHideCartCheckoutCta({ onCheckout: true, phoneAuthActive: true }), true)
    assert.equal(shouldHideCartCheckoutCta({ onCheckout: true }), false)
    assert.equal(shouldHideCartCheckoutCta({ onCheckout: false, keyboardOpen: true }), false)
  })
})
