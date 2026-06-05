function profileStorageKey() {
  const q = new URLSearchParams(window.location.search).get("tenant_id")
  const tid =
    (q && String(q).trim()) ||
    document.querySelector('meta[name="shop-tenant-id"]')?.getAttribute("content") ||
    "default"
  return `shop_guest_profile:${tid}`
}

export function loadGuestProfile() {
  try {
    const raw = localStorage.getItem(profileStorageKey())
    if (!raw) return null
    const data = JSON.parse(raw)
    if (!data?.name?.trim() || !data?.phone?.trim()) return null
    return { name: data.name.trim(), phone: data.phone.trim() }
  } catch (_) {
    return null
  }
}

export function saveGuestProfile({ name, phone }) {
  const n = name?.trim()
  const p = phone?.trim()
  if (!n || !p) return
  try {
    localStorage.setItem(profileStorageKey(), JSON.stringify({ name: n, phone: p }))
  } catch (_) {
    /* ignore */
  }
}

export function clearGuestProfile() {
  try {
    localStorage.removeItem(profileStorageKey())
  } catch (_) {
    /* ignore */
  }
}
