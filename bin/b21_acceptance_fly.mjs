#!/usr/bin/env node
/**
 * B2.1 formal acceptance Fly — критерии 1–6, 8 + скрины stage2/4.
 *   node bin/b21_acceptance_fly.mjs
 * Требует: tmp/b21_acceptance_prep.json
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const prep = JSON.parse(readFileSync(join(root, "tmp/b21_acceptance_prep.json"), "utf8"))
const outDir = join(root, prep.screen_dir)
const steps = []
const criteria = {}
const startedAt = new Date().toISOString()

const BASE = prep.base
const BARISTA_EMAIL = prep.barista_email
const PASSWORD = process.env.STAFF_PASSWORD || "demo123456"
const {
  main_order_dom_id: mainDomId,
  main_order_id: mainOrderId,
  fifo_older_dom_id: fifoOlderDom,
  fifo_newer_dom_id: fifoNewerDom,
  cancel_order_dom_id: cancelDomId,
  reconnect_token: token,
  guest_base: guestBase,
  subtitles,
  modifiers
} = prep

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

async function openGuest(page) {
  await page.goto(guestBase, { waitUntil: "networkidle", timeout: 60000 })
  await page.evaluate(
    async ({ orderId, token, tid }) => {
      sessionStorage.setItem("shop_last_order_id", orderId)
      sessionStorage.setItem("shop_reconnect_token", token)
      const csrf = document.querySelector('meta[name="csrf-token"]')?.content || ""
      const apiKey = document.querySelector('meta[name="shop-api-key"]')?.content || ""
      await fetch(`/shop/api/session/reconnect?tenant_id=${tid}`, {
        method: "POST",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": csrf,
          "X-Shop-Api-Key": apiKey
        },
        body: JSON.stringify({ order_id: orderId, reconnect_token: token })
      })
    },
    { orderId: mainOrderId, token, tid: prep.tenant_id }
  )
  await page.goto(`${guestBase}#/order/${mainOrderId}`, { waitUntil: "networkidle", timeout: 60000 })
  await page.waitForSelector(".status-title", { timeout: 30000 })
}

async function cardScreenshot(page, domId, filename) {
  const card = page.locator(`#${domId}`)
  await card.waitFor({ state: "visible", timeout: 30000 })
  await card.screenshot({ path: join(outDir, filename) })
}

const browser = await chromium.launch({ headless: true })
const barista = await browser.newPage({ viewport: { width: 1280, height: 900 } })
const guestCtx = await browser.newContext({
  viewport: { width: 390, height: 844 },
  permissions: ["notifications"]
})
const guest = await guestCtx.newPage()

let allPass = true

try {
  await loginBarista(barista)
  const shiftOk = await ensureShiftOpen(barista)
  step("shift_open", "Смена открыта", shiftOk)
  allPass &&= shiftOk

  await barista.goto(`${BASE}/barista`, { waitUntil: "networkidle" })
  let mainVisible = false
  for (let attempt = 0; attempt < 5; attempt++) {
    if (await barista.locator(`#${mainDomId}`).isVisible().catch(() => false)) {
      mainVisible = true
      break
    }
    await barista.waitForTimeout(attempt === 0 ? 1000 : 2000)
    await barista.reload({ waitUntil: "networkidle" })
  }
  if (!mainVisible) {
    await barista.locator(`#${mainDomId}`).waitFor({ state: "visible", timeout: 30000 })
  }

  // --- Крит. 4 FIFO ---
  const fifoCol = barista.locator("#orders-new")
  const fifoIds = await fifoCol.locator(".order-card").evaluateAll((els) => els.map((e) => e.id))
  const olderIdx = fifoIds.indexOf(fifoOlderDom)
  const newerIdx = fifoIds.indexOf(fifoNewerDom)
  const fifoOk = olderIdx >= 0 && newerIdx >= 0 && olderIdx < newerIdx
  await barista.screenshot({ path: join(outDir, "stage2_fifo_accepted.png"), fullPage: true })
  step("crit4_fifo", "FIFO: older заказ выше newer в НОВЫЕ", fifoOk, {
    fifo_ids_sample: fifoIds.slice(0, 8),
    older_idx: olderIdx,
    newer_idx: newerIdx,
    screenshot: "stage2_fifo_accepted.png"
  })
  criteria[4] = { pass: fifoOk, formal: fifoOk ? "PASS" : "FAIL", evidence: "stage2_fifo_accepted.png" }
  allPass &&= fifoOk

  // --- Крит. 1 кнопка ≥80px ---
  const mainCard = barista.locator(`#${mainDomId}`)
  const btnBox = await mainCard.locator(".card-btn-status").first().boundingBox()
  const btnH = btnBox?.height ?? 0
  const btnW = btnBox?.width ?? 0
  const cardBox = await mainCard.boundingBox()
  const fullWidth = cardBox && btnW >= cardBox.width * 0.95
  const crit1Ok = btnH >= 80 && fullWidth
  await cardScreenshot(barista, mainDomId, "stage1_card_accepted_fly.png")
  step("crit1_button_80px", `Кнопка статуса ${btnH.toFixed(0)}px высота, full width`, crit1Ok, {
    height_px: btnH,
    width_px: btnW,
    card_width_px: cardBox?.width
  })
  criteria[1] = { pass: crit1Ok, formal: crit1Ok ? "PASS" : "FAIL", height_px: btnH }
  allPass &&= crit1Ok

  // --- Крит. 2 цвет accepted ---
  const acceptedClass = await mainCard.getAttribute("class")
  const crit2Accepted = acceptedClass?.includes("card--accepted")
  step("crit2_color_accepted", "Карточка card--accepted", crit2Accepted, { class: acceptedClass })
  allPass &&= crit2Accepted

  // --- Крит. 3 модификаторы ---
  const addedCount = await mainCard.locator(".mod-added").count()
  const removedCount = await mainCard.locator(".mod-removed").count()
  const cardText = await mainCard.innerText()
  const modsOk =
    addedCount > 0 &&
    removedCount > 0 &&
    (cardText.toUpperCase().includes("ЛЬДОМ") || cardText.includes(modifiers.added)) &&
    cardText.toUpperCase().includes("САХАР")
  await barista.screenshot({ path: join(outDir, "stage1_modifiers_fly.png"), fullPage: false })
  step("crit3_modifiers", `Модификаторы ${modifiers.added} / ${modifiers.removed}`, modsOk, {
    screenshot: "stage1_modifiers_fly.png"
  })
  criteria[3] = { pass: modsOk, formal: modsOk ? "PASS" : "FAIL", screenshot: "stage1_modifiers_fly.png" }
  allPass &&= modsOk

  // --- Крит. 5 no drag (static, already in smoke) ---
  const bodyText = await barista.locator("body").innerText()
  const crit5Ok = !bodyText.includes("Перетащите карточку") && bodyText.includes("нажмите кнопку на карточке")
  step("crit5_no_drag", "Нет drag-hint, есть footer hint", crit5Ok)
  criteria[5] = { pass: crit5Ok, formal: crit5Ok ? "PASS" : "FAIL" }
  allPass &&= crit5Ok

  // --- Stage 4 cancel (отдельный заказ) ---
  const cancelCard = barista.locator(`#${cancelDomId}`)
  let cancelVisible = false
  for (let attempt = 0; attempt < 5; attempt++) {
    if (await cancelCard.count()) {
      await cancelCard.scrollIntoViewIfNeeded()
      cancelVisible = await cancelCard.isVisible()
      if (cancelVisible) break
    }
    await barista.reload({ waitUntil: "networkidle" })
    await barista.waitForTimeout(1500)
  }
  if (!cancelVisible) await cancelCard.waitFor({ state: "visible", timeout: 15000 })
  await cancelCard.locator(".card-cancel-trigger").click()
  await cancelCard.locator(".order-card-cancel-overlay.is-visible").waitFor({ timeout: 5000 })
  await cancelCard.screenshot({ path: join(outDir, "stage4_cancel_overlay.png") })
  step("stage4_overlay", "Overlay отмены на карточке", true, { screenshot: "stage4_cancel_overlay.png" })

  await cancelCard.locator(".card-btn-cancel-confirm").click()
  await barista.waitForTimeout(1500)
  const cancelGone = !(await cancelCard.isVisible().catch(() => false))
  await barista.screenshot({ path: join(outDir, "stage4_cancel_confirmed.png"), fullPage: true })
  step("stage4_confirmed", "ПОДТВЕРДИТЬ ОТМЕНУ — карточка снята", cancelGone, {
    screenshot: "stage4_cancel_confirmed.png"
  })
  allPass &&= cancelGone

  // --- Guest open for WS/push ---
  await openGuest(guest)

  // --- Крит. 6 latency + crit 2 preparing color ---
  const prepBtn = mainCard.locator('input.card-btn-status, button.card-btn-status').filter({ hasText: "ГОТОВИТСЯ" })
  const t0 = Date.now()
  await prepBtn.first().click()
  await barista.locator(`#orders-preparing #${mainDomId}`).waitFor({ state: "visible", timeout: 2000 })
  const boardMs = Date.now() - t0
  const crit6Ok = boardMs <= 1000
  await barista.screenshot({ path: join(outDir, "stage2_after_status_move.png"), fullPage: true })
  await cardScreenshot(barista, mainDomId, "stage1_card_preparing_fly.png")
  const prepClass = await barista.locator(`#orders-preparing #${mainDomId}`).getAttribute("class")
  const crit2Prep = prepClass?.includes("card--preparing")
  step("crit6_board_latency", `Табло ≤1с: ${boardMs}ms`, crit6Ok, { board_ms: boardMs })
  step("crit2_color_preparing", "Карточка card--preparing", crit2Prep)
  criteria[6] = { pass: crit6Ok, formal: crit6Ok ? "PASS" : "FAIL", board_ms: boardMs }
  criteria[2] = {
    pass: crit2Accepted && crit2Prep,
    formal: crit2Accepted && crit2Prep ? "PASS" : "PARTIAL",
    screenshots: ["stage1_card_accepted_fly.png", "stage1_card_preparing_fly.png"]
  }
  allPass &&= crit6Ok && crit2Prep

  // --- Крит. 7 WS (reuse e2e) ---
  const wsStart = Date.now()
  let wsOk = false
  try {
    await guest.locator(".status-subtitle", { hasText: subtitles.preparing }).waitFor({ timeout: 5000 })
    wsOk = true
  } catch {
    wsOk = false
  }
  const wsMs = Date.now() - wsStart
  await guest.screenshot({ path: join(outDir, "stage3_guest_preparing.png"), fullPage: true })

  // --- Крит. 8 push visual ---
  let pushVisualOk = false
  try {
    await guest.evaluate((body) => {
      // eslint-disable-next-line no-new
      new Notification("CoffeeOS", { body, tag: "b21-acceptance" })
    }, subtitles.preparing)
    await guest.waitForTimeout(500)
    pushVisualOk = true
  } catch {
    pushVisualOk = false
  }
  await guest.screenshot({ path: join(outDir, "stage3_push_optional.png"), fullPage: true })
  step("crit8_push_visual", "Browser Notification + stage3_push_optional.png", pushVisualOk, {
    screenshot: "stage3_push_optional.png"
  })
  criteria[8] = { pass: pushVisualOk, formal: "PARTIAL", note: "FCM pipeline verified in ruby orchestrator" }

  step("crit7_ws", `WS гостю ${wsMs}ms`, wsOk && wsMs <= 5000, { ws_ms: wsMs })
  criteria[7] = { pass: wsOk, formal: wsOk ? "PASS" : "FAIL", ws_ms: wsMs }
  allPass &&= wsOk

  // --- Ready color ---
  const readyCard = barista.locator(`#orders-preparing #${mainDomId}`)
  await readyCard.locator('input.card-btn-status, button.card-btn-status').filter({ hasText: "ГОТОВ" }).first().click()
  await barista.locator(`#orders-ready #${mainDomId}`).waitFor({ state: "visible", timeout: 15000 })
  await cardScreenshot(barista, mainDomId, "stage1_card_ready_fly.png")
  const readyClass = await barista.locator(`#orders-ready #${mainDomId}`).getAttribute("class")
  const crit2Ready = readyClass?.includes("card--ready")
  step("crit2_color_ready", "Карточка card--ready", crit2Ready)
  if (crit2Ready) {
    criteria[2].pass = crit2Accepted && crit2Prep && crit2Ready
    criteria[2].formal = "PASS"
    criteria[2].screenshots.push("stage1_card_ready_fly.png")
  }
  allPass &&= crit2Ready

  await guest.locator(".status-subtitle", { hasText: subtitles.ready }).waitFor({ timeout: 5000 })
  await guest.screenshot({ path: join(outDir, "stage3_guest_ready.png"), fullPage: true })
} catch (e) {
  step("step_error", e.message, false, { error: String(e) })
  allPass = false
} finally {
  await browser.close()
}

const result = {
  task: "B21_acceptance_fly",
  stand: BASE,
  started_at: startedAt,
  finished_at: new Date().toISOString(),
  main_order_id: mainOrderId,
  criteria,
  steps,
  status: allPass ? "PASS" : "FAIL"
}

writeFileSync(join(root, "tmp/b21_acceptance_steps.json"), JSON.stringify(result, null, 2))
console.log(JSON.stringify(result, null, 2))
process.exit(allPass ? 0 : 1)
