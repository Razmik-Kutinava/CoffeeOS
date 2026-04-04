function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") || ""
}

function withTenantQuery(url) {
  const tid = document.querySelector('meta[name="shop-tenant-id"]')?.getAttribute("content")
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
    headers
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) {
    const msg = data.error || data.message || res.statusText
    throw new Error(typeof msg === "string" ? msg : JSON.stringify(msg))
  }
  return data
}
