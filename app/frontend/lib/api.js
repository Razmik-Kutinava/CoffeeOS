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

export async function api(path, opts = {}) {
  let url = path.startsWith("/") ? `${API_PREFIX}${path}` : `${API_PREFIX}/${path}`
  url = withTenantQuery(url)
  const headers = {
    Accept: "application/json",
    "X-CSRF-Token": csrfToken(),
    ...opts.headers
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
    const msg = data.error || data.message || res.statusText
    throw new Error(typeof msg === "string" ? msg : JSON.stringify(msg))
  }
  return data
}
