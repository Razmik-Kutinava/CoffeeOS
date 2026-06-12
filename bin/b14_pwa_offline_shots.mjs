#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium, devices } from "playwright"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const SHOP_URL = `${process.env.BASE || "https://coffeeos.fly.dev"}/shop?tenant_id=${process.env.B14_TENANT_ID || "2fdee1ac-4674-41ee-b89e-87b45643f789"}`
const outDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b14_pwa_2026-06-11")
const outJson = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback/b14_pwa_acceptance_2026-06-12.json")

const result = existsSync(outJson) ? JSON.parse(readFileSync(outJson, "utf8")) : {}
result.screenshots = result.screenshots || {}

const browser = await chromium.launch({ headless: true })
const page = await (await browser.newContext({ ...devices["iPhone 13"] })).newPage()

await page.goto(SHOP_URL, { waitUntil: "domcontentloaded", timeout: 60000 })
await page.waitForTimeout(3000)
await page.context().setOffline(true)
await page.screenshot({ path: join(outDir, "offline_catalog.png"), fullPage: true })
result.screenshots.offline_catalog = "offline_catalog.png"

await page.context().setOffline(false)
await page.goto(`${SHOP_URL}#/checkout`, { waitUntil: "domcontentloaded", timeout: 45000 })
await page.waitForTimeout(1500)
await page.context().setOffline(true)
await page.screenshot({ path: join(outDir, "offline_checkout_queued.png"), fullPage: true })
result.screenshots.offline_checkout_queued = "offline_checkout_queued.png"

await browser.close()
writeFileSync(outJson, JSON.stringify(result, null, 2))
console.log("offline screenshots ok")
