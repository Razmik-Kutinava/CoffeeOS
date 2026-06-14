import assert from "node:assert/strict"
import {
  readShopLocalStorage,
  removeShopLocalStorage,
  SHOP_LS_TTL_MS,
  writeShopLocalStorage
} from "../../app/frontend/lib/shopLocalStorage.js"

const KEY = "test_shop_ls"

function mockStorage() {
  const map = new Map()
  return {
    getItem: (k) => map.get(k) ?? null,
    setItem: (k, v) => map.set(k, v),
    removeItem: (k) => map.delete(k)
  }
}

const storage = mockStorage()
globalThis.localStorage = storage

storage.removeItem(KEY)

writeShopLocalStorage(KEY, { name: "A", email: "a@test.com" })
assert.deepEqual(readShopLocalStorage(KEY), { name: "A", email: "a@test.com" })

storage.setItem(
  KEY,
  JSON.stringify({
    savedAt: new Date(Date.now() - SHOP_LS_TTL_MS - 1000).toISOString(),
    ttlMs: SHOP_LS_TTL_MS,
    payload: { stale: true }
  })
)
assert.equal(readShopLocalStorage(KEY), null)
assert.equal(storage.getItem(KEY), null)

storage.setItem(KEY, JSON.stringify({ name: "legacy" }))
assert.equal(readShopLocalStorage(KEY), null)

removeShopLocalStorage(KEY)
writeShopLocalStorage(KEY, { ok: 1 })
removeShopLocalStorage(KEY)
assert.equal(readShopLocalStorage(KEY), null)

console.log("shop_local_storage_test: PASS")
