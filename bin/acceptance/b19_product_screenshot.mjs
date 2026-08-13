#!/usr/bin/env node
/** B1.9 — скрин карточки с toggle «+» для апрува заказчика */
import { mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium, devices } from "playwright"

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..")
const SHOP = "https://coffeeos.fly.dev/shop?tenant_id=655aaccb-004a-4bb9-a50a-ce618854dda3"
const PRODUCT_ID = "24dae391-2199-4959-907e-d08c4cec3329"
const out = join(
  root,
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b19_modifier_toggle_product_2026-06-16.png"
)

mkdirSync(dirname(out), { recursive: true })

const browser = await chromium.launch({ headless: true })
const page = await browser.newPage({ ...devices["iPhone 13"], locale: "ru-RU" })
await page.goto(`${SHOP}#/product/${PRODUCT_ID}`, { waitUntil: "domcontentloaded", timeout: 90000 })
await page.waitForSelector(".mod-chip", { timeout: 60000 })
const paid = page.locator(".mod-chip").filter({ hasText: /\+30₽/ }).first()
await paid.click()
await page.waitForTimeout(500)
await page.screenshot({ path: out, fullPage: true })
await browser.close()
console.log("saved", out)
