#!/usr/bin/env node
/** BR-5: quick-add 🛒 on category grid after first product in cart */
import { chromium } from "playwright"

const BASE = process.env.BASE || "https://coffeeos.fly.dev"
const TENANT = process.env.TENANT || "655aaccb-004a-4bb9-a50a-ce618854dda3"
const SHOP_URL = `${BASE}/shop?tenant_id=${TENANT}`

async function run() {
  const browser = await chromium.launch({ headless: true })
  const page = await browser.newPage()
  await page.goto(SHOP_URL, { waitUntil: "domcontentloaded" })
  await page.waitForTimeout(1500)

  const cats = await page.evaluate(async (tenantId) => {
    const key = document.querySelector('meta[name="shop-api-key"]')?.content
    const res = await fetch(`/shop/api/categories?tenant_id=${tenantId}`, {
      headers: { Accept: "application/json", "X-Shop-Api-Key": key },
      credentials: "same-origin"
    })
    return (await res.json()).data
  }, TENANT)

  const p1 = cats[0].products[0]
  const p2 = cats[0].products[1]
  const catId = cats[0].id

  await page.evaluate(async (tenantId) => {
    const key = document.querySelector('meta[name="shop-api-key"]')?.content
    await fetch(`/shop/api/cart?tenant_id=${tenantId}`, {
      method: "DELETE",
      headers: { Accept: "application/json", "X-Shop-Api-Key": key },
      credentials: "same-origin"
    })
  }, TENANT)

  await page.goto(`${SHOP_URL}#/product/${p1.id}`)
  await page.getByRole("button", { name: /В корзину/ }).click()
  await page.waitForURL(/#\/cart/)

  await page.goto(`${SHOP_URL}#/category/${catId}`)
  await page.waitForTimeout(1500)

  const cartBtn = page.getByRole("button", { name: "В корзину" }).nth(1)
  await cartBtn.click()
  await page.waitForURL(/#\/cart/, { timeout: 30000 })

  const cart = await page.evaluate(async (tenantId) => {
    const key = document.querySelector('meta[name="shop-api-key"]')?.content
    const res = await fetch(`/shop/api/cart?tenant_id=${tenantId}`, {
      headers: { Accept: "application/json", "X-Shop-Api-Key": key },
      credentials: "same-origin"
    })
    return res.json()
  }, TENANT)

  const ids = new Set(cart.items.map((i) => i.product_id))
  const ok = cart.items.length === 2 && ids.has(p1.id) && ids.has(p2.id)
  console.log(ok ? "PASS quick-add category" : "FAIL", cart.items)
  await browser.close()
  process.exit(ok ? 0 : 1)
}

run()
