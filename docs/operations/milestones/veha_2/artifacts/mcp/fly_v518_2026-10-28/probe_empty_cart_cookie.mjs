// Проба на проде: пишет ли GET /shop/api/cart cookie сессии при пустой, ни разу не тронутой корзине.
// Последовательно, один гость, без браузера. node probe_empty_cart_cookie.mjs [baseUrl]
const base = process.argv[2] || "https://coffeeos.fly.dev"
const TENANT_A = "2fdee1ac-4674-41ee-b89e-87b45643f789"
const KEY = "_coffeeos_session"
let cookie = null
let csrf = null
const log = []

async function req(label, path, { api = false } = {}) {
  const headers = {}
  if (cookie) headers.cookie = `${KEY}=${cookie}`
  if (api) {
    headers["X-Shop-Tenant"] = TENANT_A
    headers.accept = "application/json"
    headers.referer = `${base}/shop?tenant_id=${TENANT_A}`
    if (csrf) headers["X-CSRF-Token"] = csrf
  }
  const r = await fetch(base + path, { headers, redirect: "manual" })
  const sc = (r.headers.getSetCookie?.() || []).find((c) => c.startsWith(`${KEY}=`))
  const body = await r.text()
  if (!api) csrf = body.match(/name="csrf-token" content="([^"]+)"/)?.[1] || csrf
  let items = null
  if (api && /cart/.test(path)) { try { items = JSON.parse(body).items?.length ?? null } catch {} }
  log.push({ label, status: r.status, setCookie: !!sc, cookieLen: sc ? sc.split(";")[0].length : null, items })
  if (sc) cookie = sc.split(";")[0].slice(KEY.length + 1)
}

const PARALLEL = process.env.PARALLEL === "1"
const page = async (tag) => {
  await req(`GET /shop (${tag})`, `/shop?tenant_id=${TENANT_A}`)
  if (PARALLEL) {
    // Как витрина при загрузке: несколько запросов с одной и той же cookie одновременно.
    await Promise.all([
      req(`${tag}: GET /cart ∥`, "/shop/api/cart", { api: true }),
      req(`${tag}: GET /cart ∥`, "/shop/api/cart", { api: true }),
      req(`${tag}: GET /config ∥`, "/shop/api/config", { api: true }),
      req(`${tag}: GET /tenants ∥`, "/shop/api/tenants", { api: true })
    ])
  } else {
    await req(`${tag}: GET /cart #1`, "/shop/api/cart", { api: true })
    await req(`${tag}: GET /cart #2`, "/shop/api/cart", { api: true })
    await req(`${tag}: GET /config`, "/shop/api/config", { api: true })
  }
}
await page("новый гость")
await page("перезагрузка 1")
await page("перезагрузка 2")
// Не-API запросы витрины, которые браузер шлёт при загрузке (контроллер Shop::PwaController, вне Патча 1).
await req("GET /shop/manifest.webmanifest", "/shop/manifest.webmanifest")
await req("GET /shop/service-worker.js", "/shop/service-worker.js")
await req("после PWA: GET /cart", "/shop/api/cart", { api: true })
console.log(JSON.stringify(log, null, 2))
