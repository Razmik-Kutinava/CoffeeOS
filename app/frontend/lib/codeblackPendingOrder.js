/**
 * CODE:BLACK: pending order в localStorage до/после редиректа в банк (СБП).
 * Только { orderId, timestamp } — без RebillId / платёжных данных.
 */

export const CODEBLACK_PENDING_KEY = "codeblack_pending_order"
export const PENDING_TTL_MS = 15 * 60 * 1000

function defaultStorage() {
  if (typeof localStorage === "undefined") return null
  return localStorage
}

export function isPendingFresh(pending, now = Date.now()) {
  if (!pending?.orderId || pending.timestamp == null) return false
  const age = now - Number(pending.timestamp)
  return age >= 0 && age < PENDING_TTL_MS
}

/**
 * @param {string} orderId
 * @param {{ storage?: Storage, now?: number }} [opts]
 */
export function savePendingOrder(orderId, opts = {}) {
  const storage = opts.storage ?? defaultStorage()
  if (!storage) return
  const id = String(orderId || "").trim()
  if (!id) return
  const payload = {
    orderId: id,
    timestamp: opts.now ?? Date.now()
  }
  storage.setItem(CODEBLACK_PENDING_KEY, JSON.stringify(payload))
}

/**
 * @param {{ storage?: Storage, now?: number }} [opts]
 * @returns {{ orderId: string, timestamp: number } | null}
 */
export function loadPendingOrder(opts = {}) {
  const storage = opts.storage ?? defaultStorage()
  if (!storage) return null
  const raw = storage.getItem(CODEBLACK_PENDING_KEY)
  if (!raw) return null
  let parsed
  try {
    parsed = JSON.parse(raw)
  } catch {
    clearPendingOrder({ storage })
    return null
  }
  const now = opts.now ?? Date.now()
  if (!isPendingFresh(parsed, now)) {
    clearPendingOrder({ storage })
    return null
  }
  return { orderId: String(parsed.orderId), timestamp: Number(parsed.timestamp) }
}

/** @param {{ storage?: Storage }} [opts] */
export function clearPendingOrder(opts = {}) {
  const storage = opts.storage ?? defaultStorage()
  if (!storage) return
  storage.removeItem(CODEBLACK_PENDING_KEY)
}

/**
 * Сериализует overlapping visibility/cold-start проверки статуса.
 * @returns {{ run: (fn: () => Promise<any>) => Promise<any> }}
 */
export function createVisibilityStatusGuard() {
  let chain = Promise.resolve()
  return {
    run(fn) {
      const next = chain.then(() => fn())
      // не блокируем очередь ошибкой предыдущего
      chain = next.catch(() => {})
      return next
    }
  }
}
