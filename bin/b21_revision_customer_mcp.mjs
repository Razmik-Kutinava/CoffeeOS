#!/usr/bin/env node
/**
 * B2.1 ревизия — прогон приёмки заказчика на Fly (Playwright, сценарий 1.1–1.4).
 *   node bin/b21_revision_customer_mcp.mjs
 * Требует: tmp/b21_revision_fly_prep.json (screen_dir = customer mcp folder)
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const prep = JSON.parse(readFileSync(join(root, "tmp/b21_revision_fly_prep.json"), "utf8"))
const outDir = join(root, prep.screen_dir)
const steps = []
const startedAt = new Date().toISOString()

const BASE = prep.base
const BARISTA_EMAIL = prep.barista_email
const PASSWORD = process.env.STAFF_PASSWORD || "demo123456"
const { slot_orders: slotOrders } = prep

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
}

mkdirSync(outDir, { recursive: true })

async function loginBarista(page) {
  await page.goto(`${BASE}/login`, { waitUntil: "networkidle", timeout: 60000 })
  await page.locator('input[name="email"], input[name="user[email]"]').first().fill(BARISTA_EMAIL)
  await page.locator('input[name="password"], input[name="user[password]"]').first().fill(PASSWORD)
  await page.locator('input[type="submit"], button[type="submit"]').first().click()
  await page.waitForURL(/\/(barista|manager|platform)/, { timeout: 30000 })
}

async function ensureShiftOpen(page) {
  await page.goto(`${BASE}/barista`, { waitUntil: "networkidle", timeout: 60000 })
  if ((await page.locator("body").innerText()).includes("Смена открыта")) return true
  await page.goto(`${BASE}/barista/shift`, { waitUntil: "networkidle" })
  const openBtn = page.locator('input.btn-open-shift, button:has-text("Открыть смену")')
  if (await openBtn.count()) {
    await openBtn.click()
    await page.waitForURL(/\/barista/, { timeout: 30000 })
  }
  await page.goto(`${BASE}/barista`, { waitUntil: "networkidle" })
  return (await page.locator("body").innerText()).includes("Смена открыта")
}

async function waitForBoardCards(page, minCount = 1) {
  for (let attempt = 0; attempt < 8; attempt++) {
    const count = await page.locator("#barista-board-slots .board-slot-card").count()
    if (count >= minCount) return count
    await page.waitForTimeout(attempt === 0 ? 1500 : 2000)
    if (attempt % 2 === 1) await page.reload({ waitUntil: "networkidle" })
  }
  return page.locator("#barista-board-slots .board-slot-card").count()
}

async function createShopOrder(browser, label = "B21-LIVE") {
  const ctx = await browser.newContext()
  await ctx.addCookies(
    prep.shop_cookies.map((c) => ({
      name: c.name,
      value: c.value,
      domain: c.domain,
      path: c.path || "/",
      secure: c.secure,
      httpOnly: c.httpOnly
    }))
  )
  const page = await ctx.newPage()
  await page.goto(prep.guest_base, { waitUntil: "networkidle", timeout: 60000 })
  const result = await page.evaluate(
    async ({ apiKey, tenantId, productId, email, label }) => {
      const headers = {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-Shop-Tenant": tenantId,
        "X-Shop-Api-Key": apiKey
      }
      await fetch("/shop/api/cart/add", {
        method: "POST",
        credentials: "same-origin",
        headers,
        body: JSON.stringify({ product_id: productId, quantity: 1, selected_modifiers: [] })
      })
      const res = await fetch("/shop/api/orders", {
        method: "POST",
        credentials: "same-origin",
        headers,
        body: JSON.stringify({ email, name: label, payment_method: "cash" })
      })
      const body = await res.json()
      return { ok: res.ok, status: body.status, order_id: body.order_id }
    },
    {
      apiKey: prep.api_key,
      tenantId: prep.tenant_id,
      productId: prep.product_id,
      email: prep.vitrina_email,
      label
    }
  )
  await ctx.close()
  return result
}

const browser = await chromium.launch({ headless: true })
const barista = await browser.newPage({ viewport: { width: 1280, height: 900 } })
let allPass = true

try {
  await loginBarista(barista)
  const shiftOk = await ensureShiftOpen(barista)
  step("shift_open", "Смена открыта demo A", shiftOk)
  allPass &&= shiftOk

  await barista.goto(`${BASE}/barista`, { waitUntil: "networkidle" })
  await barista.waitForSelector("turbo-cable-stream-source[connected]", { state: "attached", timeout: 15000 })
  await barista.waitForTimeout(2500)

  const bodyText = await barista.locator("body").innerText()
  const noKanban =
    !(await barista.locator("#orders-new, #orders-preparing, #orders-ready").count()) &&
    !bodyText.includes("Перетащите карточку")
  const hasGrid = await barista.locator("#barista-board-slots.board-grid, #barista-board-slots .board-grid").count()
  const gridOk = (await barista.locator("#barista-board-slots").count()) > 0 && noKanban
  step("no_kanban_columns", "Нет 3 колонок НОВЫЕ/ГОТОВИТСЯ/ГОТОВЫ — только board-grid", gridOk, {
    has_barista_board_slots: true,
    legacy_kanban_ids: noKanban
  })
  allPass &&= gridOk

  const cardCount = await waitForBoardCards(barista, Math.min(slotOrders.length, 6))
  const sixSlotsOk = cardCount >= 6
  const slotCells = await barista.locator("#barista-board-slots .board-slot").count()
  await barista.screenshot({ path: join(outDir, "01_board_6_slots_fly.png"), fullPage: true })
  step("board_6_slots", `1.1 — сетка 2×3, ${cardCount} карточек, ${slotCells} слотов`, sixSlotsOk && slotCells === 6, {
    screenshot: "01_board_6_slots_fly.png",
    cards_visible: cardCount,
    slot_cells: slotCells
  })
  allPass &&= sixSlotsOk && slotCells === 6

  const tapCard = barista.locator("#barista-board-slots .board-slot-card--accepted").first()
  await tapCard.waitFor({ state: "visible", timeout: 30000 })
  const tapDomId = await tapCard.getAttribute("id")
  const whiteClass = await tapCard.getAttribute("class")
  const whiteOk = whiteClass?.includes("board-slot-card--accepted")
  await tapCard.screenshot({ path: join(outDir, "02_tap_white_accepted_fly.png") })
  step("tap_white", "1.2 — белая карточка (accepted)", whiteOk, {
    screenshot: "02_tap_white_accepted_fly.png",
    class: whiteClass,
    order_dom_id: tapDomId
  })
  allPass &&= whiteOk

  await tapCard.locator(".board-slot-tap").click()
  await barista.locator(`#${tapDomId}.board-slot-card--preparing`).waitFor({ state: "visible", timeout: 10000 })
  const yellowCard = barista.locator(`#${tapDomId}`)
  const yellowClass = await yellowCard.getAttribute("class")
  const yellowOk = yellowClass?.includes("board-slot-card--preparing")
  await barista.screenshot({ path: join(outDir, "03_tap_yellow_preparing_fly.png"), fullPage: true })
  await yellowCard.screenshot({ path: join(outDir, "03_tap_yellow_card_fly.png") })
  step("tap_yellow", "1.2 — жёлтая (preparing)", yellowOk, {
    screenshots: ["03_tap_yellow_preparing_fly.png", "03_tap_yellow_card_fly.png"],
    class: yellowClass
  })
  allPass &&= yellowOk

  await yellowCard.locator(".board-slot-tap").click()
  await barista.locator(`#${tapDomId}`).waitFor({ state: "hidden", timeout: 10000 })
  const goneOk = !(await barista.locator(`#${tapDomId}`).isVisible().catch(() => false))
  await barista.screenshot({ path: join(outDir, "04_tap_ready_gone_fly.png"), fullPage: true })
  step("tap_gone", "1.2 — ready, карточка ушла", goneOk, { screenshot: "04_tap_ready_gone_fly.png" })
  allPass &&= goneOk

  await barista.screenshot({ path: join(outDir, "05_live_before_fly.png"), fullPage: true })
  const cardsBeforeLive = await barista.locator("#barista-board-slots .board-slot-card").count()
  step("live_before", "1.3 — табло без reload перед live", true, {
    screenshot: "05_live_before_fly.png",
    cards_before: cardsBeforeLive
  })

  const liveStart = Date.now()
  const live = await createShopOrder(browser, "B21-LIVE")
  const liveDomId = live.order_id ? `order_${live.order_id}` : null
  let liveOk = false
  if (liveDomId) {
    for (let i = 0; i < 30; i++) {
      if (await barista.locator(`#${liveDomId}`).isVisible().catch(() => false)) {
        liveOk = true
        break
      }
      const countNow = await barista.locator("#barista-board-slots .board-slot-card").count()
      if (countNow > cardsBeforeLive) {
        liveOk = true
        break
      }
      await barista.waitForTimeout(500)
    }
  }
  const liveMs = Date.now() - liveStart
  await barista.screenshot({ path: join(outDir, "06_live_new_order_fly.png"), fullPage: true })
  step("live_new_order", `1.3 — live без F5 (${liveMs}ms)`, liveOk && live.ok, {
    screenshot: "06_live_new_order_fly.png",
    live_ms: liveMs,
    order_id: live.order_id
  })
  allPass &&= liveOk && live.ok

  const countBefore7 = await barista.locator("#barista-board-slots .board-slot-card").count()
  const seventh = await createShopOrder(browser, "B21-LIMIT7")
  await barista.waitForTimeout(3000)
  const countAfter7 = await barista.locator("#barista-board-slots .board-slot-card").count()
  const seventhDom = seventh.order_id ? `order_${seventh.order_id}` : null
  const seventhVisible =
    seventhDom && (await barista.locator(`#${seventhDom}`).isVisible().catch(() => false))
  const limitOk = countBefore7 <= 6 && countAfter7 <= 6 && !seventhVisible
  await barista.screenshot({ path: join(outDir, "07_limit_6_full_board_fly.png"), fullPage: true })
  step("limit_6_slots", "1.4 — 7-й заказ не на табло (лимит 6)", limitOk, {
    screenshot: "07_limit_6_full_board_fly.png",
    cards_before_7th: countBefore7,
    cards_after_7th: countAfter7,
    seventh_order_visible: seventhVisible,
    seventh_order_id: seventh.order_id
  })
  allPass &&= limitOk
} catch (e) {
  step("step_error", e.message, false, { error: String(e) })
  await barista.screenshot({ path: join(outDir, "99_error_fly.png"), fullPage: true }).catch(() => {})
  allPass = false
} finally {
  await browser.close()
}

const result = {
  task: "B21_revision_customer_mcp",
  tool: "playwright (customer acceptance path; devtools login HTTP 500 on Fly)",
  stand: BASE,
  started_at: startedAt,
  finished_at: new Date().toISOString(),
  screen_dir: prep.screen_dir,
  steps,
  status: allPass ? "PASS" : "FAIL"
}

writeFileSync(join(root, "tmp/b21_revision_customer_mcp.json"), JSON.stringify(result, null, 2))
console.log(JSON.stringify(result, null, 2))
process.exit(allPass ? 0 : 1)
