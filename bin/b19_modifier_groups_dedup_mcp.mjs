#!/usr/bin/env node
/**
 * B1.9 хвост #1 — нет дублей имён групп на карточке (API + DOM).
 *
 *   node bin/b19_modifier_groups_dedup_mcp.mjs
 */
import { mkdirSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const BASE = process.env.BASE || "https://coffeeos.fly.dev"
const TENANT = process.env.TENANT || "655aaccb-004a-4bb9-a50a-ce618854dda3"
const SHOP_URL = `${BASE}/shop?tenant_id=${TENANT}`
const PRODUCT_ID = process.env.PRODUCT_ID || "24dae391-2199-4959-907e-d08c4cec3329"

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const shotDir = join(artifactDir, "screenshots")
const artifactPath = join(artifactDir, "b19_modifier_groups_dedup_2026-06-16.json")

mkdirSync(shotDir, { recursive: true })

const steps = []
const startedAt = new Date().toISOString()

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
}

function uniqueDupes(names) {
  const seen = new Set()
  const dupes = []
  for (const n of names) {
    const k = n.trim().toLowerCase()
    if (seen.has(k)) dupes.push(n)
    seen.add(k)
  }
  return dupes
}

async function run() {
  const browser = await chromium.launch({ headless: true })
  let overall = true

  try {
    const page = await browser.newPage()
    await page.goto(SHOP_URL, { waitUntil: "domcontentloaded", timeout: 90000 })
    await page.waitForTimeout(1500)

    const api = await page.evaluate(async (productId) => {
      const tenantId = new URLSearchParams(location.search).get("tenant_id")
      const key = document.querySelector('meta[name="shop-api-key"]')?.content
      const res = await fetch(`/shop/api/products/${productId}?tenant_id=${tenantId}`, {
        headers: { Accept: "application/json", "X-Shop-Api-Key": key },
        credentials: "same-origin"
      })
      const j = await res.json()
      const names = (j.modifier_groups || []).map((g) => g.name)
      return { names, groups: j.modifier_groups }
    }, PRODUCT_ID)

    const apiDupes = uniqueDupes(api.names)
    overall =
      step("01", "API: unique modifier group names", apiDupes.length === 0, {
        names: api.names,
        dupes: apiDupes
      }) && overall

    await page.goto(`${SHOP_URL}#/product/${PRODUCT_ID}`, { waitUntil: "domcontentloaded" })
    await page.waitForSelector(".mod-group", { timeout: 90000 })
    const domNames = await page.locator(".mod-group > p").allTextContents()
    const domDupes = uniqueDupes(domNames)

    overall =
      step("02", "DOM: one heading per group name", domDupes.length === 0, {
        domNames,
        domDupes
      }) && overall

    const tempCount = domNames.filter((n) => n.trim() === "Температура").length
    const tasteCount = domNames.filter((n) => n.trim() === "Вкус").length
    overall =
      step("03", "Brazil: single Температура and Вкус", tempCount === 1 && tasteCount === 1, {
        tempCount,
        tasteCount
      }) && overall

    await page.screenshot({
      path: join(shotDir, "b19_modifier_groups_dedup_2026-06-16.png"),
      fullPage: true
    })

    const artifact = {
      scenario: "b19_modifier_groups_dedup",
      stand: BASE,
      tenant_id: TENANT,
      product_id: PRODUCT_ID,
      started_at: startedAt,
      finished_at: new Date().toISOString(),
      pass: overall,
      steps,
      api_group_names: api.names,
      dom_group_names: domNames,
      screenshot: "b19_modifier_groups_dedup_2026-06-16.png"
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
