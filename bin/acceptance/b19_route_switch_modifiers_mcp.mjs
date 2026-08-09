#!/usr/bin/env node
/**
 * B1.9 хвост #2 — сброс модификаторов при p1 → p2 (SPA hash switch).
 *
 *   node bin/acceptance/b19_route_switch_modifiers_mcp.mjs
 */
import { mkdirSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..")
const BASE = process.env.BASE || "https://coffeeos.fly.dev"
const TENANT = process.env.TENANT || "655aaccb-004a-4bb9-a50a-ce618854dda3"
const SHOP_URL = `${BASE}/shop?tenant_id=${TENANT}`
const P1 = process.env.P1 || ""
const P2 = process.env.P2 || ""

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const shotDir = join(artifactDir, "screenshots")
const artifactPath = join(artifactDir, "b19_route_switch_modifiers_2026-06-16.json")

mkdirSync(shotDir, { recursive: true })

const steps = []
const startedAt = new Date().toISOString()

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
}

async function fetchProducts(page) {
  return page.evaluate(async (tenantId) => {
    const key = document.querySelector('meta[name="shop-api-key"]')?.content
    const res = await fetch(`/shop/api/categories?tenant_id=${tenantId}`, {
      headers: { Accept: "application/json", "X-Shop-Api-Key": key },
      credentials: "same-origin"
    })
    const data = await res.json()
    const cats = Array.isArray(data) ? data : data.categories || data.data || []
    return cats.flatMap((c) => c.products || [])
  }, TENANT)
}

async function fetchProductDetail(page, productId) {
  return page.evaluate(async ({ productId, tenantId }) => {
    const key = document.querySelector('meta[name="shop-api-key"]')?.content
    const res = await fetch(`/shop/api/products/${productId}?tenant_id=${tenantId}`, {
      headers: { Accept: "application/json", "X-Shop-Api-Key": key },
      credentials: "same-origin"
    })
    if (!res.ok) return null
    const j = await res.json()
    return { name: j.name, basePrice: Math.round(j.price) }
  }, { productId, tenantId: TENANT })
}

async function run() {
  const browser = await chromium.launch({ headless: true })
  let overall = true

  try {
    const page = await browser.newPage()
    await page.goto(SHOP_URL, { waitUntil: "domcontentloaded", timeout: 90000 })
    await page.waitForTimeout(1500)

    const catalog = await fetchProducts(page)
    const fallbackP1 = "24dae391-2199-4959-907e-d08c4cec3329"
    const fallbackP2 = "3c5259e0-f42f-4d47-953d-2ce82b335f8c"
    const brazil =
      catalog.find((p) => /бразил/i.test(p.name)) ||
      catalog.find((p) => p.id === fallbackP1)
    const other = catalog.find((p) => p.id !== brazil?.id)
    const p1Id = P1 || brazil?.id || fallbackP1
    const p2Id = P2 || other?.id || fallbackP2

    const p2Detail = await fetchProductDetail(page, p2Id)
    if (!p2Detail?.name) throw new Error(`product detail missing for ${p2Id}`)

    await page.goto(`${SHOP_URL}#/product/${p1Id}`, { waitUntil: "domcontentloaded", timeout: 90000 })
    await page.waitForSelector(".mod-chip", { timeout: 90000 })

    const p1Base = await page.locator(".price-display").innerText().then((t) => parseInt(t, 10))
    const chip = page.locator(".mod-chip").filter({ hasText: /\+\d+₽/ }).first()
    if ((await chip.count()) === 0) await page.locator(".mod-chip").first().click()
    else await chip.click()
    await page.waitForTimeout(400)

    const p1WithMod = await page.locator(".price-display").innerText().then((t) => parseInt(t, 10))
    overall =
      step("01", "p1: modifier selected changes price", p1WithMod > p1Base, {
        p1Base,
        p1WithMod
      }) && overall

    await page.evaluate((id) => {
      window.location.hash = `#/product/${id}`
    }, p2Id)
    await page.waitForSelector(".price-display", { timeout: 60000 })
    await page.waitForTimeout(300)

    const title = (await page.locator("h1").first().innerText()).trim()
    const selectedCount = await page.locator(".mod-chip--selected").count()
    const p2Price = await page.locator(".price-display").innerText().then((t) => parseInt(t, 10))

    overall =
      step("02", "hash switch shows product 2 title", title === p2Detail.name, {
        title,
        expected: p2Detail.name
      }) && overall

    overall =
      step("03", "p2: no selected modifiers after switch", selectedCount === 0, {
        selectedCount
      }) && overall

    overall =
      step("04", "p2: price equals base (no stale modifiers)", p2Price === p2Detail.basePrice, {
        p2Price,
        p2DetailBase: p2Detail.basePrice
      }) && overall

    await page.screenshot({
      path: join(shotDir, "b19_route_switch_modifiers_2026-06-16.png"),
      fullPage: false
    })

    const artifact = {
      scenario: "b19_route_switch_modifiers",
      stand: BASE,
      tenant_id: TENANT,
      p1_id: p1Id,
      p2_id: p2Id,
      started_at: startedAt,
      finished_at: new Date().toISOString(),
      pass: overall,
      steps,
      screenshot: "b19_route_switch_modifiers_2026-06-16.png"
    }
    writeFileSync(artifactPath, JSON.stringify(artifact, null, 2))
    console.log(`\nArtifact: ${artifactPath}`)
    process.exit(overall ? 0 : 1)
  } finally {
    await browser.close()
  }
}

run().catch((e) => {
  console.error(e)
  process.exit(1)
})
