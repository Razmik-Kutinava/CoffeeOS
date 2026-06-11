const DB_NAME = "coffeeos_shop_offline"
const DB_VERSION = 1
const STORE = "order_queue"

function openDb() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VERSION)
    req.onerror = () => reject(req.error)
    req.onupgradeneeded = () => {
      const db = req.result
      if (!db.objectStoreNames.contains(STORE)) {
        db.createObjectStore(STORE, { keyPath: "id" })
      }
    }
    req.onsuccess = () => resolve(req.result)
  })
}

function txStore(db, mode, fn) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE, mode)
    const store = tx.objectStore(STORE)
    fn(store)
    tx.oncomplete = () => resolve()
    tx.onerror = () => reject(tx.error)
  })
}

function getAll(db) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE, "readonly")
    const req = tx.objectStore(STORE).getAll()
    req.onsuccess = () => resolve(req.result || [])
    req.onerror = () => reject(req.error)
  })
}

export async function pendingOrderCount() {
  if (!("indexedDB" in window)) return 0
  const db = await openDb()
  const rows = await getAll(db)
  return rows.filter((r) => r.status === "pending").length
}

export async function enqueueOrder(payload) {
  const client_order_uuid = payload.client_order_uuid || crypto.randomUUID()
  const entry = {
    id: crypto.randomUUID(),
    client_order_uuid,
    created_at: Date.now(),
    status: "pending",
    payload: { ...payload, client_order_uuid }
  }
  const db = await openDb()
  await txStore(db, "readwrite", (store) => store.put(entry))
  return entry
}

export async function flushOrderQueue(apiFn) {
  if (!navigator.onLine || !("indexedDB" in window)) return { sent: 0, failed: 0 }

  const db = await openDb()
  const rows = (await getAll(db)).filter((r) => r.status === "pending").sort((a, b) => a.created_at - b.created_at)
  let sent = 0
  let failed = 0

  for (const row of rows) {
    try {
      const res = await apiFn("/orders", {
        method: "POST",
        body: JSON.stringify(row.payload)
      })
      row.status = "sent"
      row.order_id = res.order_id
      await txStore(db, "readwrite", (store) => store.put(row))
      sent += 1
      window.dispatchEvent(
        new CustomEvent("shop:offline-order-sent", { detail: { order_id: res.order_id, entry: row } })
      )
    } catch {
      failed += 1
      break
    }
  }

  return { sent, failed }
}
