#!/usr/bin/env node
/**
 * B1.9 — toggle-модификаторы на карточке товара (Fly MCP).
 *
 *   node bin/b19_modifier_toggle_mcp.mjs
 */
import { mkdirSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium, devices } from "playwright"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const BASE = process.env.BASE || "https://coffeeos.fly.dev"
const TENANT = process.env.TENANT || "655aaccb-004a-4bb9-a50a-ce618854dda3"
const SHOP_URL = `${BASE}/shop?tenant_id=${TENANT}`

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const shotDir = join(artifactDir, "screenshots")
const artifactPath = join(artifactDir, "b19_modifier_toggle_post_deploy_2026-06-15.json")

mkdirSync(shotDir, { recursive: true })

const steps = []
const startedAt = new Date().toISOString()

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
}

async function fetchBrazilProduct(page) {
  return page.evaluate(async (tenantId) => {
    const key = document.querySelector('meta[name="shop-api-key"]')?.content
    const res = await fetch(`/shop/api/categories?tenant_id=${tenantId}`, {
      headers: { Accept: "application/json", "X-Shop-Api-Key": key },
      credentials: "same-origin"
    })
    const data = await res.json()
    const cats = Array.isArray(data) ? data : data.categories || data.data || []
    const products = cats.flatMap((c) => c.products || [])
    return products.find((p) => /бразил/i.test(p.name)) || products[0]
  }, TENANT)
}

async function clearCart(page) {
  return page.evaluate(async (tenantId) => {
    const key = document.querySelector('meta[name="shop-api-key"]')?.content
    await fetch(`/shop/api/cart?tenant_id=${tenantId}`, {
      method: "DELETE",
      headers: { Accept: "application/json", "X-Shop-Api-Key": key },
      credentials: "same-origin"
    })
  }, TENANT)
}

async function run() {
  const iphone = devices["iPhone 13"]
  const browser = await chromium.launch({ headless: true })
  let overall = true
  let product = null
  let basePrice = 0
  let priceWithMod = 0

  try {
    const context = await browser.newContext({ ...iphone, locale: "ru-RU" })
    const page = await context.newPage()
    await page.goto(SHOP_URL, { waitUntil: "domcontentloaded", timeout: 90000 })
    await page.waitForTimeout(1500)

    product = await fetchBrazilProduct(page)
    if (!product?.id) throw new Error("Brazil product not found")

    await clearCart(page)
    await page.goto(`${SHOP_URL}#/product/${product.id}`, { waitUntil: "domcontentloaded", timeout: 90000 })
    await page.waitForTimeout(2000)

    const bodyText = await page.locator("body").innerText()
    overall =
      step("01", "no «обязательно» on product card", !/обязательно/i.test(bodyText)) && overall

    basePrice = await page.locator(".price-display").innerText().then((t) => parseInt(t, 10))
    overall = step("02", "base price visible", Number.isFinite(basePrice), { basePrice }) && overall

    const paidChip = page.locator(".mod-chip").filter({ hasText: /\+\d+₽/ }).first()
    const paidLabel = (await paidChip.innerText().catch(() => "")).trim()
    const paidMatch = paidLabel.match(/\+(\d+)₽/)
    const paidDelta = paidMatch ? Number(paidMatch[1]) : 0

    await paidChip.click()
    await page.waitForTimeout(400)

    const plusVisible = (await page.locator(".mod-chip--selected .mod-chip-plus").count()) > 0
    overall = step("03", "toggle on: «+» indicator visible", plusVisible) && overall

    priceWithMod = await page.locator(".price-display").innerText().then((t) => parseInt(t, 10))
    const priceOk = paidDelta > 0 ? priceWithMod === basePrice + paidDelta : priceWithMod >= basePrice
    overall =
      step("04", "price recalculates after toggle", priceOk, {
        basePrice,
        priceWithMod,
        paidDelta,
        paidLabel
      }) && overall

    await paidChip.click()
    await page.waitForTimeout(400)
    const plusGone = (await page.locator(".mod-chip--selected .mod-chip-plus").count()) === 0
    const priceBack = await page.locator(".price-display").innerText().then((t) => parseInt(t, 10))
    overall =
      step("05", "toggle off: «+» removed, price back", plusGone && priceBack === basePrice, {
        priceBack
      }) && overall

    await page.locator(".add-to-cart-btn").click()
    await page.waitForURL(/#\/cart/, { timeout: 20000 })
    await page.waitForTimeout(1000)

    const cartText = await page.locator("body").innerText()
    overall =
      step("06", "add to cart without modifiers", /корзин/i.test(cartText) || cartText.includes("₽")) &&
      overall

    await page.screenshot({
      path: join(shotDir, "b19_modifier_toggle_after_2026-06-15.png"),
      fullPage: false
    })

    const artifact = {
      scenario: "b19_modifier_toggle_post_deploy",
      stand: BASE,
      tenant_id: TENANT,
      product_id: product.id,
      product_name: product.name,
      started_at: startedAt,
      finished_at: new Date().toISOString(),
      pass: overall,
      tools: ["playwright:b19_modifier_toggle_mcp.mjs"],
      steps,
      metrics: { basePrice, priceWithMod, paidDelta },
      screenshot: "b19_modifier_toggle_after_2026-06-15.png"
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
