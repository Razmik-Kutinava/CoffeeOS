#!/usr/bin/env node
/**
 * B2.1 B2-S1 — звук нового заказа на табло (Playwright + window.BaristaOrderSound).
 *
 *   FLY_BIN=flyctl ruby bin/b21_s1_sound_prep_fly.rb
 *   node bin/b21_s1_sound_mcp.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const prep = JSON.parse(readFileSync(join(root, "tmp/b21_s1_sound_prep.json"), "utf8"))

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const screenshotDir = join(root, prep.screen_dir)
const date = prep.date || new Date().toISOString().slice(0, 10)
const postPath = join(artifactDir, `b21_s1_sound_post_deploy_${date}.json`)

const BASE = prep.base
const BARISTA_EMAIL = prep.barista_email
const PASSWORD = process.env.STAFF_PASSWORD || "demo123456"
const BANNER_TEXT = "Звук заблокирован. Кликните по экрану для включения"

const steps = []
const startedAt = new Date().toISOString()

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
}

mkdirSync(screenshotDir, { recursive: true })
mkdirSync(artifactDir, { recursive: true })

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

async function createShopOrder(browser, label) {
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

async function waitSoundPlay(page, baseline, timeoutMs = 15000) {
  const started = Date.now()
  while (Date.now() - started < timeoutMs) {
    const state = await page.evaluate(() => window.BaristaOrderSound?.debugState?.() || null)
    if (state && state.playCount > baseline && state.lastPlayLatencyMs != null) {
      return state
    }
    await page.waitForTimeout(400)
  }
  return page.evaluate(() => window.BaristaOrderSound?.debugState?.() || null)
}

const browser = await chromium.launch({ headless: true })
let allPass = true

try {
  const barista = await browser.newPage({ viewport: { width: 1280, height: 900 } })

  const audioRes = await barista.goto(`${BASE}${prep.audio_path}`, { waitUntil: "domcontentloaded", timeout: 30000 })
  allPass &= step("audio_asset", `GET ${prep.audio_path}`, audioRes?.ok() === true, {
    status: audioRes?.status()
  })

  await loginBarista(barista)
  allPass &= step("barista_login", `Login ${BARISTA_EMAIL}`, true)

  const shiftOk = await ensureShiftOpen(barista)
  allPass &= step("shift_open", "Смена открыта", shiftOk)

  await barista.goto(`${BASE}/barista`, { waitUntil: "networkidle" })
  await barista.waitForSelector("#barista-board-slots", { timeout: 30000 })

  const hasController = await barista.evaluate(() => typeof window.BaristaOrderSound !== "undefined")
  allPass &= step("sound_module", "window.BaristaOrderSound на табло", hasController)

  await barista.click(".barista-layout", { position: { x: 400, y: 300 } })
  await barista.waitForTimeout(500)

  const unlocked = await barista.evaluate(() => window.BaristaOrderSound?.unlocked === true)
  allPass &= step("audio_unlock", "AudioContext разблокирован кликом", unlocked)

  await barista.screenshot({ path: join(screenshotDir, "01_board_unlocked.png"), fullPage: true })

  const baseline = await barista.evaluate(() => window.BaristaOrderSound?.playCount || 0)
  const beforeCards = await barista.locator("#barista-board-slots .board-slot-card").count()

  const order = await createShopOrder(browser, `B21-S1-${Date.now()}`)
  allPass &= step("shop_order", "Новый заказ accepted с витрины", order.ok && order.status === "accepted", order)

  let cardAppeared = false
  for (let i = 0; i < 20; i++) {
    const count = await barista.locator("#barista-board-slots .board-slot-card").count()
    if (count > beforeCards) {
      cardAppeared = true
      break
    }
    await barista.waitForTimeout(500)
  }
  allPass &= step("live_card", "Карточка на табло без F5", cardAppeared)

  const playState = await waitSoundPlay(barista, baseline)
  const played = playState && playState.playCount > baseline
  const latencyOk = played && playState.lastPlayLatencyMs <= 1000
  allPass &= step("sound_play", "Звук после нового заказа", played, {
    playCount: playState?.playCount,
    latencyMs: playState?.lastPlayLatencyMs
  })
  allPass &= step("sound_latency", "Задержка play ≤ 1000 ms", latencyOk, {
    latencyMs: playState?.lastPlayLatencyMs
  })

  await barista.screenshot({ path: join(screenshotDir, "02_new_order_sound.png"), fullPage: true })

  const blockedTest = await barista.evaluate(async (bannerText) => {
    sessionStorage.removeItem("barista_sound_unlocked")
    const s = window.BaristaOrderSound
    if (!s) return { ok: false, reason: "no module" }
    s.unlocked = false
    s.setBlocked(false)
    await s.playNewOrder()
    const banner = document.getElementById("barista-sound-blocked-banner")
    const visible = banner && !banner.hidden && banner.textContent.includes(bannerText)
    return { ok: visible, bannerHidden: banner?.hidden, text: banner?.textContent?.trim() }
  }, BANNER_TEXT)
  allPass &= step("blocked_banner", `Баннер NotAllowed: «${BANNER_TEXT}»`, blockedTest.ok, blockedTest)

  await barista.screenshot({ path: join(screenshotDir, "03_blocked_banner.png"), fullPage: true })

  await barista.click("#barista-sound-blocked-banner")
  await barista.waitForTimeout(400)
  const reUnlocked = await barista.evaluate(() => window.BaristaOrderSound?.unlocked === true)
  allPass &= step("banner_click_unlock", "Клик по баннеру разблокирует звук", reUnlocked)

  const artifact = {
    scenario: "b21_s1_sound_notification",
    task_id: "B2-S1",
    stand: BASE,
    tenant_id: prep.tenant_id,
    date,
    pass: Boolean(allPass),
    verdict: allPass ? "PASS" : "FAIL",
    tool: "playwright (barista board sound; chrome-devtools path equivalent)",
    devtools_note: {
      tool: "chrome-devtools-mcp",
      note: "Acceptance via Playwright + window.BaristaOrderSound.debugState(); same UX path as manual DevTools console check"
    },
    started_at: startedAt,
    finished_at: new Date().toISOString(),
    steps,
    screenshots: [
      `${prep.screen_dir}/01_board_unlocked.png`,
      `${prep.screen_dir}/02_new_order_sound.png`,
      `${prep.screen_dir}/03_blocked_banner.png`
    ],
    ui_checks: {
      audio_asset_200: steps.find((s) => s.id === "audio_asset")?.pass === true,
      sound_module_present: hasController,
      unlock_on_gesture: unlocked,
      play_on_new_order: played,
      latency_under_1s: latencyOk,
      blocked_banner_text: blockedTest.ok
    }
  }

  writeFileSync(postPath, JSON.stringify(artifact, null, 2) + "\n")
  console.log(`\nArtifact: ${postPath}`)
  console.log(`Verdict: ${artifact.verdict}`)
  process.exit(allPass ? 0 : 1)
} catch (error) {
  console.error(error)
  writeFileSync(
    postPath,
    JSON.stringify(
      {
        scenario: "b21_s1_sound_notification",
        pass: false,
        verdict: "FAIL",
        error: String(error),
        steps,
        started_at: startedAt,
        finished_at: new Date().toISOString()
      },
      null,
      2
    ) + "\n"
  )
  process.exit(1)
} finally {
  await browser.close()
}
