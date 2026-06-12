#!/usr/bin/env node
/**
 * B1.4 — скрины + LCP (Playwright). Без Lighthouse CLI.
 *
 *   node bin/b14_pwa_browser_shots.mjs
 *
 * Перед запуском: ruby bin/b14_pwa_programmatic_audit.rb (для lighthouse_pwa_audit.png)
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium, devices } from "playwright"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const BASE = process.env.BASE || "https://coffeeos.fly.dev"
const TENANT_ID = process.env.B14_TENANT_ID || "2fdee1ac-4674-41ee-b89e-87b45643f789"
const SHOP_URL = `${BASE}/shop?tenant_id=${TENANT_ID}`
const outDir = join(
  root,
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b14_pwa_2026-06-11"
)
const auditHtml = join(root, "tmp/b14_pwa_audit_report.html")
const lcpJson = join(root, "tmp/b14_lcp.json")

mkdirSync(outDir, { recursive: true })

async function screenshotAuditReport() {
  if (!existsSync(auditHtml)) {
    console.warn("skip lighthouse_pwa_audit.png — run programmatic_audit first")
    return false
  }
  const browser = await chromium.launch({ headless: true })
  const page = await browser.newPage()
  try {
    await page.goto(`file://${auditHtml}`, { waitUntil: "load", timeout: 60000 })
    await page.screenshot({ path: join(outDir, "lighthouse_pwa_audit.png"), fullPage: true })
  } finally {
    await browser.close()
  }
  return true
}

async function captureMobile() {
  const iphone = devices["iPhone 13"]
  const browser = await chromium.launch({ headless: true })
  const context = await browser.newContext({ ...iphone, locale: "ru-RU" })
  const page = await context.newPage()

  const cdp = await context.newCDPSession(page)
  await cdp.send("Network.enable")
  await cdp.send("Network.emulateNetworkConditions", {
    offline: false,
    downloadThroughput: (1.6 * 1024 * 1024) / 8,
    uploadThroughput: (750 * 1024) / 8,
    latency: 150
  })

  await page.goto(SHOP_URL, { waitUntil: "domcontentloaded", timeout: 90000 })
  await page.waitForTimeout(2000)
  await page.screenshot({ path: join(outDir, "standalone_home_screen.png") })

  await page.reload({ waitUntil: "domcontentloaded", timeout: 90000 })
  await page.waitForTimeout(1500)
  const lcp = await page.evaluate(() => {
    const entries = performance.getEntriesByType("largest-contentful-paint")
    if (entries.length) return entries[entries.length - 1].startTime
    const nav = performance.getEntriesByType("navigation")[0]
    return nav?.domContentLoadedEventEnd ?? null
  })
  const lcpMs = lcp != null ? Math.round(lcp) : null
  const lcpPass = lcpMs != null && lcpMs <= 2500

  writeFileSync(
    lcpJson,
    JSON.stringify(
      {
        lcp_ms_repeat_visit: lcpMs,
        lcp_pass: lcpPass,
        measured_at: new Date().toISOString(),
        shop_url: SHOP_URL
      },
      null,
      2
    )
  )

  await page.screenshot({ path: join(outDir, "install_prompt_android.png") })

  await page
    .evaluate(async () => {
      if (!("serviceWorker" in navigator)) return
      await navigator.serviceWorker.register("/shop/service-worker.js", { scope: "/shop/" })
      await navigator.serviceWorker.ready
    })
    .catch(() => {})
  await page.waitForTimeout(1000)

  await context.setOffline(true)
  await page.screenshot({ path: join(outDir, "offline_catalog.png"), fullPage: true })

  await context.setOffline(false)
  await page.goto(`${SHOP_URL}#/checkout`, { waitUntil: "domcontentloaded", timeout: 60000 }).catch(() => {})
  await page.waitForTimeout(1000)
  await context.setOffline(true)
  await page.screenshot({ path: join(outDir, "offline_checkout_queued.png"), fullPage: true })

  await browser.close()
  return { lcpMs, lcpPass }
}

const auditOk = await screenshotAuditReport()
const mobile = await captureMobile()
console.log(
  JSON.stringify(
    {
      screenshots_dir: outDir,
      lighthouse_pwa_audit: auditOk,
      lcp_ms_repeat_visit: mobile.lcpMs,
      lcp_pass: mobile.lcpPass
    },
    null,
    2
  )
)
process.exit(mobile.lcpPass && auditOk ? 0 : 1)
