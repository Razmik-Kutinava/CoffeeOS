/** B1.14: адрес точки в шапке, дропдаун, localStorage офлайн. */

import { readShopLocalStorage, writeShopLocalStorage } from "./shopLocalStorage.js"
import { applyOperatingHours } from "./shopOperatingHours.js"

export const TENANT_ADDRESS_STUB = "Адрес не указан"
const CACHE_PREFIX = "shop_tenant_address:"
const SELECTED_KEY = "shop_selected_tenant"

const DEFAULT_STATE = {
  tenantId: null,
  displayAddress: TENANT_ADDRESS_STUB,
  switchable: false,
  tenants: [],
  dropdownOpen: false,
  loaded: false,
  fromCache: false
}

let state = { ...DEFAULT_STATE }
const listeners = new Set()

function notify() {
  listeners.forEach((fn) => fn(state))
}

function setState(patch) {
  state = { ...state, ...patch }
  notify()
}

export function getTenantHeaderState() {
  return state
}

export function subscribeTenantHeader(fn) {
  listeners.add(fn)
  fn(state)
  return () => listeners.delete(fn)
}

export function formatTenantDisplayAddress(city, address) {
  const parts = [city, address].map((p) => String(p ?? "").trim()).filter(Boolean)
  if (!parts.length) return TENANT_ADDRESS_STUB
  return parts.join(", ")
}

export function resolvedShopTenantId() {
  const q = new URLSearchParams(window.location.search).get("tenant_id")
  if (q && String(q).trim()) return String(q).trim()
  return document.querySelector('meta[name="shop-tenant-id"]')?.getAttribute("content") || ""
}

export function readSelectedTenantId() {
  return readShopLocalStorage(SELECTED_KEY)?.tenantId || null
}

export function saveSelectedTenantId(tenantId) {
  writeShopLocalStorage(SELECTED_KEY, { tenantId: String(tenantId) })
}

function cacheKey(tenantId) {
  return `${CACHE_PREFIX}${tenantId}`
}

function readCachedTenant(tenantId) {
  if (!tenantId) return null
  return readShopLocalStorage(cacheKey(tenantId))
}

function writeCachedTenant(tenant) {
  if (!tenant?.id) return
  writeShopLocalStorage(cacheKey(tenant.id), {
    id: tenant.id,
    name: tenant.name,
    city: tenant.city,
    address: tenant.address,
    display_address:
      tenant.display_address || formatTenantDisplayAddress(tenant.city, tenant.address)
  })
}

function applyOfflineFallback() {
  const currentId = resolvedShopTenantId()
  const cached = currentId ? readCachedTenant(currentId) : null
  if (cached) {
    setState({
      tenantId: cached.id,
      displayAddress: cached.display_address,
      switchable: false,
      tenants: [{ ...cached, is_current: true }],
      loaded: true,
      fromCache: true,
      dropdownOpen: false
    })
    return
  }
  setState({
    displayAddress: TENANT_ADDRESS_STUB,
    loaded: true,
    fromCache: true,
    switchable: false,
    tenants: [],
    dropdownOpen: false
  })
}

export function navigateToTenant(tenantId, { remember = true } = {}) {
  if (!tenantId) return
  if (remember) saveSelectedTenantId(tenantId)
  const url = new URL(window.location.href)
  url.searchParams.set("tenant_id", tenantId)
  const hash = window.location.hash || "#/"
  window.location.assign(`${url.pathname}${url.search}${hash}`)
}

/** Старт витрины: редирект на выбранную / последнюю точку, затем state шапки. */
export async function bootstrapShopTenant(api) {
  const currentId = resolvedShopTenantId()
  let cfg = null

  try {
    cfg = await api("/config")
  } catch {
    applyOfflineFallback()
    return null
  }

  if (cfg?.operating_hours) applyOperatingHours(cfg.operating_hours)

  const tenant = cfg.tenant || {}
  writeCachedTenant(tenant)

  const preferred = readSelectedTenantId() || cfg.last_ordered_tenant_id
  if (preferred && String(preferred) !== String(currentId)) {
    navigateToTenant(preferred, { remember: false })
    return cfg
  }

  await refreshTenantHeader(api, cfg)
  return cfg
}

export async function refreshTenantHeader(api, cfg = null) {
  try {
    if (!cfg) cfg = await api("/config")
    const tenant = cfg.tenant || {}
    writeCachedTenant(tenant)

    let tenantsPayload = { switchable: false, tenants: [] }
    try {
      tenantsPayload = await api("/tenants")
    } catch {
      tenantsPayload = {
        switchable: false,
        tenants: [
          {
            ...tenant,
            display_address:
              tenant.display_address || formatTenantDisplayAddress(tenant.city, tenant.address),
            is_current: true
          }
        ]
      }
    }

    setState({
      tenantId: tenant.id,
      displayAddress:
        tenant.display_address || formatTenantDisplayAddress(tenant.city, tenant.address),
      switchable: tenantsPayload.switchable === true,
      tenants: tenantsPayload.tenants || [],
      loaded: true,
      fromCache: false,
      dropdownOpen: false
    })
  } catch {
    applyOfflineFallback()
  }
}

export function toggleTenantDropdown() {
  if (!state.switchable) return
  setState({ dropdownOpen: !state.dropdownOpen })
}

export function closeTenantDropdown() {
  if (state.dropdownOpen) setState({ dropdownOpen: false })
}

export function selectTenant(tenantId) {
  closeTenantDropdown()
  if (!tenantId || String(tenantId) === String(state.tenantId)) return
  navigateToTenant(tenantId)
}
