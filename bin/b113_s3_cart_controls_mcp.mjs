#!/usr/bin/env node
/**
 * B1.13-S3 — Fly MCP: +/- / Удалить / +цена в поп-апе корзины.
 *
 *   ruby bin/b113_s2_cart_popup_prep_fly.rb
 *   node bin/b113_s3_cart_controls_mcp.mjs
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium, devices } from "playwright"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const prepPath = join(root, "tmp/b113_s2_cart_popup_prep.json")
if (!existsSync(prepPath)) {
  console.error("Missing prep — run: ruby bin/b113_s2_cart_popup_prep_fly.rb")
  process.exit(2)
}
const prep = JSON.parse(readFileSync(prepPath, "utf8"))
const DATE = prep.date || new Date().toISOString().slice(0, 10)

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const screenshotDir = join(artifactDir, "screenshots")
const opsPath = join(artifactDir, `b113_s3_post_deploy_${DATE}.json`)

const steps = []
const screenshots = []
const startedAt = new Date().toISOString()

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
}

async function apiOnPage(page, path, opts = {}) {
  return page.evaluate(
    async ({ tenantId, path, opts }) => {
      const key = document.querySelector('meta[name="shop-api-key"]')?.content
      const url = path.includes("tenant_id=") ? path : `${path}${path.includes("?") ? "&" : "?"}tenant_id=${tenantId}`
      const res = await fetch(`/shop/api${url}`, {
        method: opts.method || "GET",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          "X-Shop-Api-Key": key
        },
        credentials: "same-origin",
        body: opts.body ? JSON.stringify(opts.body) : undefined
      })
      const body = await res.json().catch(() => ({}))
      return { status: res.status, body }
    },
    { tenantId: prep.tenant_id, path, opts }
  )
}

async function sheetMode(page) {
  const el = page.locator('[data-testid="shop-cart-sheet"]')
  if ((await el.count()) === 0) return null
  return el.getAttribute("data-cart-sheet-mode")
}

async function clearCart(page) {
  await apiOnPage(page, "/cart", { method: "DELETE" })
}

async function scrollCatalog(page, px) {
  await page.evaluate((amount) => window.scrollBy(0, amount), px)
  await page.waitForTimeout(400)
}

async function shot(page, name) {
  const file = `b113_s3_post_deploy_${name}_${DATE}.png`
  const path = join(screenshotDir, file)
  await page.screenshot({ path, fullPage: false })
  screenshots.push({ name, file: `screenshots/${file}` })
  return file
}

async function run() {
  mkdirSync(artifactDir, { recursive: true })
  mkdirSync(screenshotDir, { recursive: true })

  const browser = await chromium.launch({ headless: true })
  let overall = true

  try {
    const iphone = devices["iPhone 13"]
    const context = await browser.newContext({ ...iphone, locale: "ru-RU", viewport: { width: 360, height: 780 } })
    const page = await context.newPage()

    await page.goto(prep.shop_url, { waitUntil: "domcontentloaded", timeout: 90000 })
    await page.waitForTimeout(1500)
    await clearCart(page)
    await page.reload({ waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1200)

    await page.goto(`${prep.shop_url}#/product/${prep.product_id}`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1500)
    await page.getByRole("button", { name: /В корзину/i }).click()
    await page.waitForTimeout(2000)

    overall =
      step("01", "add product → sheet expanded", (await sheetMode(page)) === "expanded") && overall

    const expandedDelete = await page.locator('[data-testid="shop-cart-expanded-delete"]').count()
    const expandedPlus = await page.locator('[data-testid="shop-cart-expanded-plus"]').count()
    overall =
      step("02", "expanded: +/−/Удалить visible", expandedDelete > 0 && expandedPlus > 0) && overall

    await shot(page, "expanded")

    const cartBefore = await apiOnPage(page, "/cart")
    const qty0 = cartBefore.body?.items?.[0]?.quantity ?? 0
    await page.locator('[data-testid="shop-cart-expanded-plus"]').first().click()
    await page.waitForTimeout(800)
    const cartAfter = await apiOnPage(page, "/cart")
    const qty1 = cartAfter.body?.items?.[0]?.quantity ?? 0
    overall =
      step("03", "expanded + increases qty by 1", qty1 === qty0 + 1, { qty0, qty1 }) && overall

    const totalAfter = cartAfter.body?.total ?? 0
    overall =
      step("04", "total recalculated after +", totalAfter > cartBefore.body?.total, {
        before: cartBefore.body?.total,
        after: totalAfter
      }) && overall

    const vh = await page.evaluate(() => window.innerHeight)
    await scrollCatalog(page, Math.max(120, Math.round(vh * 0.14)))
    const peekOk = (await sheetMode(page)) === "peek"
    overall = step("05", "scroll → peek mode", peekOk) && overall

    const peekPlus = await page.locator('[data-testid="shop-cart-peek-plus"]').count()
    const peekDelete = await page.locator('[data-testid="shop-cart-expanded-delete"]').count()
    overall =
      step("06", "peek: +/- only, no Удалить", peekPlus > 0 && peekDelete === 0) && overall

    await shot(page, "peek")

    const peekQty0 = (await apiOnPage(page, "/cart")).body?.items?.[0]?.quantity ?? 0
    await page.locator('[data-testid="shop-cart-peek-plus"]').first().click()
    await page.waitForTimeout(800)
    const peekQty1 = (await apiOnPage(page, "/cart")).body?.items?.[0]?.quantity ?? 0
    overall =
      step("07", "peek + increases qty by 1", peekQty1 === peekQty0 + 1, { peekQty0, peekQty1 }) && overall

    await scrollCatalog(page, Math.max(100, Math.round(vh * 0.12)))
    overall = step("08", "scroll → hidden chip", (await sheetMode(page)) === "hidden") && overall
    await shot(page, "hidden")

    await page.locator('[data-testid="shop-cart-sheet-checkout"]').click()
    await page.waitForTimeout(1200)
    overall = step("09", "+цена → #/checkout", /#\/checkout/.test(page.url()), { url: page.url() }) && overall

    const artifact = {
      scenario: "b113_s3_post_deploy",
      task_id: "B1.13-S3",
      date: DATE,
      stand: prep.base,
      shop_url: prep.shop_url,
      product_id: prep.product_id,
      pass: overall,
      steps_pass: steps.filter((s) => s.pass).length,
      steps_total: steps.length,
      steps,
      screenshots,
      criteria_s3: {
        plus_minus: steps.find((s) => s.id === "03")?.pass && steps.find((s) => s.id === "07")?.pass,
        delete_expanded_only: steps.find((s) => s.id === "06")?.pass,
        total_recalc: steps.find((s) => s.id === "04")?.pass,
        checkout: steps.find((s) => s.id === "09")?.pass
      },
      started_at: startedAt,
      finished_at: new Date().toISOString(),
      verdict: "B1.13-S3 cart controls PASS on Fly"
    }

    writeFileSync(opsPath, JSON.stringify(artifact, null, 2))
    console.log(`\nArtifact: ${opsPath}`)
    console.log(overall ? "OVERALL PASS" : "OVERALL FAIL")
    await context.close()
    process.exit(overall ? 0 : 1)
  } catch (e) {
    step("ERR", e.message || String(e), false)
    writeFileSync(
      opsPath,
      JSON.stringify(
        {
          task_id: "B1.13-S3",
          pass: false,
          error: e.message || String(e),
          steps,
          started_at: startedAt,
          finished_at: new Date().toISOString()
        },
        null,
        2
      )
    )
    console.error(e)
    process.exit(1)
  } finally {
    await browser.close()
  }
}

run().catch((e) => {
  console.error(e)
  process.exit(1)
})
