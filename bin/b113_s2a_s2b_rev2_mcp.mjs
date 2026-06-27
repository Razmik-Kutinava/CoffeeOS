#!/usr/bin/env node
/**
 * B1.13-S2a/S2b rev2 — Fly MCP: приёмка поп-апа (без пустой корзины / Q-rev2).
 *
 *   ruby bin/b113_s2_cart_popup_prep_fly.rb
 *   node bin/b113_s2a_s2b_rev2_mcp.mjs
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
const postPath = join(artifactDir, `b113_s2a_s2b_rev2_post_deploy_${DATE}.json`)

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
  await page.waitForTimeout(450)
}

async function swipeUpOnSheet(page) {
  const sheet = page.locator('[data-testid="shop-cart-sheet"]')
  const box = await sheet.boundingBox()
  if (!box) return
  const x = box.x + box.width / 2
  const y0 = box.y + box.height - 20
  const y1 = box.y + 20
  await page.mouse.move(x, y0)
  await page.mouse.down()
  await page.mouse.move(x, y1, { steps: 10 })
  await page.mouse.up()
  await page.waitForTimeout(500)
}

async function addProductFromCatalog(page, productId) {
  await page.goto(`${prep.shop_url}#/product/${productId}`, { waitUntil: "domcontentloaded" })
  await page.waitForTimeout(1500)
  await page.getByRole("button", { name: /В корзину/i }).click()
  await page.waitForTimeout(2000)
}

async function secondProductId(page) {
  const res = await apiOnPage(page, "/categories")
  const products = (res.body?.data || []).flatMap((c) => c.products || [])
  const other = products.find((p) => String(p.id) !== String(prep.product_id))
  return other?.id || null
}

async function shot(page, name, viewport = null) {
  if (viewport) await page.setViewportSize(viewport)
  const file = `b113_s2a_s2b_rev2_${name}_${DATE}.png`
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
  const criteriaS2a = {}
  const criteriaS2b = {}

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

    // --- S2a: add → expanded ---
    await addProductFromCatalog(page, prep.product_id)
    const modeExpanded = (await sheetMode(page)) === "expanded"
    overall =
      step("S2a-01", "add → catalog + sheet expanded", modeExpanded, { mode: await sheetMode(page) }) && overall
    criteriaS2a.add_expanded = modeExpanded ? "pass" : "fail"

    const lineCount = await page.locator('[data-testid="shop-cart-expanded-line"]').count()
    const lineText = await page.locator('[data-testid="shop-cart-expanded-line"]').first().innerText().catch(() => "")
    const hasImage = (await page.locator('[data-testid="shop-cart-expanded-line"] img').count()) > 0
    const hasPriceQty = /₽\s*×/.test(lineText)
    const cardOk = lineCount > 0 && hasImage && lineText.length > 3 && hasPriceQty
    overall =
      step("S2a-02", "expanded card: image, name, price×qty", cardOk, { preview: lineText.slice(0, 80) }) && overall
    criteriaS2a.expanded_card_fields = cardOk ? "pass" : "fail"

    await shot(page, "expanded_360", { width: 360, height: 780 })

    const transitionMs = await page
      .locator('[data-testid="shop-cart-sheet"]')
      .evaluate((el) => getComputedStyle(el).transitionDuration)
      .catch(() => "")
    const animOk = transitionMs.includes("0.3s") || transitionMs.includes("300ms")
    overall = step("S2a-03", "transition duration ~300ms", animOk, { transitionDuration: transitionMs }) && overall
    criteriaS2a.animation_300ms = animOk ? "pass" : "fail"

    const layout = await page.locator('[data-testid="shop-cart-sheet"]').evaluate((el) => {
      const s = getComputedStyle(el)
      return { bottom: s.bottom, maxWidth: s.maxWidth, zIndex: s.zIndex }
    })
    const layoutOk =
      layout.zIndex === "50" &&
      (layout.bottom === "56px" || layout.bottom === "3.5rem") &&
      (layout.maxWidth === "414px" || layout.maxWidth === "100%")
    overall = step("S2a-04", "sheet above bottom bar, max-width 414px", layoutOk, layout) && overall
    criteriaS2a.layout_above_nav = layoutOk ? "pass" : "fail"

    // --- S2b: scroll peek / hidden ---
    await page.goto(`${prep.shop_url}#/`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1000)
    await scrollCatalog(page, 100)
    const peekMode = (await sheetMode(page)) === "peek"
    overall = step("S2b-01", "scroll 100px → peek", peekMode, { mode: await sheetMode(page) }) && overall
    criteriaS2b.scroll_100_peek = peekMode ? "pass" : "fail"

    const peekTotal = await page.locator('[data-testid="shop-cart-peek-total"]').isVisible().catch(() => false)
    overall = step("S2a-05", "peek shows order total", peekTotal) && overall
    criteriaS2a.peek_total = peekTotal ? "pass" : "fail"

    await shot(page, "peek_360", { width: 360, height: 780 })

    const beforeUp = await sheetMode(page)
    await scrollCatalog(page, -80)
    const afterUp = await sheetMode(page)
    const scrollUpOk = beforeUp === "peek" && afterUp === "peek"
    overall = step("S2b-04", "scroll up preserves peek", scrollUpOk, { before: beforeUp, after: afterUp }) && overall
    criteriaS2b.scroll_up_preserve = scrollUpOk ? "pass" : "fail"

    await scrollCatalog(page, 180)
    const hiddenMode = (await sheetMode(page)) === "hidden"
    overall = step("S2b-02", "scroll 200px total → hidden", hiddenMode, { mode: await sheetMode(page) }) && overall
    criteriaS2b.scroll_200_hidden = hiddenMode ? "pass" : "fail"

    const hiddenTotal = await page.locator('[data-testid="shop-cart-hidden-total"]').isVisible().catch(() => false)
    overall = step("S2a-06", "hidden chip shows total", hiddenTotal) && overall
    criteriaS2a.hidden_total = hiddenTotal ? "pass" : "fail"

    await shot(page, "hidden_360", { width: 360, height: 780 })

    // --- S2b: swipe up (2 lines) — отдельная корзина ---
    await clearCart(page)
    await page.reload({ waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1200)
    await addProductFromCatalog(page, prep.product_id)
    const pid2 = await secondProductId(page)
    if (pid2) await addProductFromCatalog(page, pid2)
    await page.goto(`${prep.shop_url}#/`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1000)
    await scrollCatalog(page, 100)
    await scrollCatalog(page, 100)
    const cartBeforeSwipe = await apiOnPage(page, "/cart")
    const cartLines = cartBeforeSwipe.body?.items?.length || 0
    await swipeUpOnSheet(page)
    const swipeExpanded = (await sheetMode(page)) === "expanded"
    overall =
      step("S2b-03", "swipe up on sheet → expanded (2+ lines)", swipeExpanded && cartLines >= 2, {
        mode: await sheetMode(page),
        second_product: Boolean(pid2),
        cart_lines: cartLines
      }) && overall
    criteriaS2b.swipe_up_expanded = swipeExpanded && cartLines >= 2 ? "pass" : "fail"

    await shot(page, "swipe_expanded_360", { width: 360, height: 780 })

    // --- S2b: 1 item swipe no expand ---
    await clearCart(page)
    await page.reload({ waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1200)
    await addProductFromCatalog(page, prep.product_id)
    await page.goto(`${prep.shop_url}#/`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(800)
    await scrollCatalog(page, 100)
    await scrollCatalog(page, 100)
    const beforeSingleSwipe = await sheetMode(page)
    await swipeUpOnSheet(page)
    const afterSingleSwipe = await sheetMode(page)
    const singleSwipeOk = beforeSingleSwipe === "hidden" && afterSingleSwipe === "hidden"
    overall =
      step("S2b-05", "1 item: swipe up does not expand", singleSwipeOk, {
        before: beforeSingleSwipe,
        after: afterSingleSwipe
      }) && overall
    criteriaS2b.single_item_no_swipe_expand = singleSwipeOk ? "pass" : "fail"

    // --- S2b: localStorage peek via Избранное ---
    await clearCart(page)
    await page.reload({ waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1200)
    await addProductFromCatalog(page, prep.product_id)
    await page.goto(`${prep.shop_url}#/`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(800)
    await scrollCatalog(page, 100)
    const peekBeforeTab = (await sheetMode(page)) === "peek"
    await page.locator('nav.fixed.bottom-0 button:has-text("Избранное")').click()
    await page.waitForTimeout(1200)
    await page.locator('nav.fixed.bottom-0 button:has-text("Каталог")').click()
    await page.waitForTimeout(1200)
    const peekRestored = (await sheetMode(page)) === "peek"
    overall =
      step("S2b-06", "Избранное→Каталог: peek restored", peekBeforeTab && peekRestored, {
        mode: await sheetMode(page)
      }) && overall
    criteriaS2b.ls_peek_tab = peekBeforeTab && peekRestored ? "pass" : "fail"

    // --- S2b: localStorage expanded via Профиль ---
    await clearCart(page)
    await page.reload({ waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1200)
    await addProductFromCatalog(page, prep.product_id)
    const expandedBeforeProfile = (await sheetMode(page)) === "expanded"
    await page.locator('[data-testid="shop-header-profile"]').click()
    await page.waitForTimeout(1200)
    await page.locator('nav.fixed.bottom-0 button:has-text("Каталог")').click()
    await page.waitForTimeout(1200)
    const expandedRestored = (await sheetMode(page)) === "expanded"
    overall =
      step("S2b-07", "Профиль→Каталог: expanded restored", expandedBeforeProfile && expandedRestored, {
        mode: await sheetMode(page)
      }) && overall
    criteriaS2b.ls_expanded_profile = expandedBeforeProfile && expandedRestored ? "pass" : "fail"

    await shot(page, "320px", { width: 320, height: 700 })
    await shot(page, "414px", { width: 414, height: 896 })

    const passCount = steps.filter((s) => s.pass).length
    const artifact = {
      scenario: "b113_s2a_s2b_rev2_post_deploy",
      task_id: "B1.13-S2a+S2b-rev2",
      date: DATE,
      status: "POST_DEPLOY_FLY_MCP",
      stand: prep.base,
      shop_url: prep.shop_url,
      product_id: prep.product_id,
      method: "playwright (MCP DevTools equivalent)",
      skipped: ["empty_cart_q_rev2"],
      screenshots,
      criteria_s2a: criteriaS2a,
      criteria_s2b: criteriaS2b,
      steps,
      pass: overall,
      steps_pass: passCount,
      steps_total: steps.length,
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
      scenario: "b113_s2a_s2b_rev2_post_deploy",
      task_id: "B1.13-S2a+S2b-rev2",
      date: DATE,
      status: "POST_DEPLOY_FLY_MCP_ERROR",
      shop_url: prep.shop_url,
      pass: false,
      steps,
      error: e.message || String(e),
      started_at: startedAt,
      finished_at: new Date().toISOString()
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
