// Приёмка 🚀 1 (очередь Push + SMS, шаги 1–5) на проде (Point A) через CDP (headless Chrome).
// node verify_prod.mjs <before|after> [baseUrl]
// Каждый сценарий — отдельный чистый профиль Chrome (гостевая сессия). Без OTP, без PAN, «Оплатить» не нажимается.
// Network (статусы + тела /shop/api/cart*), Console (error / exception) и скрины пишутся в <label>/.
import { spawn } from "node:child_process"
import { mkdtempSync, writeFileSync, mkdirSync } from "node:fs"
import { tmpdir } from "node:os"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const label = process.argv[2] || "after"
const base = process.argv[3] || "https://coffeeos.fly.dev"
const TENANT_A = "2fdee1ac-4674-41ee-b89e-87b45643f789"
const PRODUCT = "3c5259e0-f42f-4d47-953d-2ce82e335f8c"
const shopUrl = (tenant, hash = "/") => `${base}/shop?tenant_id=${tenant}#${hash}`
const outDir = join(dirname(fileURLToPath(import.meta.url)), label)
mkdirSync(outDir, { recursive: true })
const chromePath = process.env.CHROME_PATH || "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const results = { label, base, startedAt: new Date().toISOString() }
let port = 9500

async function withBrowser(name, fn) {
  port += 1
  const chrome = spawn(chromePath, [
    "--headless=new", `--remote-debugging-port=${port}`,
    `--user-data-dir=${mkdtempSync(join(tmpdir(), "deploy1-"))}`,
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
  const send = (method, params = {}) => new Promise((resolve) => {
    const id = ++seq
    pending.set(id, resolve)
    ws.send(JSON.stringify({ id, method, params }))
  })

  const requests = new Map()
  const network = []
  const consoleErrors = []
  ws.addEventListener("message", async (e) => {
    const msg = JSON.parse(e.data)
    if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); return }
    const p = msg.params || {}
    if (msg.method === "Network.requestWillBeSent") {
      if (!/\/shop\/api\/|\/shop\?|\/shop$/.test(p.request.url)) return
      const row = { url: p.request.url.replace(base, ""), method: p.request.method, type: p.type, status: null, t: Date.now() }
      requests.set(p.requestId, row)
      network.push(row)
    } else if (msg.method === "Network.responseReceived") {
      const row = requests.get(p.requestId)
      if (row) row.status = p.response.status
    } else if (msg.method === "Network.loadingFinished") {
      const row = requests.get(p.requestId)
      if (row && /\/shop\/api\/cart/.test(row.url)) {
        const b = await send("Network.getResponseBody", { requestId: p.requestId })
        try { row.body = JSON.parse(b.result?.body || "null") } catch { row.body = (b.result?.body || "").slice(0, 300) }
      }
    } else if (msg.method === "Network.loadingFailed") {
      const row = requests.get(p.requestId)
      if (row) row.failed = p.errorText
    } else if (msg.method === "Runtime.consoleAPICalled" && p.type === "error") {
      consoleErrors.push({ kind: "console.error", text: (p.args || []).map((a) => a.value ?? a.description ?? "").join(" ").slice(0, 400) })
    } else if (msg.method === "Runtime.exceptionThrown") {
      consoleErrors.push({ kind: "exception", text: (p.exceptionDetails?.exception?.description || p.exceptionDetails?.text || "").slice(0, 400) })
    } else if (msg.method === "Log.entryAdded" && p.entry?.level === "error") {
      consoleErrors.push({ kind: `log.${p.entry.source}`, text: `${p.entry.text} ${p.entry.url || ""}`.slice(0, 400) })
    }
  })
  const page = {
    send, network, consoleErrors,
    async eval(expression) {
      const r = await send("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true })
      if (r.result?.exceptionDetails) throw new Error(JSON.stringify(r.result.exceptionDetails).slice(0, 400))
      return r.result?.result?.value
    },
    async viewport(w, h) {
      await send("Emulation.setDeviceMetricsOverride", { width: w, height: h, deviceScaleFactor: 2, mobile: true })
    },
    async open(url, wait = 8000) {
      await send("Page.navigate", { url })
      await sleep(wait)
    },
    // Тот же path+query с другим hash — переход без перезагрузки; здесь нужна настоящая загрузка.
    async hardOpen(url, wait = 8000) {
      await send("Page.navigate", { url: "about:blank" })
      await sleep(500)
      await send("Page.navigate", { url })
      await sleep(wait)
    },
    async rect(sel) {
      return page.eval(`(() => { const el = document.querySelector(${JSON.stringify(sel)}); if (!el) return null; const r = el.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2, w: Math.round(r.width), h: Math.round(r.height) } })()`)
    },
    async click(sel) {
      const r = await page.rect(sel)
      if (!r) throw new Error(`no element ${sel}`)
      for (const type of ["mousePressed", "mouseReleased"]) {
        await send("Input.dispatchMouseEvent", { type, x: r.x, y: r.y, button: "left", clickCount: 1 })
      }
      await sleep(900)
      return r
    },
    async shot(file) {
      const s = await send("Page.captureScreenshot", { format: "png" })
      writeFileSync(join(outDir, file), Buffer.from(s.result.data, "base64"))
    },
    mark() { return network.length },
    since(i) { return network.slice(i) }
  }
  await send("Page.enable")
  await send("Runtime.enable")
  await send("Log.enable")
  await send("Network.enable")
  try {
    results[name] = await fn(page)
  } catch (e) {
    results[name] = { error: String(e?.message || e) }
  } finally {
    results[name] = { ...(results[name] || {}), consoleErrors, apiNot2xx: network.filter((r) => r.status && r.status >= 400) }
    ws.close()
    chrome.kill()
  }
}

const STATE = `(() => {
  const q = (s) => document.querySelector(s)
  let cartLs = null
  try { cartLs = localStorage.getItem("coffeeos_shop_cart_v1") } catch {}
  let selected = null
  try { selected = localStorage.getItem("shop_selected_tenant") } catch {}
  return {
    href: location.href.replace(location.origin, ""),
    title: document.title,
    address: q('[data-testid="shop-header-tenant-address"]')?.innerText.trim() || null,
    switchable: q('[data-testid="shop-header-tenant-address"]')?.tagName === "BUTTON",
    hours: q('[data-testid="shop-hours-display"]')?.innerText.trim() || null,
    profileLabel: q('[data-testid="shop-header-profile-label"]')?.innerText.trim() || null,
    cartSheet: !!q('[data-testid="shop-cart-sheet"]'),
    cartSheetMode: q('[data-testid="shop-cart-sheet"]')?.dataset.cartSheetMode || null,
    checkoutText: q('[data-testid="shop-cart-sheet-checkout"]')?.innerText.trim() || null,
    cartError: q('[data-testid="shop-cart-error"]')?.innerText.trim() || null,
    resetBannerInBody: document.body.innerText.includes("Корзина очищена: вы перешли в другую точку"),
    cartLs, selected,
    envGuard: (() => { try { return sessionStorage.getItem("coffeeos_env_session_open_v1") } catch { return "n/a" } })()
  }
})()`

const cartCalls = (rows) => rows.filter((r) => /\/shop\/api\/cart/.test(r.url)).map((r) => ({ method: r.method, url: r.url, status: r.status, cart_reset: r.body?.cart_reset ?? null, items: (r.body?.items || r.body?.cart || []).length }))
const envCalls = (rows) => rows.filter((r) => /environment_events/.test(r.url)).map((r) => ({ method: r.method, type: r.type, status: r.status, failed: r.failed || null }))

async function addProduct(p, tenantLabel) {
  await p.open(shopUrl(currentTenant(p), `/product/${PRODUCT}`), 7000)
  const btn = await p.rect('[data-testid="shop-product-add-btn"]')
  if (!btn) throw new Error(`${tenantLabel}: no add button for ${PRODUCT}`)
  const i = p.mark()
  await p.click('[data-testid="shop-product-add-btn"]')
  await sleep(2000)
  return cartCalls(p.since(i))
}

let tenantOf = new WeakMap()
const currentTenant = (p) => tenantOf.get(p) || TENANT_A

async function switchViaHeader(p) {
  await p.open(shopUrl(currentTenant(p), "/"), 7000)
  const st = await p.eval(STATE)
  if (!st.switchable) return { switched: false, reason: "в шапке нет переключателя точек (одна активная точка)" }
  await p.click('[data-testid="shop-header-tenant-address"]')
  const options = await p.eval(`[...document.querySelectorAll('[data-testid="shop-tenant-dropdown"] li')].map((li, i) => ({ i, current: li.getAttribute("aria-selected") === "true", text: li.innerText.trim() }))`)
  const target = options.find((o) => !o.current)
  if (!target) return { switched: false, reason: "в списке нет другой точки", options }
  const i = p.mark()
  await p.eval(`document.querySelectorAll('[data-testid="shop-tenant-dropdown"] li button')[${target.i}].click()`)
  await sleep(9000)
  const after = await p.eval(STATE)
  const tid = new URL(base + after.href).searchParams.get("tenant_id")
  if (tid) tenantOf.set(p, tid)
  return { switched: true, options, to: target.text, tenantId: tid, cart: cartCalls(p.since(i)), state: after }
}

// ONLY=task120_kitchen — только сценарий 4 (суррогат точки B, см. ниже)
const ONLY = process.env.ONLY || null
const run = (name) => !ONLY || ONLY === name

// ---------- 1. Каталог Point A + TASK_112 (одно событие за вкладку, перезагрузка без дубля) ----------
if (run("main")) await withBrowser("catalog_and_env_event_412x915", async (p) => {
  await p.viewport(412, 915)
  await p.open(shopUrl(TENANT_A, "/"), 9000)
  const first = await p.eval(STATE)
  await p.shot("01_catalog_point_a_412x915.png")
  const envFirst = envCalls(p.network)
  await p.send("Page.reload", {})
  await sleep(9000)
  const afterReload = await p.eval(STATE)
  const envTotal = envCalls(p.network)
  return { first, afterReload, envFirst, envTotal, api: p.network.filter((r) => /\/shop\/api\//.test(r.url)).map((r) => `${r.method} ${r.url.split("?")[0]} ${r.status}`) }
})

// ---------- 2. TASK_120: корзина A → переход в B → сброс; пустая корзина → без баннера; снова A ----------
if (run("main")) await withBrowser("cart_tenant_switch_412x915", async (p) => {
  await p.viewport(412, 915)
  tenantOf.set(p, TENANT_A)
  await p.open(shopUrl(TENANT_A, "/"), 9000)
  const addA = await addProduct(p, "A")
  await p.open(shopUrl(TENANT_A, "/"), 7000)
  const stateA = await p.eval(STATE)
  await p.shot("02_point_a_cart_1_item.png")

  const toB = await switchViaHeader(p)
  if (!toB.switched) return { addA, stateA, toB }
  await p.shot("03_point_b_cart_reset_banner.png")

  const toAEmpty = await switchViaHeader(p)
  await p.shot("04_back_to_a_empty_cart_no_banner.png")

  const addAagain = await addProduct(p, "A again")
  await p.open(shopUrl(currentTenant(p), "/"), 7000)
  const stateAagain = await p.eval(STATE)
  await p.shot("05_point_a_add_again.png")
  return { addA, stateA, toB, toAEmpty, addAagain, stateAagain }
})

// ---------- 3. RUBY-1R: поддельный Client-IP → не 500 (только after: до фикса это 500 → шум в Sentry) ----------
if (label === "after" && run("main")) {
  const rows = []
  for (const url of [shopUrl(TENANT_A, "/").split("#")[0], `${base}/up`]) {
    const r = await fetch(url, { headers: { "Client-IP": "1.2.3.4" }, redirect: "manual" })
    rows.push({ url: url.replace(base, ""), status: r.status })
  }
  results.ruby_1r_client_ip = rows
}

// ---------- 4. TASK_120 суррогат: на проде одна торговая точка, B = кухня (единственная другая активная) ----------
// Shop API находит точку по id без фильтра по типу → первый GET /cart?tenant_id=<кухня> уходит до того,
// как bootstrap вернёт гостя в A (кухни нет в /tenants). Баннер так не увидеть — страница перезагружается.
const KITCHEN = "d47165db-81c9-4e9d-bc50-e37fe610d86c"
if (run("task120_kitchen")) await withBrowser("task120_kitchen_as_b_412x915", async (p) => {
  await p.viewport(412, 915)
  tenantOf.set(p, TENANT_A)
  await p.open(shopUrl(TENANT_A, "/"), 9000)
  const addA = await addProduct(p, "A")
  await p.open(shopUrl(TENANT_A, "/"), 7000)
  const stateA = await p.eval(STATE)
  await p.shot("06_task120_point_a_cart_1_item.png")

  const iB = p.mark()
  await p.hardOpen(shopUrl(KITCHEN, "/"), 11000)
  const onB = cartCalls(p.since(iB))
  const configOnB = p.since(iB).filter((r) => /\/shop\/api\/config/.test(r.url)).map((r) => r.status)
  const afterB = await p.eval(STATE)
  await p.shot("07_task120_point_b_cart_reset_banner.png")

  const iEmpty = p.mark()
  await p.hardOpen(shopUrl(KITCHEN, "/"), 11000)
  const emptyOnB = cartCalls(p.since(iEmpty))
  const afterEmpty = await p.eval(STATE)
  await p.shot("07b_task120_point_b_empty_cart_no_banner.png")

  const iBack = p.mark()
  await p.hardOpen(shopUrl(TENANT_A, "/"), 9000)
  const backToA = cartCalls(p.since(iBack))
  const afterBackToA = await p.eval(STATE)

  const addAagain = await addProduct(p, "A again")
  await p.hardOpen(shopUrl(TENANT_A, "/"), 7000)
  const stateAagain = await p.eval(STATE)
  await p.shot("08_task120_point_a_add_again.png")
  const timeline = p.network.filter((r) => /\/shop\/api\/|\/shop\?/.test(r.url)).map((r) => ({
    at: new Date(r.t).toISOString().slice(11, 19), req: `${r.method} ${r.url.split("?")[0]}`,
    tenant: (r.url.match(/tenant_id=([0-9a-f]{8})/) || [])[1] || "-", status: r.status,
    cart: r.body && typeof r.body === "object" ? { items: (r.body.items || r.body.cart || []).length, cart_reset: r.body.cart_reset ?? null } : undefined
  }))
  return { addA, stateA, onB, configOnB, afterB, emptyOnB, afterEmpty, backToA, afterBackToA, addAagain, stateAagain, timeline }
})

results.finishedAt = new Date().toISOString()
const outFile = ONLY ? `results_${ONLY}.json` : "results.json"
writeFileSync(join(outDir, outFile), JSON.stringify(results, null, 2))
console.log(JSON.stringify(results, null, 2))
process.exit(0)
