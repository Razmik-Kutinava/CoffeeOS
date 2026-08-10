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
    setItem: (k, v) => map.set(k, String(v)),
    removeItem: (k) => map.delete(k)
  }
}

globalThis.localStorage = mockStorage()
globalThis.document = {
  querySelector: (sel) => {
    if (sel === 'meta[name="csrf-token"]') return { getAttribute: () => "test-csrf" }
    if (sel === 'meta[name="shop-api-key"]') return { getAttribute: () => "test-key" }
    if (sel === 'meta[name="shop-tenant-id"]') return { getAttribute: () => "tenant-test" }
    return { getAttribute: () => "tenant-test" }
  }
}
globalThis.window = { location: { search: "" } }

const lsUrl = pathToFileURL(path.join(root, "app/frontend/lib/shopLocalStorage.js")).href
const { saveShopRefreshToken, loadShopRefreshToken } = await import(`${lsUrl}?t=${Date.now()}`)

let fetchImpl = async () => ({ ok: true, status: 200, json: async () => ({}) })
globalThis.fetch = async (url, opts) => fetchImpl(url, opts)

const refreshModUrl = pathToFileURL(path.join(root, "app/frontend/lib/silentRefreshSession.js")).href
let mod
try {
  mod = await import(`${refreshModUrl}?t=${Date.now()}`)
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

// Race: 401 со старым токеном не должен стереть уже ротированный новый.
saveShopRefreshToken("token-stale")
let release
const gate = new Promise((r) => {
  release = r
})
fetchImpl = async (_url, opts) => {
  const body = JSON.parse(opts.body)
  if (body.refresh_token === "token-stale") {
    await gate
    return { ok: false, status: 401, json: async () => ({ error: "Unauthorized" }) }
  }
  return {
    ok: true,
    status: 200,
    json: async () => ({
      refresh_token: "token-fresh",
      profile: { email: "a@test.com" }
    })
  }
}
const stalePromise = silentRefreshSession()
saveShopRefreshToken("token-fresh")
release()
const stale = await stalePromise
assert.equal(stale.verified, false)
assert.equal(loadShopRefreshToken(), "token-fresh")

// Parallel callers share one inflight promise.
saveShopRefreshToken("token-shared")
let calls = 0
fetchImpl = async () => {
  calls += 1
  await new Promise((r) => setTimeout(r, 20))
  return {
    ok: true,
    status: 200,
    json: async () => ({
      refresh_token: "token-shared-new",
      profile: { email: "a@test.com" }
    })
  }
}
const [a, b] = await Promise.all([silentRefreshSession(), silentRefreshSession()])
assert.equal(a.verified, true)
assert.equal(b.verified, true)
assert.equal(calls, 1)
assert.equal(loadShopRefreshToken(), "token-shared-new")

console.log("silent_refresh_session_test: PASS")
