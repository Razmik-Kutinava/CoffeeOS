#!/usr/bin/env node
/**
 * B2.1 MCP e2e Fly — витрина → бариста (UI) → гость (WS).
 *   node bin/acceptance/b21_mcp_e2e_fly.mjs
 * Требует: tmp/b21_mcp_e2e_prep.json
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..", "..")
const prep = JSON.parse(readFileSync(join(root, "tmp/b21_mcp_e2e_prep.json"), "utf8"))
const outDir = join(root, prep.screen_dir)
const steps = []
const startedAt = new Date().toISOString()

const {
  base: BASE,
  barista_email: BARISTA_EMAIL,
  order_id: orderId,
  order_dom_id: orderDomId,
  reconnect_token: token,
  guest_base: guestBase,
  subtitles
} = prep

const PASSWORD = process.env.STAFF_PASSWORD || "demo123456"

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
}

mkdirSync(outDir, { recursive: true })

async function loginBarista(page) {
  await page.goto(`${BASE}/login`, { waitUntil: "networkidle", timeout: 60000 })
  const emailSel = 'input[name="email"], input[name="user[email]"]'
  const passSel = 'input[name="password"], input[name="user[password]"]'
  await page.locator(emailSel).first().fill(BARISTA_EMAIL)
  await page.locator(passSel).first().fill(PASSWORD)
  await page.locator('input[type="submit"], button[type="submit"]').first().click()
  await page.waitForURL(/\/(barista|manager|platform)/, { timeout: 30000 })
}

async function ensureShiftOpen(page) {
  await page.goto(`${BASE}/barista`, { waitUntil: "networkidle", timeout: 60000 })
  const body = await page.locator("body").innerText()
  if (body.includes("Смена открыта")) return true

  await page.goto(`${BASE}/barista/shift`, { waitUntil: "networkidle", timeout: 60000 })
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
  const reconnectOk = await page.evaluate(
    async ({ orderId, token, tid }) => {
      sessionStorage.setItem("shop_last_order_id", orderId)
      sessionStorage.setItem("shop_reconnect_token", token)
      const csrf = document.querySelector('meta[name="csrf-token"]')?.content || ""
      const apiKey = document.querySelector('meta[name="shop-api-key"]')?.content || ""
      const res = await fetch(`/shop/api/session/reconnect?tenant_id=${tid}`, {
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
      const body = await res.json().catch(() => ({}))
      return { ok: res.ok, status: body.status || body.ok }
    },
    { orderId, token, tid: prep.tenant_id }
  )
  await page.goto(`${guestBase}#/order/${orderId}`, { waitUntil: "networkidle", timeout: 60000 })
  await page.waitForSelector(".status-title, .error-text", { timeout: 30000 })
  return reconnectOk
}

const browser = await chromium.launch({ headless: true })
const guest = await browser.newPage({ viewport: { width: 390, height: 844 } })
const barista = await browser.newPage({ viewport: { width: 1280, height: 900 } })

let allPass = true

try {
  // Step 1 — vitrina
  await guest.goto(guestBase, { waitUntil: "networkidle", timeout: 60000 })
  const catalogOk = (await guest.locator("body").innerText()).length > 50
  await guest.screenshot({ path: join(outDir, "stage5_e2e_vitrina_checkout.png"), fullPage: true })
  step(
    "step1_vitrina_catalog",
    "GET /shop каталог + скрин stage5_e2e_vitrina_checkout.png",
    catalogOk,
    { screenshot: "stage5_e2e_vitrina_checkout.png" }
  )
  allPass &&= catalogOk

  const reconnectOk = await openGuest(guest)
  const acceptedTitle = await guest.locator(".status-title").innerText().catch(() => "")
  const orderAccepted =
    reconnectOk?.ok !== false &&
    (acceptedTitle.includes("Оплачен") || acceptedTitle.includes("Принят") || acceptedTitle.includes("Готовится"))
  step(
    "step1_vitrina_order_accepted",
    "Заказ accepted на экране гостя (prep API + OTP)",
    orderAccepted,
    { order_id: orderId, status_title: acceptedTitle }
  )
  allPass &&= orderAccepted

  // Step 2 — barista board
  await loginBarista(barista)
  const shiftOk = await ensureShiftOpen(barista)
  step("step2_shift_open", "Открытая смена на demo A", shiftOk)
  allPass &&= shiftOk

  await barista.goto(`${BASE}/barista`, { waitUntil: "networkidle" })
  const card = barista.locator(`#${orderDomId}`)
  await card.waitFor({ state: "visible", timeout: 30000 })
  const onBoard = await card.isVisible()
  await barista.screenshot({ path: join(outDir, "stage5_e2e_vitrina_to_board.png"), fullPage: true })
  step(
    "step2_barista_board",
    `Карточка ${orderDomId} в НОВЫЕ + скрин`,
    onBoard,
    { screenshot: "stage5_e2e_vitrina_to_board.png", order_dom_id: orderDomId }
  )
  allPass &&= onBoard

  // Step 3 — barista UI → preparing
  const prepBtn = card.locator('button.card-btn-status, input.card-btn-status').filter({ hasText: "ГОТОВИТСЯ" })
  await prepBtn.first().click()
  await barista.locator(`#orders-preparing #${orderDomId}`).waitFor({ state: "visible", timeout: 15000 })
  const inPreparing = await barista.locator(`#orders-preparing #${orderDomId}`).isVisible()
  await barista.screenshot({ path: join(outDir, "stage5_e2e_barista_preparing.png"), fullPage: true })
  step(
    "step3_barista_preparing_ui",
    "Клик ГОТОВИТСЯ → карточка в PREPARING (turbo)",
    inPreparing,
    { screenshot: "stage5_e2e_barista_preparing.png" }
  )
  allPass &&= inPreparing

  // Step 4 — guest preparing (WS ≤5s, no reload)
  const guestTitleBefore = await guest.locator(".status-title").innerText().catch(() => "")
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
  await guest.screenshot({ path: join(outDir, "stage5_e2e_guest_preparing.png"), fullPage: true })
  const prepSubtitle = await guest.locator(".status-subtitle").innerText().catch(() => "")
  step(
    "step4_guest_preparing_ws",
    "Подзаголовок «Ваш заказ начали готовить» без reload ≤5с",
    wsOk && prepSubtitle.includes(subtitles.preparing),
    {
      ws_ms: wsMs,
      title_before: guestTitleBefore,
      subtitle: prepSubtitle,
      screenshots: ["stage3_guest_preparing.png", "stage5_e2e_guest_preparing.png"]
    }
  )
  allPass &&= wsOk && prepSubtitle.includes(subtitles.preparing)

  // Step 5 — barista UI → ready
  const readyCard = barista.locator(`#orders-preparing #${orderDomId}`)
  const readyBtn = readyCard.locator('button.card-btn-status, input.card-btn-status').filter({ hasText: "ГОТОВ" })
  await readyBtn.first().click()
  await barista.locator(`#orders-ready #${orderDomId}`).waitFor({ state: "visible", timeout: 15000 })
  const inReady = await barista.locator(`#orders-ready #${orderDomId}`).isVisible()
  await barista.screenshot({ path: join(outDir, "stage5_e2e_barista_ready.png"), fullPage: true })
  step(
    "step5_barista_ready_ui",
    "Клик ГОТОВ → карточка в READY",
    inReady,
    { screenshot: "stage5_e2e_barista_ready.png" }
  )
  allPass &&= inReady

  // Step 6 — guest ready WS
  const ws2Start = Date.now()
  let ws2Ok = false
  try {
    await guest.locator(".status-subtitle", { hasText: subtitles.ready }).waitFor({ timeout: 5000 })
    ws2Ok = true
  } catch {
    ws2Ok = false
  }
  const ws2Ms = Date.now() - ws2Start
  await guest.screenshot({ path: join(outDir, "stage3_guest_ready.png"), fullPage: true })
  await guest.screenshot({ path: join(outDir, "stage5_e2e_guest_ready.png"), fullPage: true })
  const readySubtitle = await guest.locator(".status-subtitle").innerText().catch(() => "")
  step(
    "step6_guest_ready_ws",
    "«Заказ готов, забирайте!» без reload ≤5с",
    ws2Ok && readySubtitle.includes(subtitles.ready),
    {
      ws_ms: ws2Ms,
      subtitle: readySubtitle,
      screenshots: ["stage3_guest_ready.png", "stage5_e2e_guest_ready.png"]
    }
  )
  allPass &&= ws2Ok && readySubtitle.includes(subtitles.ready)
} catch (e) {
  step("step_error", e.message, false, { error: String(e) })
  allPass = false
} finally {
  await browser.close()
}

const result = {
  task: "B2_1_mcp_e2e_fly",
  tool: "playwright (MCP-style browser e2e)",
  stand: BASE,
  started_at: startedAt,
  finished_at: new Date().toISOString(),
  order_id: orderId,
  order_dom_id: orderDomId,
  tenant_id: prep.tenant_id,
  barista_email: BARISTA_EMAIL,
  screen_dir: prep.screen_dir,
  steps,
  status: allPass ? "PASS" : "FAIL"
}

writeFileSync(join(root, "tmp/b21_mcp_e2e_steps.json"), JSON.stringify(result, null, 2))
console.log(JSON.stringify(result, null, 2))
process.exit(allPass ? 0 : 1)
