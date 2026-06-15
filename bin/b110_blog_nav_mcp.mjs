#!/usr/bin/env node
/**
 * B1.10 — шапка без «Блог» + LCP ≤ 1.5 s (Playwright, аналог MCP DevTools).
 *
 *   node bin/b110_blog_nav_mcp.mjs              # post-deploy: Блог отсутствует
 *   node bin/b110_blog_nav_mcp.mjs --expect-blog  # до правки: Блог есть
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium, devices } from "playwright"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const BASE = process.env.BASE || "https://coffeeos.fly.dev"
const TENANT = process.env.TENANT || "655aaccb-004a-4bb9-a50a-ce618854dda3"
const SHOP_URL = `${BASE}/shop?tenant_id=${TENANT}`
const expectBlog = process.argv.includes("--expect-blog")

const shotDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots")
const artifactPath = join(
  root,
  "docs/operations/milestones/veha_2/artifacts/demo-feedback/b110_blog_nav_post_deploy_2026-06-15.json"
)

mkdirSync(shotDir, { recursive: true })

const steps = []
const startedAt = new Date().toISOString()

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
}

async function measure(page) {
  await page.waitForTimeout(1200)
  const headerText = await page.locator("header").innerText().catch(() => "")
  const bodyText = await page.locator("body").innerText().catch(() => "")
  const blogLinkCount = await page.locator('header a[href="/blog"]').count()
  const hasBlogInHeader = blogLinkCount > 0 || /\bБлог\b/.test(headerText)
  const hasVitrina = /Витрина/.test(headerText)
  const lcp = await page.evaluate(() => {
    const entries = performance.getEntriesByType("largest-contentful-paint")
    if (entries.length) return entries[entries.length - 1].startTime
    const nav = performance.getEntriesByType("navigation")[0]
    return nav?.domContentLoadedEventEnd ?? null
  })
  const interactiveMs = await page.evaluate(() => {
    const nav = performance.getEntriesByType("navigation")[0]
    return nav ? Math.round(nav.domInteractive) : null
  })
  const lcpMs = lcp != null ? Math.round(lcp) : interactiveMs
  return { headerText, bodyText, hasBlogInHeader, hasVitrina, lcpMs, interactiveMs }
}

async function run() {
  const iphone = devices["iPhone 13"]
  const browser = await chromium.launch({ headless: true })
  let overall = true

  try {
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

    const t0 = Date.now()
    await page.goto(SHOP_URL, { waitUntil: "domcontentloaded", timeout: 90000 })
    const navMs = Date.now() - t0
    const m = await measure(page)

    const shotName = expectBlog ? "b110_blog_nav_before.png" : "b110_blog_nav_after_2026-06-15.png"
    await page.screenshot({ path: join(shotDir, shotName), fullPage: false })

    const blogCheck = expectBlog ? m.hasBlogInHeader : !m.hasBlogInHeader
    overall =
      step("01", expectBlog ? "header contains «Блог» (before)" : "header has no «Блог»", blogCheck, {
        hasBlogInHeader: m.hasBlogInHeader,
        headerText: m.headerText.trim()
      }) && overall

    overall =
      step("02", "header shows «Витрина»", m.hasVitrina, { hasVitrina: m.hasVitrina }) && overall

    const lcpPass = m.lcpMs != null && m.lcpMs <= 1500
    overall =
      step("03", "LCP / interactive ≤ 1500 ms", lcpPass, {
        lcp_ms: m.lcpMs,
        nav_domcontentloaded_ms: navMs
      }) && overall

    overall =
      step("04", "catalog interactive (CoffeeOS visible)", /CoffeeOS/.test(m.bodyText)) && overall

    const artifact = {
      scenario: expectBlog ? "b110_before_blog_in_nav" : "b110_post_deploy_no_blog",
      tool: "playwright_mobile_4g (MCP DevTools equivalent)",
      stand: BASE,
      tenant_id: TENANT,
      shop_url: SHOP_URL,
      started_at: startedAt,
      finished_at: new Date().toISOString(),
      pass: overall,
      expect_blog: expectBlog,
      steps,
      metrics: {
        lcp_ms: m.lcpMs,
        navigation_ms: navMs,
        lcp_threshold_ms: 1500
      },
      screenshot: shotName
    }

    if (!expectBlog) {
      writeFileSync(artifactPath, JSON.stringify(artifact, null, 2))
      console.log(`\nArtifact: ${artifactPath}`)
    }

    process.exit(overall ? 0 : 1)
  } finally {
    await browser.close()
  }
}

run().catch((e) => {
  console.error(e)
  process.exit(1)
})
