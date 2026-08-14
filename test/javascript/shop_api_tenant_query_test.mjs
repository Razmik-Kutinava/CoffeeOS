/**
 * #65 linkage: tenant_id from In-App link → /shop/api (no silent meta/fallback swap).
 * node --test test/javascript/shop_api_tenant_query_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach, afterEach } from "node:test"
import {
  resolvedShopTenantId,
  withTenantQuery
} from "../../app/frontend/lib/api.js"

const POINT_A = "2fdee1ac-4674-41ee-b89e-87b45643f789"
const OTHER = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

describe("shop api tenant query (#65 linkage)", () => {
  const originalWindow = globalThis.window
  const originalDocument = globalThis.document
  const originalImportMeta = globalThis.import

  beforeEach(() => {
    globalThis.document = {
      querySelector: (sel) => {
        if (sel === 'meta[name="shop-tenant-id"]') {
          return { getAttribute: () => OTHER }
        }
        if (sel === 'meta[name="csrf-token"]') {
          return { getAttribute: () => "csrf" }
        }
        if (sel === 'meta[name="shop-api-key"]') {
          return { getAttribute: () => "" }
        }
        return null
      }
    }
  })

  afterEach(() => {
    globalThis.window = originalWindow
    globalThis.document = originalDocument
  })

  it("query tenant_id wins over different meta (no silent swap)", () => {
    globalThis.window = {
      location: { search: `?tenant_id=${POINT_A}` }
    }
    assert.equal(resolvedShopTenantId(), POINT_A)
    assert.match(withTenantQuery("/shop/api/categories"), new RegExp(`tenant_id=${POINT_A}`))
    assert.doesNotMatch(withTenantQuery("/shop/api/categories"), new RegExp(OTHER))
  })

  it("when tenant_id key is present but blank, does not fall back to meta", () => {
    globalThis.window = {
      location: { search: "?tenant_id=" }
    }
    assert.equal(resolvedShopTenantId(), "")
    assert.match(withTenantQuery("/shop/api/categories"), /tenant_id=$|tenant_id=(?:&|$)/)
    assert.doesNotMatch(withTenantQuery("/shop/api/categories"), new RegExp(OTHER))
  })

  it("without tenant_id key uses meta for same-origin catalog", () => {
    globalThis.window = {
      location: { search: "" }
    }
    assert.equal(resolvedShopTenantId(), OTHER)
    assert.match(withTenantQuery("/shop/api/categories"), new RegExp(`tenant_id=${OTHER}`))
  })

  it("does not invent Telegram/UA identity as tenant", () => {
    globalThis.window = {
      location: { search: `?tenant_id=${POINT_A}&tg_user_id=999` },
      navigator: { userAgent: "Telegram-Android" }
    }
    assert.equal(resolvedShopTenantId(), POINT_A)
    assert.doesNotMatch(withTenantQuery("/shop/api/categories"), /tg_user|999/)
  })
})
