import { describe, it } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import * as layout from "../../app/frontend/lib/shopWebViewLayout.js"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const read = (p) => readFileSync(join(root, p), "utf8")

function rootStub() {
  const props = {}
  return { props, el: { style: { setProperty: (k, v) => { props[k] = v } } } }
}

const SCREENS = [
  "app/frontend/components/CatalogFiltersSheet.svelte",
  "app/frontend/components/CatalogSortSheet.svelte",
  "app/frontend/components/ContactSupportSheet.svelte",
  "app/frontend/routes/OrderReceipt.svelte",
  "app/frontend/components/OrderStatusSheet.svelte"
]

describe("TASK_SAFE-BOTTOM-MIN — минимальный нижний отступ 8px [TDD]", () => {
  it("SHOP_SAFE_BOTTOM_MIN_PX = 8", () => {
    assert.equal(layout.SHOP_SAFE_BOTTOM_MIN_PX, 8)
  })

  it("WebView inset 0 → --shop-safe-bottom 8px", () => {
    const { el, props } = rootStub()
    layout.applyShopWebViewLayout(el, { innerHeight: 640, visualViewport: { height: 640 }, safeAreaInsetBottom: 0 })
    assert.equal(props["--shop-safe-bottom"], "8px")
  })

  it("WebView inset 34 (Home Indicator) → 34px (берётся большее)", () => {
    const { el, props } = rootStub()
    layout.applyShopWebViewLayout(el, { innerHeight: 640, visualViewport: { height: 640 }, safeAreaInsetBottom: 34 })
    assert.equal(props["--shop-safe-bottom"], "34px")
  })

  it("app.css default --shop-safe-bottom = max(8px, env(safe-area-inset-bottom))", () => {
    assert.match(read("app/frontend/styles/app.css"), /--shop-safe-bottom:\s*max\(8px,\s*env\(safe-area-inset-bottom,\s*0px\)\);/)
  })

  for (const p of SCREENS) {
    it(`${p.split("/").pop()} uses var(--shop-safe-bottom), not own env()`, () => {
      const src = read(p)
      assert.doesNotMatch(src, /env\(safe-area-inset-bottom/)
      assert.match(src, /var\(--shop-safe-bottom/)
    })
  }

  it("CartSheet стоит у края экрана: safe-area — фон шторки, а не пустая полоса под ней", () => {
    const src = read("app/frontend/components/CartSheet.svelte")
    assert.match(src, /style:bottom=\{payStackActive \? `\$\{stackBottomPx\}px` : "0px"\}/)
    assert.match(src, /style:padding-bottom=\{payStackActive \? null : "var\(--shop-safe-bottom, 0px\)"\}/)
    assert.match(src, /style:height=\{payStackActive \? `\$\{heightPx\}px` : `calc\(\$\{heightPx\}px \+ var\(--shop-safe-bottom, 0px\)\)`\}/)
  })

  it("bugbot: резерв под CartSheet учитывает её подъём на --shop-safe-bottom", () => {
    const lift = "var(--cart-sheet-h, 42vh) + var(--shop-safe-bottom, 0px)"
    assert.ok(read("app/frontend/routes/Catalog.svelte").includes(`padding-bottom: calc(${lift})`))
    assert.match(
      read("app/frontend/routes/CategoryProducts.svelte"),
      /padding-bottom: max\(80px, calc\(var\(--cart-sheet-h, 80px\) \+ var\(--shop-safe-bottom, 0px\)\)\)/
    )
    const product = read("app/frontend/routes/Product.svelte")
    assert.match(product, /height: calc\(var\(--cart-sheet-h, 34vh\) \+ var\(--shop-safe-bottom, 0px\) \+ 1rem\)/)
    assert.match(product, /bottom: calc\(var\(--cart-sheet-h, 34vh\) \+ var\(--shop-safe-bottom, 0px\) \+ 0\.5rem\)/)
  })

  it("screen extras 24px/16px сохранены", () => {
    assert.match(read(SCREENS[0]), /calc\(24px \+ var\(--shop-safe-bottom/)
    assert.match(read(SCREENS[1]), /calc\(24px \+ var\(--shop-safe-bottom/)
    assert.match(read(SCREENS[2]), /calc\(16px \+ var\(--shop-safe-bottom/)
    assert.match(read(SCREENS[3]), /calc\(16px \+ var\(--shop-safe-bottom/)
  })
})
