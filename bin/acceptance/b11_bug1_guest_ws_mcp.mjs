#!/usr/bin/env node
/**
 * B1.1 баг-1 — guest WS без F5 после тапа баристы (Playwright; MCP DevTools — см. bin/acceptance/b11_bug1_guest_ws_fly.rb).
 *   node bin/acceptance/b11_bug1_guest_ws_mcp.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..", "..")
const prep = JSON.parse(readFileSync(join(root, "tmp/b11_bug1_guest_ws_prep.json"), "utf8"))
const outDir = join(root, prep.screen_dir)
mkdirSync(outDir, { recursive: true })

const steps = []
const startedAt = new Date().toISOString()

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
}

async function loginBarista(page) {
  await page.goto(`${prep.base}/login`, { waitUntil: "networkidle", timeout: 60000 })
  await page.locator('input[name="email"], input[name="user[email]"]').first().fill(prep.barista_email)
  await page.locator('input[name="password"], input[name="user[password]"]').first().fill(prep.barista_password)
  await page.locator('input[type="submit"], button[type="submit"]').first().click()
  await page.waitForURL(/\/(barista|manager|platform)/, { timeout: 30000 })
}

async function ensureShift(page) {
  await page.goto(`${prep.base}/barista`, { waitUntil: "networkidle", timeout: 60000 })
  if ((await page.locator("body").innerText()).includes("Смена открыта")) return true
  await page.goto(`${prep.base}/barista/shift`, { waitUntil: "networkidle" })
  const btn = page.locator('input.btn-open-shift, button:has-text("Открыть смену")')
  if (await btn.count()) {
    await btn.first().click()
    await page.waitForURL(/\/barista/, { timeout: 30000 })
  }
  await page.goto(`${prep.base}/barista`, { waitUntil: "networkidle" })
  return (await page.locator("body").innerText()).includes("Смена открыта")
}

async function openGuestWithStaleToken(page) {
  await page.goto(prep.guest_base, { waitUntil: "networkidle", timeout: 60000 })
  const stale = prep.stale_reconnect_token || "stale-token-for-repro"
  await page.evaluate(
    async ({ orderId, token, staleToken, tid }) => {
      sessionStorage.setItem("shop_last_order_id", orderId)
      sessionStorage.setItem("shop_reconnect_token", staleToken)
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
    {
      orderId: prep.order_id,
      token: prep.reconnect_token,
      staleToken: stale,
      tid: prep.tenant_id
    }
  )
  await page.goto(prep.guest_url, { waitUntil: "networkidle", timeout: 60000 })
  await page.waitForSelector(".status-title, .error-text", { timeout: 30000 })
  if (await page.locator(".error-text").count()) {
    throw new Error(await page.locator(".error-text").first().innerText())
  }
}

const browser = await chromium.launch({ headless: true })
const guest = await browser.newPage({ viewport: { width: 390, height: 844 } })
const barista = await browser.newPage({ viewport: { width: 1280, height: 900 } })

let allPass = true

try {
  await openGuestWithStaleToken(guest)
  const titleBefore = await guest.locator(".status-title").innerText()
  await guest.screenshot({ path: join(outDir, "01_guest_before_tap.png"), fullPage: true })
  step(
    "guest_open_stale_token",
    "Гость на экране статуса со stale reconnect_token в sessionStorage",
    titleBefore.includes("Оплачен") || titleBefore.includes("Принят"),
    { title_before: titleBefore }
  )

  await loginBarista(barista)
  allPass &&= step("barista_login", "Login barista demo A", true)
  allPass &&= step("barista_shift", "Смена открыта", await ensureShift(barista))

  await barista.goto(`${prep.base}/barista`, { waitUntil: "networkidle" })
  const card = barista.locator(`#${prep.order_dom_id}`)
  await card.waitFor({ state: "visible", timeout: 30000 })
  await barista.screenshot({ path: join(outDir, "02_barista_board_before_tap.png"), fullPage: true })
  allPass &&= step("barista_card_visible", "Карточка заказа на табло", await card.isVisible())

  const tapBtn = card.locator("button.board-slot-tap, form.board-slot-tap-form button").first()
  await tapBtn.click()
  await barista.waitForTimeout(1500)
  await barista.screenshot({ path: join(outDir, "03_barista_after_tap.png"), fullPage: true })

  const wsStart = Date.now()
  let wsOk = false
  try {
    await guest.waitForFunction(
      () => {
        const el = document.querySelector(".status-title")
        return el && (el.textContent.includes("Готовится") || el.textContent.includes("Готов"))
      },
      { timeout: 8000 }
    )
    wsOk = true
  } catch {
    wsOk = false
  }
  const wsMs = Date.now() - wsStart
  const titleAfter = await guest.locator(".status-title").innerText()
  await guest.screenshot({ path: join(outDir, "04_guest_after_tap_no_reload.png"), fullPage: true })

  allPass &&= step(
    "guest_ws_preparing_no_reload",
    "Статус гостя → Готовится/Готов без F5 ≤8с после тапа баристы",
    wsOk && (titleAfter.includes("Готовится") || titleAfter.includes("Готов")),
    { ws_ms: wsMs, title_before: titleBefore, title_after: titleAfter }
  )
} finally {
  await browser.close()
}

const result = {
  task: "B1_1_bug1_guest_ws",
  date: prep.date,
  method: "playwright_dual_tab_stale_token",
  status: allPass ? "PASS" : "FAIL",
  verdict: allPass ? "PASS" : "FAIL",
  started_at: startedAt,
  finished_at: new Date().toISOString(),
  prep: "tmp/b11_bug1_guest_ws_prep.json",
  screen_dir: prep.screen_dir,
  steps
}

writeFileSync(join(root, "tmp/b11_bug1_guest_ws_mcp.json"), JSON.stringify(result, null, 2))
writeFileSync(
  join(root, `docs/operations/milestones/veha_2/artifacts/demo-feedback/b11_bug1_guest_ws_${prep.date}.json`),
  JSON.stringify(result, null, 2)
)
console.log(JSON.stringify(result, null, 2))
process.exit(allPass ? 0 : 1)
