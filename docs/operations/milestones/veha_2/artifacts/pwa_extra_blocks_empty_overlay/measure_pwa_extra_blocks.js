// TASK_106 — замер нижней шторки витрины (вставить в DevTools / CDP Runtime.evaluate на /shop#/ или #/product/:id).
// Viewport задаётся отдельно: Emulation.setDeviceMetricsOverride { width: 412, height: 915, deviceScaleFactor: 2.625, mobile: true }.
(() => {
  const rect = (el) => {
    if (!el) return null
    const b = el.getBoundingClientRect()
    return { top: Math.round(b.top), bottom: Math.round(b.bottom), h: Math.round(b.height), left: Math.round(b.left), w: Math.round(b.width) }
  }
  const q = (s) => document.querySelector(s)
  const sheet = q("[data-testid=shop-cart-sheet]")
  const button = q("[data-testid=shop-cart-sheet-checkout]")
  const cold = [...document.querySelectorAll("h2")].find((h) => h.textContent.trim() === "Холодные")
  const sections = sheet ? [...sheet.children] : []
  const lastBottom = sections.length ? sections[sections.length - 1].getBoundingClientRect().bottom : null
  return {
    hash: location.hash,
    viewport: { w: innerWidth, h: innerHeight, visual: visualViewport?.height },
    mode: sheet?.dataset.cartSheetMode,
    sheet: rect(sheet),
    cartSheetH: getComputedStyle(document.documentElement).getPropertyValue("--cart-sheet-h"),
    sections: sections.map((c) => ({ id: c.dataset.testid || c.className.slice(0, 30), ...rect(c) })),
    emptyBelowContentPx: sheet && lastBottom != null ? Math.round(sheet.getBoundingClientRect().bottom - lastBottom) : null,
    itogoVisible: !!sheet?.textContent.includes("Итого"),
    button: rect(button),
    buttonText: button?.textContent.trim(),
    repeatInSheet: !!q("[data-testid=shop-repeat-section]"),
    productCta: rect(q("[data-testid=shop-product-sheet-cta]")),
    coldHeading: rect(cold)
  }
})()
