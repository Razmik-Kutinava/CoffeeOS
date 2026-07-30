function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") || ""
}

/** Сначала ?tenant_id= в URL (совпадает с выбранной точкой в менеджере), иначе meta с сервера. */
function resolvedShopTenantId() {
  const q = new URLSearchParams(window.location.search).get("tenant_id")
  if (q && String(q).trim()) return String(q).trim()
  return document.querySelector('meta[name="shop-tenant-id"]')?.getAttribute("content") || ""
}

function withTenantQuery(url) {
  const tid = resolvedShopTenantId()
  if (!tid || url.includes("tenant_id=")) return url
  const sep = url.includes("?") ? "&" : "?"
  return `${url}${sep}tenant_id=${encodeURIComponent(tid)}`
}

const API_PREFIX = "/shop/api"

function shopApiKey() {
  const meta = document.querySelector('meta[name="shop-api-key"]')?.getAttribute("content")
  if (meta && meta.trim()) return meta.trim()
  const env = import.meta.env.VITE_SHOP_API_KEY
  return env && String(env).trim() ? String(env).trim() : ""
}

export async function api(path, opts = {}) {
  let url = path.startsWith("/") ? `${API_PREFIX}${path}` : `${API_PREFIX}/${path}`
  url = withTenantQuery(url)
  const headers = {
    Accept: "application/json",
    "X-CSRF-Token": csrfToken(),
    ...opts.headers
  }
  const apiKey = shopApiKey()
  if (apiKey && !headers["X-Shop-Api-Key"]) {
    headers["X-Shop-Api-Key"] = apiKey
  }
  if (opts.body && !headers["Content-Type"]) {
    headers["Content-Type"] = "application/json"
  }
  const res = await fetch(url, {
    credentials: "same-origin",
    ...opts,
    headers,
    cache: opts.cache ?? "no-store"
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) {
    const fallback =
      res.status === 500 ? "Ошибка сервера. Попробуйте позже." : res.statusText
    const msg = data.error || data.message || fallback
    const err = new Error(typeof msg === "string" ? msg : JSON.stringify(msg))
    err.httpStatus = res.status
    if (data.error_code) err.error_code = data.error_code
    if (data.tbank_status) err.tbank_status = data.tbank_status
    err.body = data
    throw err
  }
  return data
}
