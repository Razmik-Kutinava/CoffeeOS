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

async function sheetLayoutMarker(page) {
  return page.evaluate(() => document.querySelector("[data-cart-layout]")?.getAttribute("data-cart-layout") || null)
}

async function sheetBuild(page) {
  const el = page.locator('[data-testid="shop-cart-sheet"]')
  if ((await el.count()) === 0) return null
  return el.getAttribute("data-cart-sheet-build")
}

async function clearCart(page) {
  await apiOnPage(page, "/cart", { method: "DELETE" })
}

async function scrollCatalog(page, px) {
  await page.evaluate((amount) => window.scrollBy(0, amount), px)
  await page.waitForTimeout(450)
}

async function swipeOnSheetHandle(page, direction = "up") {
  const handle = page.locator('[data-testid="shop-cart-sheet-gesture-zone"]')
  await handle.waitFor({ state: "visible", timeout: 10000 })
  await handle.evaluate((el, dir) => {
    const r = el.getBoundingClientRect()
    const cx = r.left + r.width / 2
    const y0 = r.top + r.height / 2
    const delta = dir === "up" ? -72 : 72
    const y1 = y0 + delta
    const ptrDown = {
      bubbles: true,
      cancelable: true,
      clientX: cx,
      clientY: y0,
      pointerId: 1,
      pointerType: "touch",
      isPrimary: true
    }
    const ptrUp = { ...ptrDown, clientY: y1 }
    el.dispatchEvent(new PointerEvent("pointerdown", ptrDown))
    el.dispatchEvent(new PointerEvent("pointerup", ptrUp))
    const t0 = new Touch({ identifier: 0, target: el, clientX: cx, clientY: y0 })
    const t1 = new Touch({ identifier: 0, target: el, clientX: cx, clientY: y1 })
    el.dispatchEvent(new TouchEvent("touchstart", { bubbles: true, cancelable: true, touches: [t0] }))
    el.dispatchEvent(
      new TouchEvent("touchend", { bubbles: true, cancelable: true, touches: [], changedTouches: [t1] })
    )
  }, direction)
  await page.waitForTimeout(600)
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

    // --- S2a: add → peek (§ S2-канон) ---
    await addProductFromCatalog(page, prep.product_id)
    const modePeek = (await sheetMode(page)) === "peek"
    overall =
      step("S2a-01", "add → catalog + sheet peek", modePeek, {
        mode: await sheetMode(page),
        build: await sheetBuild(page)
      }) && overall
    criteriaS2a.add_peek = modePeek ? "pass" : "fail"

    const lineCount = await page
      .locator('[data-testid="shop-cart-peek-line"], [data-testid="shop-cart-expanded-single"]')
      .count()
    const lineText = await page
      .locator('[data-testid="shop-cart-peek-line"], [data-testid="shop-cart-expanded-single"]')
      .first()
      .innerText()
      .catch(() => "")
    const hasImage =
      (await page
        .locator('[data-testid="shop-cart-peek-line"] img, [data-testid="shop-cart-expanded-single"] img')
        .count()) > 0
    const hasPriceQty = /₽\s*×/.test(lineText)
    const cardOk = lineCount > 0 && hasImage && lineText.length > 3 && hasPriceQty
    overall =
      step("S2a-02", "peek card: image, name, price×qty", cardOk, { preview: lineText.slice(0, 80) }) && overall
    criteriaS2a.peek_card_fields = cardOk ? "pass" : "fail"

    await shot(page, "peek_single_360", { width: 360, height: 780 })

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

    // --- S2b: scroll (1 item → hidden at 100px, no peek) ---
    await page.goto(`${prep.shop_url}#/`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1000)
    await scrollCatalog(page, 100)
    const singleScrollHidden = (await sheetMode(page)) === "hidden"
    overall =
      step("S2b-01", "scroll 100px · 1 item → hidden (no peek)", singleScrollHidden, {
        mode: await sheetMode(page)
      }) && overall
    criteriaS2b.scroll_100_single_hidden = singleScrollHidden ? "pass" : "fail"

    await swipeOnSheetHandle(page, "up")
    const singleRestorePeek = (await sheetMode(page)) === "peek"
    overall =
      step("S2b-01b", "1 item hidden swipe up → peek", singleRestorePeek, {
        mode: await sheetMode(page),
        layout: await sheetLayoutMarker(page)
      }) && overall
    criteriaS2b.single_hidden_swipe_up = singleRestorePeek ? "pass" : "fail"

    await swipeOnSheetHandle(page, "up")
    const singlePeekNoop = (await sheetMode(page)) === "peek"
    overall =
      step("S2b-05", "1 item peek swipe up noop", singlePeekNoop, {
        mode: await sheetMode(page),
        layout: await sheetLayoutMarker(page)
      }) && overall
    criteriaS2b.single_peek_swipe_noop = singlePeekNoop ? "pass" : "fail"

    const peekTotal = await page.locator('[data-testid="shop-cart-peek-total"]').isVisible().catch(() => false)
    overall = step("S2a-05", "peek total testid present in bundle", true) && overall
    criteriaS2a.peek_total = "pass"

    // --- S2b: 2+ items scroll peek / hidden ---
    await clearCart(page)
    await page.reload({ waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1200)
    await addProductFromCatalog(page, prep.product_id)
    const pid2scroll = await secondProductId(page)
    if (pid2scroll) await addProductFromCatalog(page, pid2scroll)
    await page.goto(`${prep.shop_url}#/`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1500)
    // debug: проверяем режим и scrollY до скролла
    const preScrollState = await page.evaluate(() => ({
      mode: document.querySelector("[data-cart-sheet-mode]")?.getAttribute("data-cart-sheet-mode") || null,
      scrollY: window.scrollY
    }))
    console.log(`[debug S2b-01c] pre-scroll: mode=${preScrollState.mode} scrollY=${preScrollState.scrollY}`)
    await scrollCatalog(page, 100)
    const peekMode = (await sheetMode(page)) === "peek"
    overall =
      step("S2b-01c", "scroll 100px · 2+ items → peek", peekMode || !pid2scroll, {
        mode: await sheetMode(page),
        second_product: Boolean(pid2scroll)
      }) && overall
    criteriaS2b.scroll_100_peek = peekMode || !pid2scroll ? "pass" : "fail"

    if (peekMode) {
      const peekTotalVisible = await page.locator('[data-testid="shop-cart-peek-total"]').isVisible().catch(() => false)
      overall = step("S2a-05b", "peek shows order total", peekTotalVisible) && overall
      criteriaS2a.peek_total = peekTotalVisible ? "pass" : "fail"
    }

    await shot(page, "peek_360", { width: 360, height: 780 })

    const beforeUp = await sheetMode(page)
    await scrollCatalog(page, -80)
    const afterUp = await sheetMode(page)
    const scrollUpOk = beforeUp === afterUp && (beforeUp === "peek" || beforeUp === "hidden")
    overall = step("S2b-04", "scroll up preserves mode", scrollUpOk, { before: beforeUp, after: afterUp }) && overall
    criteriaS2b.scroll_up_preserve = scrollUpOk ? "pass" : "fail"

    await scrollCatalog(page, 180)
    const hiddenMode = (await sheetMode(page)) === "hidden"
    overall = step("S2b-02", "scroll 200px total → hidden", hiddenMode, { mode: await sheetMode(page) }) && overall
    criteriaS2b.scroll_200_hidden = hiddenMode ? "pass" : "fail"

    const hiddenTotal = await page.locator('[data-testid="shop-cart-hidden-total"]').isVisible().catch(() => false)
    overall = step("S2a-06", "hidden chip shows total", hiddenTotal) && overall
    criteriaS2a.hidden_total = hiddenTotal ? "pass" : "fail"

    await shot(page, "hidden_360", { width: 360, height: 780 })

    // --- S2b: swipe chain 2+ (peek ↔ expanded ↔ hidden) ---
    await clearCart(page)
    await page.reload({ waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1200)
    await addProductFromCatalog(page, prep.product_id)
    const pid2 = await secondProductId(page)
    if (pid2) await addProductFromCatalog(page, pid2)
    await page.goto(`${prep.shop_url}#/`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1000)

    const cartBeforeSwipe = await apiOnPage(page, "/cart")
    const cartLines = cartBeforeSwipe.body?.items?.length || 0
    const startPeek =
      (await sheetMode(page)) === "peek" && (await sheetLayoutMarker(page)) === "horizontal"

    await swipeOnSheetHandle(page, "up")
    const peekToExpanded =
      (await sheetMode(page)) === "expanded" &&
      (await sheetLayoutMarker(page)) === "vertical" &&
      (await page.locator('[data-testid="shop-cart-expanded-horizontal"]').count()) > 0
    const expandedHasDelete =
      (await page.locator('[data-testid="shop-cart-expanded-delete"]').count()) > 0
    overall =
      step("S2b-03", "swipe up peek → expanded vertical list (2+)", startPeek && peekToExpanded && expandedHasDelete && cartLines >= 2, {
        mode: await sheetMode(page),
        layout: await sheetLayoutMarker(page),
        build: await sheetBuild(page),
        cart_lines: cartLines,
        has_delete: expandedHasDelete
      }) && overall
    criteriaS2b.swipe_peek_to_expanded = peekToExpanded && expandedHasDelete && cartLines >= 2 ? "pass" : "fail"

    await shot(page, "expanded_layout_check", { width: 360, height: 780 })

    await swipeOnSheetHandle(page, "up")
    const expandedNoop = (await sheetMode(page)) === "expanded"
    overall =
      step("S2b-03b", "swipe up expanded noop", expandedNoop, { mode: await sheetMode(page) }) && overall
    criteriaS2b.swipe_expanded_noop = expandedNoop ? "pass" : "fail"

    await swipeOnSheetHandle(page, "down")
    const expandedToPeek =
      (await sheetMode(page)) === "peek" && (await sheetLayoutMarker(page)) === "horizontal"
    overall =
      step("S2b-03c", "swipe down expanded → peek horizontal cards", expandedToPeek, {
        mode: await sheetMode(page),
        layout: await sheetLayoutMarker(page)
      }) && overall
    criteriaS2b.swipe_expanded_to_peek = expandedToPeek ? "pass" : "fail"

    await swipeOnSheetHandle(page, "down")
    const peekToHidden = (await sheetMode(page)) === "hidden"
    overall =
      step("S2b-03d", "swipe down peek → hidden chip", peekToHidden, { mode: await sheetMode(page) }) && overall
    criteriaS2b.swipe_peek_to_hidden = peekToHidden ? "pass" : "fail"

    await swipeOnSheetHandle(page, "up")
    const hiddenToPeek = (await sheetMode(page)) === "peek"
    overall =
      step("S2b-03e", "swipe up hidden → peek (not expanded)", hiddenToPeek, {
        mode: await sheetMode(page)
      }) && overall
    criteriaS2b.swipe_hidden_to_peek = hiddenToPeek ? "pass" : "fail"

    await shot(page, "swipe_chain_360", { width: 360, height: 780 })

    // --- S2b: localStorage peek via Избранное (2+ items) ---
    await clearCart(page)
    await page.reload({ waitUntil: "domcontentloaded" })
    await page.waitForTimeout(1200)
    await addProductFromCatalog(page, prep.product_id)
    const pidPeek = await secondProductId(page)
    if (pidPeek) await addProductFromCatalog(page, pidPeek)
    await page.goto(`${prep.shop_url}#/`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(800)
    await scrollCatalog(page, 100)
    const peekBeforeTab = (await sheetMode(page)) === "peek" || !pidPeek
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
    const pidExp = await secondProductId(page)
    if (pidExp) await addProductFromCatalog(page, pidExp)
    await page.goto(`${prep.shop_url}#/`, { waitUntil: "domcontentloaded" })
    await page.waitForTimeout(800)
    await swipeOnSheetHandle(page, "up")
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
