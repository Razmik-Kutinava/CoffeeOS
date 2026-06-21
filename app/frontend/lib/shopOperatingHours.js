/** B1.11: статус режима работы точки с shop API. */

const DEFAULT_HOURS = {
  is_open: true,
  closed_until: null,
  closed_message: null,
  schedule_display: null,
  timezone: "Europe/Moscow",
  loaded: false
}

let hours = { ...DEFAULT_HOURS }
const listeners = new Set()

function notify() {
  listeners.forEach((fn) => fn(hours))
}

export function getOperatingHours() {
  return hours
}

export function subscribeOperatingHours(fn) {
  listeners.add(fn)
  fn(hours)
  return () => listeners.delete(fn)
}

export function applyOperatingHours(payload) {
  if (!payload || typeof payload !== "object") return hours
  hours = {
    ...DEFAULT_HOURS,
    ...payload,
    loaded: true
  }
  notify()
  return hours
}

export async function loadOperatingHours(api) {
  try {
    const cfg = await api("/config")
    return applyOperatingHours(cfg.operating_hours)
  } catch {
    return hours
  }
}

export function shopIsOpenForPay() {
  return hours.is_open !== false
}
