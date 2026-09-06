import {
  readShopLocalStorage,
  removeShopLocalStorage,
  writeShopLocalStorage
} from "./shopLocalStorage.js"

function tenantIdForStorage() {
  if (typeof window === "undefined") return "default"
  const q = new URLSearchParams(window.location.search).get("tenant_id")
  return (
    (q && String(q).trim()) ||
    (typeof document !== "undefined" &&
      document.querySelector('meta[name="shop-tenant-id"]')?.getAttribute("content")) ||
    "default"
  )
}

function profileStorageKey() {
  return `shop_guest_profile:${tenantIdForStorage()}`
}

function receiptEmailStorageKey() {
  return `shop_receipt_email:${tenantIdForStorage()}`
}

export function maskEmail(email) {
  const value = email?.trim()
  if (!value || !value.includes("@")) return value || ""
  const [local, domain] = value.split("@")
  if (!local || !domain) return value
  return `${local.slice(0, 1)}***@${domain}`
}

export function isValidEmail(email) {
  return /^[^\s@]+@[^@\s]+\.[^\s@]+$/.test(email?.trim() || "")
}

export function loadGuestProfile() {
  const data = readShopLocalStorage(profileStorageKey())
  if (!data?.name?.trim() || !data?.email?.trim()) return null
  return {
    name: data.name.trim(),
    email: data.email.trim().toLowerCase(),
    emailVerified: !!data.emailVerified
  }
}

export function saveGuestProfile({ name, email, emailVerified }) {
  const n = name?.trim()
  const e = email?.trim().toLowerCase()
  if (!n || !e) return
  writeShopLocalStorage(profileStorageKey(), {
    name: n,
    email: e,
    emailVerified: !!emailVerified
  })
}

export function clearGuestProfile() {
  removeShopLocalStorage(profileStorageKey())
}

/** Сбросить только флаг OTP — имя/email оставить (session на сервере могла слететь). */
export function clearEmailVerifiedInProfile() {
  const profile = loadGuestProfile()
  if (!profile) return
  saveGuestProfile({ ...profile, emailVerified: false })
}

/** Email для чека после оплаты — без name (Callcheck-only). */
export function loadReceiptEmail() {
  const data = readShopLocalStorage(receiptEmailStorageKey())
  const raw =
    typeof data === "string"
      ? data
      : data && typeof data === "object"
        ? data.email
        : ""
  const email = String(raw || "").trim().toLowerCase()
  if (!email || !isValidEmail(email)) return ""
  return email
}

export function saveReceiptEmail(email) {
  const e = String(email || "").trim().toLowerCase()
  if (!e || !isValidEmail(e)) return
  writeShopLocalStorage(receiptEmailStorageKey(), { email: e })
}
