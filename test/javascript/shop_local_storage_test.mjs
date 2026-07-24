import assert from "node:assert/strict"
import {
  clearShopRefreshToken,
  loadShopRefreshToken,
  readShopLocalStorage,
  removeShopLocalStorage,
  saveShopRefreshToken,
  SHOP_LS_TTL_MS,
  touchShopLocalStorage,
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

// Через 24ч+ данные НЕ сжигаются (скользящий TTL / без hard burn)
storage.setItem(
  KEY,
  JSON.stringify({
    savedAt: new Date(Date.now() - SHOP_LS_TTL_MS - 1000).toISOString(),
    ttlMs: SHOP_LS_TTL_MS,
    payload: { stale: false, keep: true }
  })
)
assert.deepEqual(readShopLocalStorage(KEY), { stale: false, keep: true })

storage.setItem(KEY, JSON.stringify({ name: "legacy" }))
assert.equal(readShopLocalStorage(KEY), null)

removeShopLocalStorage(KEY)
writeShopLocalStorage(KEY, { ok: 1 })
touchShopLocalStorage(KEY)
const raw = JSON.parse(storage.getItem(KEY))
assert.ok(raw.savedAt)
assert.deepEqual(raw.payload, { ok: 1 })
removeShopLocalStorage(KEY)
assert.equal(storage.getItem(KEY), null)

saveShopRefreshToken("abc123token")
assert.equal(loadShopRefreshToken(), "abc123token")
clearShopRefreshToken()
assert.equal(loadShopRefreshToken(), null)

console.log("shop_local_storage_test: PASS")
