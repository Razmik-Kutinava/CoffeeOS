// Приёмка повторного 🚀 1 (TASK_120 Патч 1) на проде (Point A) через CDP (headless Chrome).
// Основа — fly_v517_2026-10-28/verify_prod.mjs; добавлены сырые заголовки (set-cookie ответа, cookie запроса).
// node verify_prod.mjs <label> [baseUrl]      ONLY=a|b|d — один сценарий
// Каждый сценарий — отдельный чистый профиль Chrome (гостевая сессия). Без OTP, без PAN, «Оплатить» не нажимается.
// Точка B — кухня (на проде одна торговая точка; shop API находит точку по id без фильтра по типу, см. v517).
import { spawn } from "node:child_process"
import { mkdtempSync, writeFileSync, mkdirSync } from "node:fs"
import { tmpdir } from "node:os"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const label = process.argv[2] || "after"
const base = process.argv[3] || "https://coffeeos.fly.dev"
const TENANT_A = "2fdee1ac-4674-41ee-b89e-87b45643f789"
const KITCHEN = "d47165db-81c9-4e9d-bc50-e37fe610d86c"
const PRODUCT = "3c5259e0-f42f-4d47-953d-2ce82e335f8c"
const SESSION_KEY = "_coffeeos_session"
const shopUrl = (tenant, hash = "/") => `${base}/shop?tenant_id=${tenant}#${hash}`
const outDir = join(dirname(fileURLToPath(import.meta.url)), label)
mkdirSync(outDir, { recursive: true })
const chromePath = process.env.CHROME_PATH || "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const results = { label, base, startedAt: new Date().toISOString() }
let port = 9600

async function withBrowser(name, fn) {
  port += 1
  const chrome = spawn(chromePath, [
    "--headless=new", `--remote-debugging-port=${port}`,
    `--user-data-dir=${mkdtempSync(join(tmpdir(), "deploy1r-"))}`,
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
  const reqExtra = new Map()
  const resExtra = new Map()
  const network = []
  // Прочие запросы (статика, 404, cable) — в отчёт попадают только если пишут cookie сессии.
  const otherRows = []
  const consoleErrors = []
  const attachExtra = (id) => {
    const row = requests.get(id)
    if (!row) return
    const rq = reqExtra.get(id)
    const tail = (v) => (v ? v.slice(-10) : null)
    if (rq) {
      row.hadCookie = new RegExp(`(^|;\\s*)${SESSION_KEY}=`).test(rq.cookie || "")
      row.sentTail = tail((rq.cookie || "").match(new RegExp(`${SESSION_KEY}=([^;]+)`))?.[1])
    }
    const rs = resExtra.get(id)
    if (rs !== undefined) {
      const sc = rs.split("\n").filter((c) => c.startsWith(`${SESSION_KEY}=`))
      row.setTail = tail(sc[0]?.split(";")[0])
      row.setCookie = sc.length > 0
      row.setCookieExpires = sc.some((c) => /;\s*expires=/i.test(c))
    }
  }
  ws.addEventListener("message", async (e) => {
    const msg = JSON.parse(e.data)
    if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); return }
    const p = msg.params || {}
    if (msg.method === "Network.requestWillBeSent") {
      const row = { url: p.request.url.replace(base, ""), method: p.request.method, type: p.type, status: null, t: Date.now(), hadCookie: null, setCookie: null }
      requests.set(p.requestId, row)
      if (/\/shop\/api\/|\/shop\?|\/shop$|\/shop\/(manifest\.webmanifest|service-worker\.js)/.test(p.request.url)) network.push(row)
      else otherRows.push(row)
      attachExtra(p.requestId)
    } else if (msg.method === "Network.requestWillBeSentExtraInfo") {
      const h = p.headers || {}
      reqExtra.set(p.requestId, { cookie: h.cookie || h.Cookie || "" })
      attachExtra(p.requestId)
    } else if (msg.method === "Network.responseReceivedExtraInfo") {
      const h = p.headers || {}
      resExtra.set(p.requestId, h["set-cookie"] || h["Set-Cookie"] || "")
      attachExtra(p.requestId)
    } else if (msg.method === "Network.responseReceived") {
      const row = requests.get(p.requestId)
      if (row) row.status = p.response.status
    } else if (msg.method === "Network.loadingFinished") {
      const row = requests.get(p.requestId)
      attachExtra(p.requestId)
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
    await sleep(1500)
    results[name] = {
      ...(results[name] || {}),
      consoleErrors,
      jsExceptions: consoleErrors.filter((c) => c.kind === "exception" || c.kind === "console.error"),
      apiNot2xx: network.filter((r) => r.status && r.status >= 400).map((r) => `${r.method} ${r.url.split("?")[0]} ${r.status}`),
      otherSessionWrites: otherRows.filter((r) => r.setCookie).map((r) => ({ at: new Date(r.t).toISOString().slice(11, 19), req: `${r.method} ${r.url.split("?")[0]}`, status: r.status, sentTail: r.sentTail ?? null, setTail: r.setTail ?? null })),
      headers: network.map((r) => ({ at: new Date(r.t).toISOString().slice(11, 19), req: `${r.method} ${r.url.split("?")[0]}`, status: r.status, hadCookie: r.hadCookie, sentTail: r.sentTail ?? null, setCookie: r.setCookie, setTail: r.setTail ?? null, expires: r.setCookieExpires ?? null, cart_reset: r.body?.cart_reset ?? undefined }))
    }
    ws.close()
    chrome.kill()
  }
}

const STATE = `(() => {
  const q = (s) => document.querySelector(s)
  let cartLs = null
  try { const raw = localStorage.getItem("coffeeos_shop_cart_v1"); const j = JSON.parse(raw || "null"); cartLs = j ? { items: (j.payload?.items || []).length, total: j.payload?.total ?? null, cart_reset: j.payload?.cart_reset ?? null } : null } catch {}
  return {
    href: location.href.replace(location.origin, ""),
    address: q('[data-testid="shop-header-tenant-address"]')?.innerText.trim() || null,
    hours: q('[data-testid="shop-hours-display"]')?.innerText.trim() || null,
    profileLabel: q('[data-testid="shop-header-profile-label"]')?.innerText.trim() || null,
    cartSheet: !!q('[data-testid="shop-cart-sheet"]'),
    cartSheetMode: q('[data-testid="shop-cart-sheet"]')?.dataset.cartSheetMode || null,
    checkoutText: q('[data-testid="shop-cart-sheet-checkout"]')?.innerText.trim() || null,
    cartError: q('[data-testid="shop-cart-error"]')?.innerText.trim() || null,
    resetBannerInBody: document.body.innerText.includes("Корзина очищена: вы перешли в другую точку"),
    cartLs,
    envGuard: (() => { try { return sessionStorage.getItem("coffeeos_env_session_open_v1") } catch { return "n/a" } })()
  }
})()`

const cartCalls = (rows) => rows.filter((r) => /\/shop\/api\/cart/.test(r.url)).map((r) => ({ method: r.method, url: r.url.split("?")[0], tenant: (r.url.match(/tenant_id=([0-9a-f]{8})/) || [])[1] || "-", status: r.status, cart_reset: r.body?.cart_reset ?? null, items: (r.body?.items || r.body?.cart || []).length, setCookie: r.setCookie }))
const resetCount = (calls) => calls.filter((c) => c.cart_reset === true).length
const envCalls = (rows) => rows.filter((r) => /environment_events/.test(r.url)).map((r) => ({ method: r.method, type: r.type, status: r.status, failed: r.failed || null }))

async function addProduct(p, tenant, tag) {
  await p.open(shopUrl(tenant, `/product/${PRODUCT}`), 7000)
  const btn = await p.rect('[data-testid="shop-product-add-btn"]')
  if (!btn) throw new Error(`${tag}: no add button for ${PRODUCT}`)
  const i = p.mark()
  await p.click('[data-testid="shop-product-add-btn"]')
  await sleep(2500)
  return cartCalls(p.since(i))
}

const ONLY = process.env.ONLY || null
const run = (name) => !ONLY || ONLY === name

// ---------- a) TASK_120: A (товар) → B (сброс + баннер) → снова B (без сброса) → A (пусто, без сброса) ----------
if (run("a")) await withBrowser("a_task120_a_b_b_a_412x915", async (p) => {
  await p.viewport(412, 915)
  await p.open(shopUrl(TENANT_A, "/"), 9000)
  const addA = await addProduct(p, TENANT_A, "A")
  await p.open(shopUrl(TENANT_A, "/"), 7000)
  const stateA = await p.eval(STATE)
  await p.shot("a1_point_a_cart_1_item.png")

  const iB = p.mark()
  await p.hardOpen(shopUrl(KITCHEN, "/"), 12000)
  const onB = cartCalls(p.since(iB))
  const afterB = await p.eval(STATE)
  await p.shot("a2_point_b_cart_reset_banner.png")

  const iB2 = p.mark()
  await p.hardOpen(shopUrl(KITCHEN, "/"), 12000)
  const onB2 = cartCalls(p.since(iB2))
  const afterB2 = await p.eval(STATE)
  await p.shot("a3_point_b_again_no_banner.png")

  const iA = p.mark()
  await p.hardOpen(shopUrl(TENANT_A, "/"), 12000)
  const backToA = cartCalls(p.since(iA))
  const afterBackToA = await p.eval(STATE)
  await p.shot("a4_back_to_a_empty_cart.png")

  // Дать отработать опросу (8 с) и перезагрузить: корзина A не должна «вернуться».
  await sleep(18000)
  const iA2 = p.mark()
  await p.hardOpen(shopUrl(TENANT_A, "/"), 10000)
  const reloadA = cartCalls(p.since(iA2))
  const afterReloadA = await p.eval(STATE)
  await p.shot("a5_point_a_after_poll_reload_empty.png")

  return {
    addA, stateA,
    onB, onB_resets: resetCount(onB), afterB,
    onB2, onB2_resets: resetCount(onB2), afterB2,
    backToA, backToA_resets: resetCount(backToA), afterBackToA,
    reloadA, afterReloadA
  }
})

// ---------- b) Гонка с опросом: товар в A, ≥30 с опроса, перезагрузка — товар на месте ----------
if (run("b")) await withBrowser("b_poll_race_412x915", async (p) => {
  await p.viewport(412, 915)
  await p.open(shopUrl(TENANT_A, "/"), 9000)
  const add = await addProduct(p, TENANT_A, "A")
  await p.open(shopUrl(TENANT_A, "/"), 3000)
  const iWait = p.mark()
  const waitStart = Date.now()
  await sleep(35000)
  const waitedMs = Date.now() - waitStart
  const during = p.since(iWait).map((r) => `${r.method} ${r.url.split("?")[0]} ${r.status} setCookie=${r.setCookie}`)
  const beforeReload = await p.eval(STATE)
  const iR = p.mark()
  await p.send("Page.reload", {})
  await sleep(10000)
  const afterReloadCart = cartCalls(p.since(iR))
  const afterReload = await p.eval(STATE)
  await p.shot("b1_point_a_after_35s_poll_reload.png")
  return { add, waitedMs, during, beforeReload, afterReloadCart, afterReload }
})

// ---------- d) Регрессия v517: каталог, шапка, шторка, TASK_112 beacon (1 за вкладку), /config + /tenants ----------
if (run("d")) await withBrowser("d_catalog_env_event_412x915", async (p) => {
  await p.viewport(412, 915)
  await p.open(shopUrl(TENANT_A, "/"), 9000)
  const first = await p.eval(STATE)
  await p.shot("d1_catalog_point_a_412x915.png")
  const envFirst = envCalls(p.network)
  await p.send("Page.reload", {})
  await sleep(9000)
  const afterReload = await p.eval(STATE)
  const envTotal = envCalls(p.network)
  const configTenants = p.network.filter((r) => /\/shop\/api\/(config|tenants)\b/.test(r.url)).map((r) => `${r.method} ${r.url.split("?")[0]} ${r.status}`)
  return { first, afterReload, envFirst, envTotal, configTenants, api: p.network.filter((r) => /\/shop\/api\//.test(r.url)).map((r) => `${r.method} ${r.url.split("?")[0]} ${r.status}`) }
})

// ---------- c) Заголовки: сводка по всем сценариям ----------
const allRows = Object.entries(results).filter(([, v]) => v && Array.isArray(v.headers)).flatMap(([, v]) => v.headers)
const summary = {}
for (const h of allRows) {
  const key = h.req + (h.cart_reset === true ? " [cart_reset]" : "")
  const s = summary[key] ||= { total: 0, withCookieReq: 0, setCookie: 0, setCookieWithExpires: 0, setCookieUnknown: 0 }
  s.total += 1
  if (h.hadCookie) s.withCookieReq += 1
  if (h.setCookie === true) s.setCookie += 1
  if (h.setCookie === null) s.setCookieUnknown += 1
  if (h.expires) s.setCookieWithExpires += 1
}
results.c_headers_summary = summary

results.finishedAt = new Date().toISOString()
const outFile = ONLY ? `results_${ONLY}.json` : "results.json"
writeFileSync(join(outDir, outFile), JSON.stringify(results, null, 2))
console.log(JSON.stringify({ c_headers_summary: summary }, null, 2))
process.exit(0)
