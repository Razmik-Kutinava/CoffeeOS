import { CART_STORE, openOfflineDb } from "./shopOfflineQueue.js"

function txCart(db, mode, fn) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(CART_STORE, mode)
    fn(tx.objectStore(CART_STORE))
    tx.oncomplete = () => resolve()
    tx.onerror = () => reject(tx.error)
  })
}

function getAllCart(db) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(CART_STORE, "readonly")
    const req = tx.objectStore(CART_STORE).getAll()
    req.onsuccess = () => resolve(req.result || [])
    req.onerror = () => reject(req.error)
  })
}

export async function pendingCartAddCount() {
  if (!("indexedDB" in window)) return 0
  const db = await openOfflineDb()
  const rows = await getAllCart(db)
  return rows.filter((r) => r.status === "pending").length
}

export async function enqueueCartAdd(payload) {
  const entry = {
    id: crypto.randomUUID(),
    created_at: Date.now(),
    status: "pending",
    payload
  }
  const db = await openOfflineDb()
  await txCart(db, "readwrite", (store) => store.put(entry))
  return entry
}

export async function flushCartQueue(apiFn) {
  if (!navigator.onLine || !("indexedDB" in window)) return { sent: 0, failed: 0 }

  const db = await openOfflineDb()
  const rows = (await getAllCart(db))
    .filter((r) => r.status === "pending")
    .sort((a, b) => a.created_at - b.created_at)
  let sent = 0
  let failed = 0

  for (const row of rows) {
    try {
      await apiFn("/cart/add", {
        method: "POST",
        body: JSON.stringify(row.payload)
      })
      row.status = "sent"
      await txCart(db, "readwrite", (store) => store.put(row))
      sent += 1
    } catch {
      failed += 1
      break
    }
  }

  if (sent > 0) {
    window.dispatchEvent(new CustomEvent("shop:offline-cart-sent", { detail: { sent } }))
  }

  return { sent, failed }
}
