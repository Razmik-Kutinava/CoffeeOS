// Досъёмка к verify_prod.mjs (только после деплоя):
//  a) 2 заказа — промежуточная прокрутка: номер второго заказа виден;
//  b) стрелка состава — активация клавишей Enter / Space (keyDown с text, как реальная клавиатура);
//  c) 360×640 — поле номера карты в фокусе докручивается внутри тела шторки оплаты.
// node verify_extra.mjs [baseUrl]
import { spawn } from "node:child_process"
import { mkdtempSync, writeFileSync, mkdirSync } from "node:fs"
import { tmpdir } from "node:os"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const base = process.argv[2] || "https://coffeeos.fly.dev"
const TENANT = "2fdee1ac-4674-41ee-b89e-87b45643f789"
const PRODUCT = "3c5259e0-f42f-4d47-953d-2ce82e335f8c"
const SHOP = `${base}/shop?tenant_id=${TENANT}`
const outDir = join(dirname(fileURLToPath(import.meta.url)), "after")
mkdirSync(outDir, { recursive: true })
const chromePath = process.env.CHROME_PATH || "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const results = {}
let port = 9500

async function withBrowser(name, fn) {
  port += 1
  const chrome = spawn(chromePath, ["--headless=new", `--remote-debugging-port=${port}`, `--user-data-dir=${mkdtempSync(join(tmpdir(), "v516x-"))}`, "--no-first-run", "--hide-scrollbars", "about:blank"], { stdio: "ignore" })
  let wsUrl
  for (let i = 0; i < 60 && !wsUrl; i++) {
    try { wsUrl = (await (await fetch(`http://127.0.0.1:${port}/json`)).json()).find((t) => t.type === "page")?.webSocketDebuggerUrl } catch {}
    if (!wsUrl) await sleep(250)
  }
  const ws = new WebSocket(wsUrl)
  await new Promise((r) => ws.addEventListener("open", r, { once: true }))
  let seq = 0
  const pending = new Map()
  const mocks = []
  const send = (method, params = {}) => new Promise((resolve) => { const id = ++seq; pending.set(id, resolve); ws.send(JSON.stringify({ id, method, params })) })
  ws.addEventListener("message", (e) => {
    const msg = JSON.parse(e.data)
    if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); return }
    if (msg.method === "Fetch.requestPaused") {
      const { requestId, request } = msg.params
      const m = mocks.find((x) => x.re.test(request.url))
      if (!m) { send("Fetch.continueRequest", { requestId }); return }
      send("Fetch.fulfillRequest", { requestId, responseCode: 200, responseHeaders: [{ name: "Content-Type", value: "application/json" }], body: Buffer.from(JSON.stringify(m.body)).toString("base64") })
    }
  })
  const p = {
    send,
    async mock(re, body) { mocks.push({ re, body }); await send("Fetch.enable", { patterns: [{ urlPattern: "*/shop/api/*", requestStage: "Request" }] }) },
    async eval(expression) { const r = await send("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true }); return r.result?.result?.value },
    async rect(sel) { return p.eval(`(() => { const el = document.querySelector(${JSON.stringify(sel)}); if (!el) return null; const r = el.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 } })()`) },
    async click(sel) { const r = await p.rect(sel); for (const type of ["mousePressed", "mouseReleased"]) await send("Input.dispatchMouseEvent", { type, x: r.x, y: r.y, button: "left", clickCount: 1 }); await sleep(700) },
    async key(key, code, vk, text) {
      await send("Input.dispatchKeyEvent", { type: "keyDown", key, code, windowsVirtualKeyCode: vk, text })
      await send("Input.dispatchKeyEvent", { type: "keyUp", key, code, windowsVirtualKeyCode: vk })
      await sleep(700)
    },
    async shot(file) { const s = await send("Page.captureScreenshot", { format: "png" }); writeFileSync(join(outDir, file), Buffer.from(s.result.data, "base64")) }
  }
  await send("Page.enable"); await send("Runtime.enable")
  try { results[name] = await fn(p) } catch (e) { results[name] = { error: String(e?.message || e) } } finally { ws.close(); chrome.kill() }
}

function order(i, long) {
  const items = Array.from({ length: long ? 8 : 2 }, (_, k) => ({ name: `Позиция ${i}.${k + 1}`, quantity: 1, price: 150, line_total: 150, modifiers: [] }))
  return { id: `v516-${i}`, order_number: `202610-T${i}`, status: "preparing", can_cancel: false, payment_settled: true, sales_point: { name: "Витрина А" }, items, subtotal: items.length * 150, discount: 0, total_amount: items.length * 150 }
}
const VISIBLE_TEXT = `(() => {
  const list = document.querySelector('[data-oss-scroll-root]'); const c = list.getBoundingClientRect()
  return [...list.querySelectorAll('.aoa')].map((row) => { const meta = row.querySelector('[class*="meta"]') || row; const m = meta.getBoundingClientRect(); return { text: meta.innerText.split('\\n')[0].slice(0, 60), metaFullyVisible: m.top >= c.top && m.bottom <= c.bottom } })
})()`

await withBrowser("orders_2_mid_scroll", async (p) => {
  await p.mock(/\/shop\/api\/orders\/active/, { orders: [order(1), order(2)] })
  await p.send("Emulation.setDeviceMetricsOverride", { width: 390, height: 844, deviceScaleFactor: 2, mobile: true })
  await p.send("Page.navigate", { url: `${SHOP}#/` }); await sleep(8000)
  const r = await p.rect("[data-oss-scroll-root]")
  await p.send("Input.dispatchMouseEvent", { type: "mouseWheel", x: r.x, y: r.y, deltaX: 0, deltaY: 140 }); await sleep(700)
  await p.shot("13_orders_2_mid_scroll.png")
  return { scrollTop: await p.eval(`document.querySelector('[data-oss-scroll-root]').scrollTop`), windowScrollY: await p.eval("scrollY"), rows: await p.eval(VISIBLE_TEXT) }
})

await withBrowser("arrow_keyboard", async (p) => {
  await p.mock(/\/shop\/api\/orders\/active/, { orders: [order(1, true), order(2)] })
  await p.send("Emulation.setDeviceMetricsOverride", { width: 390, height: 844, deviceScaleFactor: 2, mobile: true })
  await p.send("Page.navigate", { url: `${SHOP}#/` }); await sleep(8000)
  const st = () => p.eval(`(() => { const b = document.querySelector('.aoa__receipt-cta'); return { focused: document.activeElement === b, ariaExpanded: b.getAttribute('aria-expanded'), text: b.innerText.trim(), receipts: document.querySelectorAll('.aoa__receipt').length, outline: getComputedStyle(b).outlineStyle } })()`)
  await p.eval(`document.querySelector('.aoa__receipt-cta').focus({ focusVisible: true })`)
  const focused = await st()
  await p.key("Enter", "Enter", 13, "\r")
  const afterEnter = await st()
  await p.shot("14_arrow_after_enter.png")
  await p.key(" ", "Space", 32, " ")
  const afterSpace = await st()
  return { focused, afterEnter, afterSpace }
})

const FAKE_VV = `(() => { const et = new EventTarget(); let kb = 0
  const vv = { get height() { return innerHeight - kb }, get width() { return innerWidth }, get offsetTop() { return 0 }, get offsetLeft() { return 0 }, get pageTop() { return scrollY }, get pageLeft() { return 0 }, scale: 1, addEventListener: et.addEventListener.bind(et), removeEventListener: et.removeEventListener.bind(et), dispatchEvent: et.dispatchEvent.bind(et) }
  Object.defineProperty(window, "visualViewport", { configurable: true, get() { return vv } })
  window.__kb = (px) => { kb = px; et.dispatchEvent(new Event("resize")); let o = document.getElementById("__kb_overlay"); if (!px) { o?.remove(); return } if (!o) { o = document.createElement("div"); o.id = "__kb_overlay"; document.documentElement.appendChild(o) } o.style.cssText = "position:fixed;left:0;right:0;bottom:0;height:" + px + "px;background:rgba(90,90,90,.92);z-index:2147483647;pointer-events:none;color:#fff;font:600 14px sans-serif;display:flex;align-items:center;justify-content:center"; o.textContent = "цифровая клавиатура " + px + "px (эмуляция)" }
})()`

await withBrowser("pay_360x640_card_number_focus", async (p) => {
  await p.send("Page.addScriptToEvaluateOnNewDocument", { source: FAKE_VV })
  await p.mock(/\/shop\/api\/profile/, { id: "v516-check", phone: "+79990000000", phone_verified: true, first_name: "Проверка" })
  await p.mock(/\/shop\/api\/user\/cards/, { cards: [], sbp_accounts: [], primary: null, growth_promo: { eligible: false, amount_rub: 11 } })
  await p.send("Emulation.setDeviceMetricsOverride", { width: 360, height: 640, deviceScaleFactor: 2, mobile: true })
  await p.send("Page.navigate", { url: `${SHOP}#/product/${PRODUCT}` }); await sleep(6000)
  await p.click('[data-testid="shop-product-add-btn"]'); await sleep(1500)
  await p.send("Page.navigate", { url: `${SHOP}#/checkout` }); await sleep(6000)
  await p.click('[data-testid="shop-cart-sheet-checkout"]'); await sleep(2500)
  if (!(await p.rect('input[autocomplete="cc-number"]')) && (await p.rect('[data-testid="payment-method-new-card"]'))) { await p.click('[data-testid="payment-method-new-card"]'); await sleep(800) }
  await p.eval(`window.__kb(365)`); await sleep(600)
  await p.eval(`(() => { const el = document.querySelector('input[autocomplete="cc-number"]'); el.focus(); el.scrollIntoView({ block: "nearest" }) })()`); await sleep(600)
  await p.shot("15_pay_360x640_keyboard_card_number.png")
  return await p.eval(`(() => { const vvh = visualViewport.height; const a = document.activeElement.getBoundingClientRect(); const pay = document.querySelector('[data-testid="payment-methods-sheet"] .pm-sheet__pay button').getBoundingClientRect(); return { vvh, active: document.activeElement.getAttribute('autocomplete'), fieldTop: Math.round(a.top), fieldBottom: Math.round(a.bottom), fieldVisible: a.top >= 0 && a.bottom <= vvh, payBottom: Math.round(pay.bottom), payAboveKb: pay.bottom <= vvh + 1, overlap: a.bottom > pay.top && a.top < pay.bottom, windowScrollY: scrollY } })()`)
})

writeFileSync(join(outDir, "results_extra.json"), JSON.stringify(results, null, 2))
console.log(JSON.stringify(results, null, 2))
process.exit(0)
