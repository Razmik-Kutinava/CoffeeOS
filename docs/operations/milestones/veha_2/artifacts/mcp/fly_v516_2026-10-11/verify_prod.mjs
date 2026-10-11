// Приёмка TASK_103–107 на проде (Point A) через CDP (headless Chrome).
// node verify_prod.mjs <before|after> [baseUrl]
// Каждый сценарий — отдельный чистый профиль Chrome. Подмена ответов API — CDP Fetch (только в этом браузере,
// на сервере заказы/оплаты не создаются). Клавиатура Android — сжатие visualViewport (layout 100vh не меняется).
import { spawn } from "node:child_process"
import { mkdtempSync, writeFileSync, mkdirSync } from "node:fs"
import { tmpdir } from "node:os"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const label = process.argv[2] || "after"
const base = process.argv[3] || "https://coffeeos.fly.dev"
const TENANT = "2fdee1ac-4674-41ee-b89e-87b45643f789"
const PRODUCT = "3c5259e0-f42f-4d47-953d-2ce82e335f8c"
const SHOP = `${base}/shop?tenant_id=${TENANT}`
const outDir = join(dirname(fileURLToPath(import.meta.url)), label)
mkdirSync(outDir, { recursive: true })
const chromePath = process.env.CHROME_PATH || "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const results = {}
let port = 9400

async function withBrowser(name, fn) {
  port += 1
  const chrome = spawn(chromePath, [
    "--headless=new", `--remote-debugging-port=${port}`,
    `--user-data-dir=${mkdtempSync(join(tmpdir(), "v516-"))}`,
    "--no-first-run", "--hide-scrollbars", "about:blank"
  ], { stdio: "ignore" })
  let wsUrl
  for (let i = 0; i < 60 && !wsUrl; i++) {
    try {
      const list = await (await fetch(`http://127.0.0.1:${port}/json`)).json()
      wsUrl = list.find((t) => t.type === "page")?.webSocketDebuggerUrl
    } catch {}
    if (!wsUrl) await sleep(250)
  }
  const ws = new WebSocket(wsUrl)
  await new Promise((r) => ws.addEventListener("open", r, { once: true }))
  let seq = 0
  const pending = new Map()
  const mocks = []
  const send = (method, params = {}) => new Promise((resolve) => {
    const id = ++seq
    pending.set(id, resolve)
    ws.send(JSON.stringify({ id, method, params }))
  })
  ws.addEventListener("message", (e) => {
    const msg = JSON.parse(e.data)
    if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); return }
    if (msg.method === "Fetch.requestPaused") {
      const { requestId, request } = msg.params
      const m = mocks.find((x) => x.re.test(request.url))
      if (!m) { send("Fetch.continueRequest", { requestId }); return }
      send("Fetch.fulfillRequest", {
        requestId, responseCode: 200,
        responseHeaders: [{ name: "Content-Type", value: "application/json" }],
        body: Buffer.from(JSON.stringify(m.body())).toString("base64")
      })
    }
  })
  const page = {
    send,
    async mock(re, body) {
      mocks.push({ re, body: typeof body === "function" ? body : () => body })
      await send("Fetch.enable", { patterns: [{ urlPattern: "*/shop/api/*", requestStage: "Request" }] })
    },
    async eval(expression) {
      const r = await send("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true })
      if (r.result?.exceptionDetails) throw new Error(JSON.stringify(r.result.exceptionDetails).slice(0, 400))
      return r.result?.result?.value
    },
    async viewport(w, h) {
      await send("Emulation.setDeviceMetricsOverride", { width: w, height: h, deviceScaleFactor: 2, mobile: true })
      await send("Emulation.setTouchEmulationEnabled", { enabled: false })
    },
    async go(hash, wait = 6000) {
      await send("Page.navigate", { url: `${SHOP}#${hash}` })
      await sleep(wait)
    },
    async rect(sel) {
      return page.eval(`(() => { const el = document.querySelector(${JSON.stringify(sel)}); if (!el) return null; const r = el.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2, top: Math.round(r.top), bottom: Math.round(r.bottom), left: Math.round(r.left), right: Math.round(r.right), w: Math.round(r.width), h: Math.round(r.height) } })()`)
    },
    async click(sel) {
      const r = await page.rect(sel)
      if (!r) throw new Error(`no element ${sel}`)
      for (const type of ["mousePressed", "mouseReleased"]) {
        await send("Input.dispatchMouseEvent", { type, x: r.x, y: r.y, button: "left", clickCount: 1 })
      }
      await sleep(700)
      return r
    },
    async wheel(sel, dy) {
      const r = await page.rect(sel)
      if (!r) throw new Error(`no element ${sel}`)
      await send("Input.dispatchMouseEvent", { type: "mouseWheel", x: r.x, y: r.y, deltaX: 0, deltaY: dy })
      await sleep(600)
    },
    async shot(file) {
      const s = await send("Page.captureScreenshot", { format: "png" })
      writeFileSync(join(outDir, file), Buffer.from(s.result.data, "base64"))
    }
  }
  await send("Page.enable")
  await send("Runtime.enable")
  try {
    results[name] = await fn(page)
  } catch (e) {
    results[name] = { error: String(e?.message || e) }
  } finally {
    ws.close()
    chrome.kill()
  }
}

// ---------- общие замеры ----------
const MEASURE_CART = `(() => {
  const q = (s) => document.querySelector(s)
  const r = (el) => { if (!el) return null; const b = el.getBoundingClientRect(); return { top: Math.round(b.top), bottom: Math.round(b.bottom), left: Math.round(b.left), right: Math.round(b.right), h: Math.round(b.height), w: Math.round(b.width) } }
  const sheet = q('[data-testid="shop-cart-sheet"]')
  const btn = q('[data-testid="shop-cart-sheet-checkout"]')
  const repeatSlots = [...document.querySelectorAll('[data-testid^="shop-repeat-slot"]')].map((el) => ({ id: el.dataset.testid, h: Math.round(el.getBoundingClientRect().height), children: el.children.length }))
  return {
    viewport: { w: innerWidth, h: innerHeight },
    sheet: r(sheet), sheetMode: sheet?.dataset.cartSheetMode || null,
    itogoBlock: !!q('[data-testid="shop-cart-order-total"]'),
    itogoTextInSheet: sheet ? /Итого/.test(sheet.innerText) : null,
    checkoutBtn: btn ? { text: btn.innerText.trim(), ...r(btn) } : null,
    emptyText: q('[data-testid="shop-cart-sheet-empty"]')?.innerText.trim() || null,
    repeatSlots,
    repeatSectionRendered: !!sheet?.querySelector('[data-testid^="shop-repeat"] *, .repeat-section'),
    productCta: r(q('[data-testid="shop-product-sheet-cta"]')),
    coldHeader: (() => { const h = [...document.querySelectorAll('h2,h3')].find((x) => /Холодные/.test(x.textContent)); return h ? r(h) : null })()
  }
})()`

const MEASURE_HEADER = `(() => {
  const q = (s) => document.querySelector(s)
  const btn = q('[data-testid="shop-header-profile"]')
  const b = btn?.getBoundingClientRect()
  const header = q('header')?.getBoundingClientRect()
  return {
    profileText: btn ? btn.innerText.trim() : null,
    profileHasSvg: !!btn?.querySelector('svg'),
    badge: !!q('[data-testid="shop-header-profile-id-badge"]'),
    profileInside: b ? b.right <= innerWidth : null,
    address: q('[data-testid="shop-header-tenant-address"]')?.innerText.trim() || null,
    hours: q('[data-testid="shop-hours-display"]')?.innerText.trim() || null,
    headerH: header ? Math.round(header.height) : null
  }
})()`

// ---------- 1. Каталог, пустая корзина + шапка (TASK_106, TASK_107) ----------
await withBrowser("catalog_empty_412x915", async (p) => {
  await p.viewport(412, 915)
  await p.go("/")
  await p.shot("01_catalog_empty_412x915.png")
  return { cart: await p.eval(MEASURE_CART), header: await p.eval(MEASURE_HEADER) }
})

await withBrowser("header_320x640", async (p) => {
  await p.viewport(320, 640)
  await p.go("/")
  const s = await p.send("Page.captureScreenshot", { format: "png", clip: { x: 0, y: 0, width: 320, height: 120, scale: 2 } })
  writeFileSync(join(outDir, "02_header_320x640.png"), Buffer.from(s.result.data, "base64"))
  return await p.eval(MEASURE_HEADER)
})

// ---------- 2. «повторить»: есть на каталоге, нет на товаре (TASK_106) ----------
const FREQUENT = {
  has_active_order: false,
  frequent_items: [{ product_id: PRODUCT, name: "Фильтр-кофе без кофеина (декаф) Гватемала", price: 10, image_url: null, modifier_options: {}, category_id: "08af5e93-b615-4cb1-851f-b25fc79ab714", orders_count: 3 }],
  categories: {}
}
await withBrowser("repeat_catalog_vs_product_412x915", async (p) => {
  await p.mock(/\/shop\/api\/frequent_products/, FREQUENT)
  await p.viewport(412, 915)
  await p.go("/")
  await p.shot("03_catalog_with_repeat_412x915.png")
  const catalog = await p.eval(MEASURE_CART)
  await p.go(`/product/${PRODUCT}`)
  await p.shot("04_product_412x915.png")
  const product = await p.eval(MEASURE_CART)
  return { catalog, product }
})

// ---------- 3. Активные заказы: прокрутка (TASK_103) + стрелка (TASK_104) ----------
function order(i, long) {
  const items = Array.from({ length: long ? 8 : 2 }, (_, k) => ({
    name: `Позиция ${i}.${k + 1}`, quantity: 1, price: 150, line_total: 150,
    modifiers: k === 0 ? [{ name: "Овсяное молоко", price: 40 }] : []
  }))
  return {
    id: `v516-${i}`, order_number: `202610-T${i}`, status: "preparing", can_cancel: false, payment_settled: true,
    sales_point: { name: "Витрина А" }, items, subtotal: items.length * 150 + 40, discount: 0, total_amount: items.length * 150 + 40
  }
}
const MEASURE_ORDERS = `(() => {
  const q = (s) => document.querySelector(s)
  const box = (el) => { if (!el) return null; const r = el.getBoundingClientRect(); const cs = getComputedStyle(el); return { top: Math.round(r.top), bottom: Math.round(r.bottom), h: Math.round(r.height), scrollTop: Math.round(el.scrollTop), scrollH: el.scrollHeight, clientH: el.clientHeight, overflowY: cs.overflowY } }
  const panel = q('.oss__panel')
  const list = q('[data-oss-scroll-root]')
  const clip = (list || panel)?.getBoundingClientRect()
  const rows = [...document.querySelectorAll('.oss__panel .aoa')].map((row) => { const r = row.getBoundingClientRect(); return { top: Math.round(r.top), bottom: Math.round(r.bottom), visiblePx: clip ? Math.round(Math.max(0, Math.min(r.bottom, clip.bottom) - Math.max(r.top, clip.top))) : 0 } })
  const cta = q('.aoa__receipt-cta')
  const ctaCs = cta ? getComputedStyle(cta) : null
  return {
    panel: box(panel), list: box(list), rows, windowScrollY: Math.round(scrollY),
    cart: box(q('[data-testid="shop-cart-sheet"]')),
    cta: cta ? { visibleText: cta.innerText.trim(), ariaLabel: cta.getAttribute('aria-label'), ariaExpanded: cta.getAttribute('aria-expanded'), bg: ctaCs.backgroundColor, color: ctaCs.color, w: Math.round(cta.getBoundingClientRect().width), h: Math.round(cta.getBoundingClientRect().height), right: Math.round(cta.getBoundingClientRect().right), rowRight: Math.round(cta.closest('.aoa').getBoundingClientRect().right) } : null,
    openReceipts: document.querySelectorAll('.aoa__receipt').length
  }
})()`

for (const n of [2, 3]) {
  await withBrowser(`active_orders_${n}_390x844`, async (p) => {
    const orders = Array.from({ length: n }, (_, i) => order(i + 1, false))
    await p.mock(/\/shop\/api\/orders\/active/, { orders })
    await p.viewport(390, 844)
    await p.go("/", 8000)
    await p.shot(`05_orders_${n}_initial.png`)
    const before = await p.eval(MEASURE_ORDERS)
    const target = before.list ? "[data-oss-scroll-root]" : ".oss__panel"
    await p.wheel(target, 400)
    await p.shot(`06_orders_${n}_after_wheel.png`)
    const after = await p.eval(MEASURE_ORDERS)
    return { before, after }
  })
}

await withBrowser("receipt_arrow_toggle_390x844", async (p) => {
  await p.mock(/\/shop\/api\/orders\/active/, { orders: [order(1, true), order(2, false)] })
  await p.viewport(390, 844)
  await p.go("/", 8000)
  const closed = await p.eval(MEASURE_ORDERS)
  const ctaShot = await p.rect(".aoa__receipt-cta")
  await p.shot("07_arrow_closed.png")
  await p.click(".aoa__receipt-cta")
  await sleep(800)
  const opened = await p.eval(MEASURE_ORDERS)
  await p.shot("08_arrow_open.png")
  await p.wheel(".aoa__receipt, [data-oss-scroll-root]", 200)
  const afterReceiptWheel = await p.eval(MEASURE_ORDERS)
  await p.click(".aoa__receipt-cta")
  const closedAgain = await p.eval(MEASURE_ORDERS)
  // клавиатура: Tab-фокус и Enter
  await p.eval(`document.querySelector('.aoa__receipt-cta')?.focus()`)
  await p.send("Input.dispatchKeyEvent", { type: "keyDown", key: "Enter", code: "Enter", windowsVirtualKeyCode: 13 })
  await p.send("Input.dispatchKeyEvent", { type: "keyUp", key: "Enter", code: "Enter", windowsVirtualKeyCode: 13 })
  await sleep(700)
  const afterEnter = await p.eval(MEASURE_ORDERS)
  return { ctaRect: ctaShot, closed, opened, afterReceiptWheel, closedAgain, afterEnter }
})

// ---------- 4. Форма оплаты под цифровой клавиатурой (TASK_105) ----------
const FAKE_VV = `(() => {
  const et = new EventTarget(); let kb = 0
  const vv = {
    get height() { return innerHeight - kb }, get width() { return innerWidth },
    get offsetTop() { return 0 }, get offsetLeft() { return 0 }, get pageTop() { return scrollY }, get pageLeft() { return 0 }, scale: 1,
    addEventListener: et.addEventListener.bind(et), removeEventListener: et.removeEventListener.bind(et), dispatchEvent: et.dispatchEvent.bind(et)
  }
  Object.defineProperty(window, "visualViewport", { configurable: true, get() { return vv } })
  window.__kb = (px) => {
    kb = px
    et.dispatchEvent(new Event("resize"))
    let o = document.getElementById("__kb_overlay")
    if (!px) { o?.remove(); return }
    if (!o) { o = document.createElement("div"); o.id = "__kb_overlay"; document.documentElement.appendChild(o) }
    o.style.cssText = "position:fixed;left:0;right:0;bottom:0;height:" + px + "px;background:rgba(90,90,90,.92);z-index:2147483647;pointer-events:none;color:#fff;font:600 14px sans-serif;display:flex;align-items:center;justify-content:center"
    o.textContent = "цифровая клавиатура " + px + "px (эмуляция)"
  }
})()`
const PROFILE = { id: "v516-check", phone: "+79990000000", phone_verified: true, first_name: "Проверка" }
const CARDS = { cards: [], sbp_accounts: [], primary: null, growth_promo: { eligible: false, amount_rub: 11 } }
const MEASURE_PAY = `(() => {
  const q = (s) => document.querySelector(s)
  const r = (el) => { if (!el) return null; const b = el.getBoundingClientRect(); return { top: Math.round(b.top), bottom: Math.round(b.bottom), h: Math.round(b.height) } }
  const sheet = q('[data-testid="payment-methods-sheet"]')
  const pay = sheet?.querySelector('.pm-sheet__pay')
  const body = sheet?.querySelector('.pm-sheet__body')
  const vvh = visualViewport.height
  const payBtn = pay?.querySelector('button')
  const card = q('input[autocomplete="cc-number"]')
  return {
    visualViewportH: vvh, innerH: innerHeight,
    sheet: r(sheet), payBlock: r(pay), payBtnText: payBtn?.innerText.trim() || null, payBtn: r(payBtn),
    payBtnAboveKeyboard: payBtn ? payBtn.getBoundingClientRect().bottom <= vvh + 1 : null,
    body: body ? { ...r(body), scrollH: body.scrollHeight, clientH: body.clientHeight, overflowY: getComputedStyle(body).overflowY } : null,
    cartSheetRendered: !!q('[data-testid="shop-cart-sheet"]'),
    productCardInPay: !!q('[data-testid="shop-cart-peek-line"], [data-testid="shop-cart-expanded-card"]'),
    totalLine: q('[data-testid="payment-methods-order-total"]')?.innerText.replace(/\\s+/g, " ").trim() || null,
    sbp: r(q('[data-testid="payment-method-sbp"]')),
    cardInput: r(card), activeEl: document.activeElement?.getAttribute('autocomplete') || document.activeElement?.tagName,
    activeVisible: (() => { const a = document.activeElement; if (!a || a === document.body) return null; const b = a.getBoundingClientRect(); return b.top >= 0 && b.bottom <= vvh })(),
    windowScrollY: Math.round(scrollY)
  }
})()`

for (const [w, h] of [[412, 915], [390, 844], [360, 640]]) {
  await withBrowser(`pay_stack_${w}x${h}`, async (p) => {
    await p.send("Page.addScriptToEvaluateOnNewDocument", { source: FAKE_VV })
    await p.mock(/\/shop\/api\/profile/, PROFILE)
    await p.mock(/\/shop\/api\/user\/cards/, CARDS)
    await p.viewport(w, h)
    await p.go(`/product/${PRODUCT}`)
    await p.click('[data-testid="shop-product-add-btn"]')
    await sleep(1500)
    await p.go("/checkout", 6000)
    await p.click('[data-testid="shop-cart-sheet-checkout"]')
    await sleep(2500)
    if (!(await p.rect('[data-testid="payment-methods-sheet"]'))) throw new Error("payment sheet not opened")
    if (!(await p.rect('input[autocomplete="cc-number"]')) && (await p.rect('[data-testid="payment-method-new-card"]'))) {
      await p.click('[data-testid="payment-method-new-card"]')
      await sleep(800)
    }
    const noKb = await p.eval(MEASURE_PAY)
    await p.shot(`09_pay_${w}x${h}_no_keyboard.png`)
    await p.eval(`document.querySelector('input[autocomplete="cc-number"]')?.focus()`)
    await p.eval(`window.__kb(365)`)
    await sleep(800)
    const kbCard = await p.eval(MEASURE_PAY)
    await p.shot(`10_pay_${w}x${h}_keyboard_card.png`)
    const fields = {}
    for (const ac of ["cc-exp", "cc-csc"]) {
      await p.eval(`(() => { const el = document.querySelector('input[autocomplete="${ac}"]'); el?.focus(); el?.scrollIntoView({ block: "nearest" }) })()`)
      await sleep(500)
      fields[ac] = await p.eval(MEASURE_PAY)
    }
    if (kbCard.body && kbCard.body.scrollH > kbCard.body.clientH) {
      await p.wheel('[data-testid="payment-methods-sheet"] .pm-sheet__body', 300)
    }
    const kbScrolled = await p.eval(MEASURE_PAY)
    await p.shot(`11_pay_${w}x${h}_keyboard_scrolled.png`)
    await p.eval(`document.activeElement?.blur(); window.__kb(0)`)
    await sleep(800)
    const kbClosed = await p.eval(MEASURE_PAY)
    await p.shot(`12_pay_${w}x${h}_keyboard_closed.png`)
    return { noKb, kbCard, fields, kbScrolled, kbClosed }
  })
}

writeFileSync(join(outDir, "results.json"), JSON.stringify(results, null, 2))
console.log(JSON.stringify(results, null, 2))
process.exit(0)
