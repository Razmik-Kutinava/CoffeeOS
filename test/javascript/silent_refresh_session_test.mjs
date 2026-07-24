import assert from "node:assert/strict"
import path from "node:path"
import { pathToFileURL } from "node:url"
import { fileURLToPath } from "node:url"

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(__dirname, "../..")

function mockStorage() {
  const map = new Map()
  return {
    getItem: (k) => map.get(k) ?? null,
    setItem: (k, v) => map.set(k, v),
    removeItem: (k) => map.delete(k)
  }
}

globalThis.localStorage = mockStorage()
globalThis.document = {
  querySelector: () => ({ getAttribute: () => "tenant-test" })
}
globalThis.window = { location: { search: "" } }

const lsUrl = pathToFileURL(path.join(root, "app/frontend/lib/shopLocalStorage.js")).href
const { saveShopRefreshToken, loadShopRefreshToken } = await import(lsUrl)

let fetchImpl = async () => ({ ok: true, status: 200, json: async () => ({}) })
globalThis.fetch = async (url, opts) => fetchImpl(url, opts)

const refreshModUrl = pathToFileURL(path.join(root, "app/frontend/lib/silentRefreshSession.js")).href
let mod
try {
  mod = await import(refreshModUrl)
} catch (e) {
  console.error("silent_refresh_session_test: FAIL missing silentRefreshSession.js", e.message)
  process.exit(1)
}

const { silentRefreshSession } = mod

saveShopRefreshToken("token-old")
fetchImpl = async () => ({
  ok: true,
  status: 200,
  json: async () => ({
    refresh_token: "token-new",
    profile: { id: "c1", name: "Aram", email: "a@test.com" }
  })
})
const ok = await silentRefreshSession()
assert.equal(ok.verified, true)
assert.equal(loadShopRefreshToken(), "token-new")

saveShopRefreshToken("token-bad")
fetchImpl = async () => ({
  ok: false,
  status: 401,
  json: async () => ({ error: "Unauthorized" })
})
const bad = await silentRefreshSession()
assert.equal(bad.verified, false)
assert.equal(loadShopRefreshToken(), null)

saveShopRefreshToken("token-net")
fetchImpl = async () => {
  throw new Error("network down")
}
const net = await silentRefreshSession()
assert.equal(net.verified, false)
assert.equal(loadShopRefreshToken(), null)

console.log("silent_refresh_session_test: PASS")
