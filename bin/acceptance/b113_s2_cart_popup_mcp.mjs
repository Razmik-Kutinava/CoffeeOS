#!/usr/bin/env node
/**
 * B1.13-S2 — Fly MCP: поп-ап корзины · bottom bar 2 вкладки · скролл/вкладки.
 *
 *   ruby bin/acceptance/b113_s2_cart_popup_prep_fly.rb
 *   node bin/acceptance/b113_s2_cart_popup_mcp.mjs
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium, devices } from "playwright"

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..")
const prepPath = join(root, "tmp/b113_s2_cart_popup_prep.json")
if (!existsSync(prepPath)) {
  console.error("Missing prep — run: ruby bin/acceptance/b113_s2_cart_popup_prep_fly.rb")
  process.exit(2)
}
const prep = JSON.parse(readFileSync(prepPath, "utf8"))
const DATE = prep.date || new Date().toISOString().slice(0, 10)

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const screenshotDir = join(artifactDir, "screenshots")
const postPath = join(artifactDir, `b113_s2_post_deploy_${DATE}.json`)

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

async function bottomNavLabels(page) {
  return page
    .locator("nav.fixed.bottom-0 span.text-xs")
    .allTextContents()
    .then((t) => t.map((s) => s.trim()).filter(Boolean))
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

async function shot(page, name, viewport = null) {
  if (viewport) await page.setViewportSize(viewport)
  const file = `b113_s2_post_deploy_${name}_${DATE}.png`
  const path = join(screenshotDir, file)
  await page.screenshot({ path, fullPage: false })
  screenshots.push({ name, file: `screenshots/${file}`, viewport: viewport ? `${viewport.width}` : "current" })
  return file
}

async function run() {
  mkdirSync(artifactDir, { recursive: true })
  mkdirSync(screenshotDir, { recursive: true })

  const browser = await chromium.launch({ headless: true })
  let overall = true
  const criteria = {}

  try {
    const upRes = await fetch(`${prep.base}/up`)
    overall = step("00", "/up 200", upRes.status === 200) && overall

    const iphone = devices["iPhone 13"]
    const context = await browser.newContext({ ...iphone, locale: "ru-RU" })
    const page = await context.newPage()

    await page.goto(prep.shop_url, { waitUntil: "domcontentloaded", timeout: 90000 })
    await page.waitForTimeout(2000)
    await clearCart(page)
    await page.reload({ waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1500)

    const labels0 = await bottomNavLabels(page)
    const c1 =
      labels0.includes("Каталог") &&
      labels0.includes("Избранное") &&
      !labels0.includes("Корзина") &&
      !labels0.includes("Профиль")
    overall =
      step("01", "bottom nav: Каталог + Избранное only", c1, { labels: labels0 }) && overall
    criteria.c1_bottom_nav_two_tabs = c1 ? "pass" : "fail"

    const emptyVisible = await page.locator('[data-testid="shop-cart-sheet-empty"]').isVisible().catch(() => false)
    const emptyText = await page.locator('[data-testid="shop-cart-sheet-empty"]').innerText().catch(() => "")
    const c2 = emptyVisible && /тут будут твои заказы/i.test(emptyText)
    overall =
      step("02", "empty cart placeholder on catalog", c2, { text: emptyText.trim() }) && overall
    criteria.c2_empty_placeholder = c2 ? "pass" : "fail"

    await shot(page, "empty_360", { width: 360, height: 780 })

    await page.goto(`${prep.shop_url}#/cart`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1200)
    const cartRouteOk = /#\/$|#\/\?|#\/$/.test(page.url()) || !page.url().includes("#/cart")
    const onCatalogHash = page.url().endsWith("#/") || page.url().includes("#/") && !page.url().includes("#/cart")
    const cCart = onCatalogHash || cartRouteOk
    overall = step("03", "#/cart redirects to catalog (no legacy cart screen)", cCart, { url: page.url() }) && overall
    criteria.c_cart_redirect = cCart ? "pass" : "fail"

    await page.goto(`${prep.shop_url}#/product/${prep.product_id}`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1500)
    await page.getByRole("button", { name: /В корзину/i }).click()
    await page.waitForTimeout(2000)

    const afterAddUrl = page.url()
    const onCatalogAfterAdd = /#\/$|#\/\?/.test(afterAddUrl) || (afterAddUrl.includes("#/") && !afterAddUrl.includes("#/cart") && !afterAddUrl.includes("#/product"))
    const modeExpanded = (await sheetMode(page)) === "expanded"
    const sheetVisible = (await page.locator('[data-testid="shop-cart-sheet"]').count()) > 0
    const c3 = onCatalogAfterAdd && sheetVisible && modeExpanded
    overall =
      step("04", "add product → catalog + sheet expanded", c3, {
        url: afterAddUrl,
        mode: await sheetMode(page)
      }) && overall
    criteria.c3_add_expanded = c3 ? "pass" : "fail"

    await shot(page, "expanded_360", { width: 360, height: 780 })

    await scrollCatalog(page, 100)
    const modePeek = (await sheetMode(page)) === "peek"
    overall = step("05", "scroll down → peek mode", modePeek, { mode: await sheetMode(page) }) && overall
    criteria.c5_scroll_peek = modePeek ? "pass" : "fail"

    await scrollCatalog(page, 100)
    const modeHidden = (await sheetMode(page)) === "hidden"
    overall = step("06", "scroll down → hidden chip", modeHidden, { mode: await sheetMode(page) }) && overall
    criteria.c6_scroll_hidden = modeHidden ? "pass" : "fail"

    await shot(page, "hidden_360", { width: 360, height: 780 })

    await page.locator('nav.fixed.bottom-0 button:has-text("Избранное")').click()
    await page.waitForTimeout(1200)
    const onFavorites = page.url().includes("#/favorites")
    const sheetHiddenOnFav = (await page.locator('[data-testid="shop-cart-sheet"]').count()) === 0
    overall =
      step("07", "favorites: cart sheet hidden", onFavorites && sheetHiddenOnFav, { url: page.url() }) && overall

    await page.locator('nav.fixed.bottom-0 button:has-text("Каталог")').click()
    await page.waitForTimeout(1200)
    const sheetBack = await page.locator('[data-testid="shop-cart-sheet"]').isVisible()
    const modeRestored = (await sheetMode(page)) === "hidden"
    const c7 = sheetBack && modeRestored
    overall =
      step("08", "return catalog: sheet state preserved", c7, { mode: await sheetMode(page) }) && overall
    criteria.c7_tab_state_preserved = c7 ? "pass" : "fail"

    await page.goto(prep.shop_url, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1000)
    await shot(page, "320px", { width: 320, height: 700 })
    await shot(page, "428px", { width: 428, height: 926 })

    const headerProfile = await page.locator("header").innerText()
    const s1Ok = /Профиль/.test(headerProfile) && !/Витрина/.test(headerProfile)
    overall = step("09", "S1 intact: profile in header", s1Ok, { header: headerProfile.trim().slice(0, 120) }) && overall
    criteria.c_s1_profile_header = s1Ok ? "pass" : "fail"

    const artifact = {
      task_id: "B1.13-S2",
      date: DATE,
      status: "POST_DEPLOY_FLY_MCP",
      shop_url: prep.shop_url,
      method: "playwright (MCP DevTools equivalent)",
      product_id: prep.product_id,
      screenshots,
      checks: {
        bottom_nav_labels: labels0,
        empty_placeholder: emptyText.trim(),
        after_add_mode: await sheetMode(page)
      },
      criteria_s2: criteria,
      steps,
      pass: overall,
      started_at: startedAt,
      finished_at: new Date().toISOString(),
      pending: ["customer_approval"]
    }

    writeFileSync(postPath, JSON.stringify(artifact, null, 2))
    console.log(`\nArtifact: ${postPath}`)
    console.log(overall ? "OVERALL PASS" : "OVERALL FAIL")
    await context.close()
    process.exit(overall ? 0 : 1)
  } catch (e) {
    step("ERR", e.message || String(e), false)
    const artifact = {
      task_id: "B1.13-S2",
      date: DATE,
      status: "POST_DEPLOY_FLY_MCP_ERROR",
      shop_url: prep.shop_url,
      pass: false,
      steps,
      error: e.message || String(e),
      started_at: startedAt,
      finished_at: new Date().toISOString(),
      pending: ["fly_deploy", "customer_approval"]
    }
    writeFileSync(postPath, JSON.stringify(artifact, null, 2))
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
