#!/usr/bin/env node
/**
 * BR-5 customer flow: Товар 1 в корзину → карточка Товара 2 на главной → «В корзину».
 */
import { writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..")
const BASE = process.env.BASE || "https://coffeeos.fly.dev"
const TENANT = process.env.TENANT || "655aaccb-004a-4bb9-a50a-ce618854dda3"
const SHOP_URL = `${BASE}/shop?tenant_id=${TENANT}`
const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const shotDir = join(artifactDir, "screenshots")

mkdirSync(shotDir, { recursive: true })

const steps = []
function step(id, action, pass, extra = {}) {
  steps.push({ id, action, pass, at: new Date().toISOString(), ...extra })
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
    const cats = data.data || data.categories || []
    return cats.flatMap((c) => c.products || [])
  }, TENANT)
}

async function clearCart(page) {
  await page.evaluate(async (tenantId) => {
    const key = document.querySelector('meta[name="shop-api-key"]')?.content
    await fetch(`/shop/api/cart?tenant_id=${tenantId}`, {
      method: "DELETE",
      headers: { Accept: "application/json", "X-Shop-Api-Key": key },
      credentials: "same-origin"
    })
  }, TENANT)
}

async function run() {
  const browser = await chromium.launch({ headless: true })
  let overall = true
  let p1, p2

  try {
    const page = await browser.newPage()
    await page.goto(SHOP_URL, { waitUntil: "domcontentloaded", timeout: 60000 })
    await page.waitForTimeout(1500)

    const products = await fetchProducts(page)
    p1 = products[0]
    p2 = products[1]
    if (!p1 || !p2) throw new Error("need 2 products")

    await clearCart(page)

    // Товар 1
    await page.goto(`${SHOP_URL}#/product/${p1.id}`, { waitUntil: "domcontentloaded" })
    await page.getByRole("button", { name: /В корзину/ }).click()
    await page.waitForURL(/#\/cart/, { timeout: 30000 })
    overall = step("01", "product 1 → cart", true) && overall

    await page.screenshot({
      path: join(shotDir, "b17_br5_regression_after_p1_2026-06-04.png"),
      fullPage: true
    })

    // Каталог (как пользователь: с корзины → «Каталог» → карточка Товара 2)
    await page.getByRole("button", { name: "Каталог" }).click()
    await page.waitForURL(/#\/$|#\/\?|shop\?[^#]*$/, { timeout: 15000 })
    await page.waitForTimeout(1200)

    const clicked = await page.evaluate((p2Name) => {
      const needle = p2Name.slice(0, 20)
      const btn = [...document.querySelectorAll("button")].find(
        (b) => b.textContent?.includes(needle) && !b.textContent?.includes("Каталог")
      )
      if (!btn) return false
      btn.click()
      return true
    }, p2.name)
    if (!clicked) throw new Error(`catalog card not found for ${p2.name}`)

    await page.waitForURL(new RegExp(`#/product/${p2.id}`), { timeout: 30000 })
    await page.waitForTimeout(800)

    const title = await page.locator("h1").first().innerText()
    overall =
      step("02", "catalog card opens product 2", title.trim() === p2.name, {
        title,
        expected: p2.name
      }) && overall

    await page.screenshot({
      path: join(shotDir, "b17_br5_regression_before_p2_add_2026-06-04.png"),
      fullPage: true
    })

    await page.getByRole("button", { name: /В корзину/ }).click()
    await page.waitForURL(/#\/cart/, { timeout: 30000 })

    const body = await page.locator("body").innerText()
    const hasBanner = body.includes("добавлен в корзину")
    const cartFinal = await page.evaluate(async (tenantId) => {
      const key = document.querySelector('meta[name="shop-api-key"]')?.content
      const res = await fetch(`/shop/api/cart?tenant_id=${tenantId}`, {
        headers: { Accept: "application/json", "X-Shop-Api-Key": key },
        credentials: "same-origin"
      })
      return res.json()
    }, TENANT)

    const ids = new Set((cartFinal.items || []).map((i) => i.product_id))
    const twoDistinct = cartFinal.items?.length === 2 && ids.has(p1.id) && ids.has(p2.id)

    await page.screenshot({
      path: join(shotDir, "b17_br5_regression_after_2026-06-04.png"),
      fullPage: true
    })

    overall = step("03", "product 2 add → cart redirect", /#\/cart/.test(page.url())) && overall
    overall = step("04", "banner visible", hasBanner, { hasBanner }) && overall
    overall =
      step("05", "cart has 2 distinct products", twoDistinct, {
        items: cartFinal.items?.map((i) => ({ id: i.product_id, name: i.product_name }))
      }) && overall
  } finally {
    await browser.close()
  }

  const artifact = {
    scenario: "b17_br5_catalog_card_flow",
    stand: BASE,
    tenant_id: TENANT,
    pass: overall,
    steps,
    products: p1 && p2 ? { p1: { id: p1.id, name: p1.name }, p2: { id: p2.id, name: p2.name } } : null
  }
  writeFileSync(
    join(artifactDir, "b17_br5_regression_repro_2026-06-04.json"),
    JSON.stringify(artifact, null, 2)
  )
  process.exit(overall ? 0 : 1)
}

run().catch((e) => {
  console.error(e)
  process.exit(1)
})
