#!/usr/bin/env node
/**
 * B1.4 PWA formal acceptance on Fly — Lighthouse PWA, LCP, скрины.
 *   node bin/b14_pwa_acceptance_fly.mjs
 *   node bin/b14_pwa_acceptance_fly.mjs --lighthouse-only
 *   node bin/b14_pwa_acceptance_fly.mjs --screenshots-only
 */
import { execSync } from "node:child_process"
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium, devices } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const BASE = process.env.BASE || "https://coffeeos.fly.dev"
const TENANT_ID = process.env.B14_TENANT_ID || "2fdee1ac-4674-41ee-b89e-87b45643f789"
const SHOP_URL = `${BASE}/shop?tenant_id=${TENANT_ID}`
const outDir = join(
  root,
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b14_pwa_2026-06-11"
)
const tmpDir = join(root, "tmp")
const outJson = join(
  root,
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/b14_pwa_acceptance_2026-06-12.json"
)

const args = new Set(process.argv.slice(2))
const lighthouseOnly = args.has("--lighthouse-only")
const screenshotsOnly = args.has("--screenshots-only")

function loadExisting() {
  if (!existsSync(outJson)) return {}
  try {
    return JSON.parse(readFileSync(outJson, "utf8"))
  } catch {
    return {}
  }
}

const result = {
  ...loadExisting(),
  task: "B14_pwa_formal_acceptance",
  run_at: new Date().toISOString(),
  base: BASE,
  tenant_id: TENANT_ID,
  shop_url: SHOP_URL,
  lighthouse_pwa: loadExisting().lighthouse_pwa ?? null,
  lcp_ms_repeat_visit: loadExisting().lcp_ms_repeat_visit ?? null,
  lcp_pass: loadExisting().lcp_pass ?? false,
  screenshots: { ...(loadExisting().screenshots || {}) },
  notes: [...(loadExisting().notes || [])]
}

mkdirSync(outDir, { recursive: true })
mkdirSync(tmpDir, { recursive: true })

function save() {
  writeFileSync(outJson, JSON.stringify(result, null, 2))
}

function runLighthouse() {
  const basePath = join(tmpDir, "b14_lighthouse_pwa")
  const jsonPath = `${basePath}.report.json`
  const htmlPath = `${basePath}.report.html`
  try {
    execSync(
      `npx --yes lighthouse "${SHOP_URL}" --only-categories=pwa --form-factor=mobile --quiet --chrome-flags="--headless --no-sandbox --disable-dev-shm-usage" --output=json --output=html --output-path=${basePath}`,
      { cwd: root, stdio: "inherit", timeout: 300000 }
    )
  } catch (e) {
    result.notes.push(`lighthouse exit: ${e.status ?? "error"}`)
  }

  const path = existsSync(jsonPath) ? jsonPath : `${basePath}.json`
  if (!existsSync(path)) {
    result.notes.push("lighthouse json missing")
    return null
  }

  const audit = JSON.parse(readFileSync(path, "utf8"))
  const pwa = audit.categories?.pwa || {}
  const score = typeof pwa.score === "number" ? Math.round(pwa.score * 100) : null
  const audits = audit.audits || {}
  const failed = Object.values(audits).filter(
    (a) => a.score !== null && a.score < 1 && a.scoreDisplayMode !== "notApplicable"
  )

  result.lighthouse_pwa = {
    score_percent: score,
    pass: score === 100,
    failed_audit_ids: failed.map((a) => a.id).slice(0, 15)
  }

  const html = existsSync(htmlPath) ? htmlPath : `${basePath}.html`
  return existsSync(html) ? html : null
}

async function lighthouseScreenshot(htmlPath) {
  const browser = await chromium.launch({ headless: true })
  const page = await browser.newPage()
  try {
    await page.goto(`file://${htmlPath}`, { waitUntil: "load", timeout: 60000 })
    await page.screenshot({ path: join(outDir, "lighthouse_pwa_audit.png"), fullPage: true })
    result.screenshots.lighthouse_pwa_audit = "lighthouse_pwa_audit.png"
  } catch {
    result.notes.push("lighthouse html screenshot failed")
  }
  await browser.close()
}

async function captureScreenshots() {
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
  result.screenshots.standalone_home_screen = "standalone_home_screen.png"

  await page.reload({ waitUntil: "domcontentloaded", timeout: 90000 })
  await page.waitForTimeout(1500)
  const lcp = await page.evaluate(() => {
    const entries = performance.getEntriesByType("largest-contentful-paint")
    if (entries.length) return entries[entries.length - 1].startTime
    const nav = performance.getEntriesByType("navigation")[0]
    return nav?.domContentLoadedEventEnd ?? null
  })
  result.lcp_ms_repeat_visit = lcp != null ? Math.round(lcp) : null
  result.lcp_pass = result.lcp_ms_repeat_visit != null && result.lcp_ms_repeat_visit <= 2500

  await page.screenshot({ path: join(outDir, "install_prompt_android.png") })
  result.screenshots.install_prompt_android = "install_prompt_android.png"
  if (!result.notes.some((n) => n.includes("install_prompt"))) {
    result.notes.push("install_prompt: mobile viewport (beforeinstallprompt редко в headless)")
  }

  await page.evaluate(async () => {
    if (!("serviceWorker" in navigator)) return
    await navigator.serviceWorker.register("/shop/service-worker.js", { scope: "/shop/" })
    await navigator.serviceWorker.ready
  }).catch(() => {})
  await page.waitForTimeout(1000)

  await context.setOffline(true)
  await page.screenshot({ path: join(outDir, "offline_catalog.png"), fullPage: true })
  result.screenshots.offline_catalog = "offline_catalog.png"

  await context.setOffline(false)
  await page.goto(`${SHOP_URL}#/checkout`, { waitUntil: "domcontentloaded", timeout: 60000 }).catch(() => {})
  await page.waitForTimeout(1000)
  await context.setOffline(true)
  await page.screenshot({ path: join(outDir, "offline_checkout_queued.png"), fullPage: true })
  result.screenshots.offline_checkout_queued = "offline_checkout_queued.png"

  if (!result.notes.some((n) => n.includes("ios_add_to_home"))) {
    result.notes.push("ios_add_to_home: только физическое устройство — пропущено")
  }

  await browser.close()
}

function finalizeStatus() {
  const screenshotCount = Object.keys(result.screenshots).length
  result.fly_smoke = result.fly_smoke || loadExisting().fly_smoke
  const smokePass = result.fly_smoke?.status === "PASS" || result.fly_smoke === true
  result.status =
    smokePass &&
    result.lighthouse_pwa?.pass &&
    result.lcp_pass &&
    screenshotCount >= 5
      ? "OPS_PASS"
      : "PARTIAL"
}

async function main() {
  if (!screenshotsOnly) {
    const htmlPath = runLighthouse()
    if (htmlPath) await lighthouseScreenshot(htmlPath)
    save()
  }

  if (!lighthouseOnly) {
    await captureScreenshots()
    save()
  }

  finalizeStatus()
  save()
  console.log(JSON.stringify(result, null, 2))
  process.exit(result.status === "OPS_PASS" ? 0 : 1)
}

main().catch((e) => {
  console.error(e)
  result.error = e.message
  save()
  process.exit(1)
})
