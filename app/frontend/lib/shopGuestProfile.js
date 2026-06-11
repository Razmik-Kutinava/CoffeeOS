function profileStorageKey() {
  const q = new URLSearchParams(window.location.search).get("tenant_id")
  const tid =
    (q && String(q).trim()) ||
    document.querySelector('meta[name="shop-tenant-id"]')?.getAttribute("content") ||
    "default"
  return `shop_guest_profile:${tid}`
}

export function maskEmail(email) {
  const value = email?.trim()
  if (!value || !value.includes("@")) return value || ""
  const [local, domain] = value.split("@")
  if (!local || !domain) return value
  return `${local.slice(0, 1)}***@${domain}`
}

export function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email?.trim() || "")
}

export function loadGuestProfile() {
  try {
    const raw = localStorage.getItem(profileStorageKey())
    if (!raw) return null
    const data = JSON.parse(raw)
    if (!data?.name?.trim() || !data?.email?.trim()) return null
    return {
      name: data.name.trim(),
      email: data.email.trim().toLowerCase(),
      emailVerified: !!data.emailVerified
    }
  } catch (_) {
    return null
  }
}

export function saveGuestProfile({ name, email, emailVerified }) {
  const n = name?.trim()
  const e = email?.trim().toLowerCase()
  if (!n || !e) return
  try {
    localStorage.setItem(
      profileStorageKey(),
      JSON.stringify({ name: n, email: e, emailVerified: !!emailVerified })
    )
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

/** Сбросить только флаг OTP — имя/email оставить (session на сервере могла слететь). */
export function clearEmailVerifiedInProfile() {
  const profile = loadGuestProfile()
  if (!profile) return
  saveGuestProfile({ ...profile, emailVerified: false })
}
