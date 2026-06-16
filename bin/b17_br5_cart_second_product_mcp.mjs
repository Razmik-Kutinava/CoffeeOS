#!/usr/bin/env node
/**
 * BR-5: второй разный товар в корзину (SPA product/:id → product/:id + UI add).
 *
 *   ruby tmp/b17_br5_cart_two_products.rb   # product ids с Fly
 *   node bin/b17_br5_cart_second_product_mcp.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")

const BASE = process.env.BASE || "https://coffeeos.fly.dev"
const TENANT = process.env.TENANT || "655aaccb-004a-4bb9-a50a-ce618854dda3"
const SHOP_URL = `${BASE}/shop?tenant_id=${TENANT}`

const artifactDir = join(
  root,
  "docs/operations/milestones/veha_2/artifacts/demo-feedback"
)
const artifactPath = join(artifactDir, "b17_cart_second_product_2026-06-14.json")

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
      headers: {
        Accept: "application/json",
        "X-Shop-Api-Key": key
      },
      credentials: "same-origin"
    })
    const data = await res.json()
    const cats = Array.isArray(data) ? data : data.categories || data.data || []
    return cats.flatMap((c) => c.products || [])
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
  mkdirSync(artifactDir, { recursive: true })
  const browser = await chromium.launch({ headless: true })
  let overall = true
  let products = []
  let p1 = null
  let p2 = null

  try {
    const ctx = await browser.newContext()
    const page = await ctx.newPage()
    await page.goto(SHOP_URL, { waitUntil: "domcontentloaded", timeout: 60000 })
    await page.waitForTimeout(1500)

    products = await fetchProducts(page)
    p1 = products[0]
    p2 = products[1]
    if (!p1 || !p2) {
      overall = step("00", "catalog has 2+ products", false, { count: products.length })
      throw new Error("need 2 products")
    }
    overall = step("00", "catalog has 2+ products", true, {
      p1: { id: p1.id, name: p1.name },
      p2: { id: p2.id, name: p2.name }
    }) && overall

    await clearCart(page)

    // Товар 1 — через UI карточки товара
    await page.goto(`${SHOP_URL}#/product/${p1.id}`, { waitUntil: "domcontentloaded" })
    await page.getByRole("button", { name: /В корзину/ }).waitFor({ timeout: 30000 })
    await page.getByRole("button", { name: /В корзину/ }).click()
    await page.waitForURL(/#\/cart/, { timeout: 30000 })
    overall =
      step("01", "product 1 add → redirect #/cart", /#\/cart/.test(page.url())) && overall

    const cartAfter1 = await page.evaluate(async (tenantId) => {
      const key = document.querySelector('meta[name="shop-api-key"]')?.content
      const res = await fetch(`/shop/api/cart?tenant_id=${tenantId}`, {
        headers: { Accept: "application/json", "X-Shop-Api-Key": key },
        credentials: "same-origin"
      })
      return res.json()
    }, TENANT)
    overall =
      step("02", "cart API has 1 line after first add", cartAfter1.items?.length === 1, {
        count: cartAfter1.items?.length
      }) && overall

    // BR-5: product/1 → product/2 без размонтирования (тот же route pattern)
    await page.goto(`${SHOP_URL}#/product/${p1.id}`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(500)
    await page.evaluate((id) => {
      window.location.hash = `#/product/${id}`
    }, p2.id)
    await page.waitForTimeout(1500)

    const headerTitle = await page.locator(".header-title").innerText().catch(() => "")
    const showsP2 = headerTitle.trim() === p2.name
    overall =
      step("03", "product page shows product 2 after hash switch", showsP2, {
        headerTitle,
        expected: p2.name
      }) && overall

    await page.getByRole("button", { name: /В корзину/ }).click()
    await page.waitForURL(/#\/cart/, { timeout: 30000 })
    await page.waitForTimeout(800)

    const bodyText = await page.locator("body").innerText()
    const hasBanner = bodyText.includes("добавлен в корзину")
    const hasP1 = bodyText.includes(p1.name.slice(0, 10))
    const hasP2 = bodyText.includes(p2.name.slice(0, 10))

    const cartFinal = await page.evaluate(async (tenantId) => {
      const key = document.querySelector('meta[name="shop-api-key"]')?.content
      const res = await fetch(`/shop/api/cart?tenant_id=${tenantId}`, {
        headers: { Accept: "application/json", "X-Shop-Api-Key": key },
        credentials: "same-origin"
      })
      return res.json()
    }, TENANT)

    const ids = new Set((cartFinal.items || []).map((i) => i.product_id))
    const twoDistinct =
      cartFinal.items?.length === 2 && ids.has(p1.id) && ids.has(p2.id)

    await page.screenshot({
      path: join(artifactDir, "screenshots", "b17_cart_second_product_2026-06-14.png"),
      fullPage: true
    }).catch(() => {})

    overall =
      step("04", "second add → redirect #/cart", /#\/cart/.test(page.url())) && overall
    overall =
      step("05", "just-added banner visible", hasBanner, { hasBanner }) && overall
    overall =
      step("06", "cart has both distinct products", twoDistinct, {
        items: cartFinal.items?.map((i) => ({
          product_id: i.product_id,
          name: i.product_name,
          qty: i.quantity
        }))
      }) && overall
    overall =
      step("07", "cart UI shows both product names", hasP1 && hasP2, { hasP1, hasP2 }) && overall
  } finally {
    await browser.close()
  }

  const artifact = {
    scenario: "b17_br5_second_product_cart",
    stand: BASE,
    tenant_id: TENANT,
    started_at: startedAt,
    finished_at: new Date().toISOString(),
    pass: overall,
    steps,
    products: p1 && p2 ? { p1, p2 } : null
  }
  writeFileSync(artifactPath, JSON.stringify(artifact, null, 2))
  console.log(`\nArtifact: ${artifactPath}`)
  process.exit(overall ? 0 : 1)
}

run().catch((e) => {
  console.error(e)
  process.exit(1)
})
