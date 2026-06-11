#!/usr/bin/env node
/**
 * B2.1 stage3 — скрины экрана гостя (preparing / ready) на Fly.
 *   node bin/b21_stage3_guest_screenshots.mjs
 * Требует: tmp/b21_stage3_guest_prep.json (bin/b21_stage3_guest_screenshots_prep.rb)
 */
import { readFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const prep = JSON.parse(readFileSync(join(root, "tmp/b21_stage3_guest_prep.json"), "utf8"))
const outDir =
  process.env.SCREEN_DIR ||
  join(
    root,
    "docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b21_barista_board_2026-06-10"
  )

mkdirSync(outDir, { recursive: true })

const { order_id: orderId, reconnect_token: token, guest_base: guestBase, subtitles } = prep

async function openGuestOrder(page) {
  await page.addInitScript(
    ({ orderId, token }) => {
      sessionStorage.setItem("shop_last_order_id", orderId)
      sessionStorage.setItem("shop_reconnect_token", token)
    },
    { orderId, token }
  )
  await page.goto(`${guestBase}#/order/${orderId}`, { waitUntil: "networkidle", timeout: 60000 })
  await page.waitForSelector(".status-subtitle, .status-title, .error-text", { timeout: 30000 })
}

async function setBaristaStatus(status) {
  const { execSync } = await import("node:child_process")
  execSync(`ruby bin/b21_stage3_fly_status.rb ${status}`, { stdio: "inherit", cwd: root })
}

const browser = await chromium.launch({ headless: true })
const page = await browser.newPage({ viewport: { width: 390, height: 844 } })

try {
  await openGuestOrder(page)
  await page.locator(".status-subtitle", { hasText: subtitles.preparing }).waitFor({
    timeout: 30000
  })
  const prepText = await page.locator(".status-subtitle").innerText()
  await page.screenshot({
    path: join(outDir, "stage3_guest_preparing.png"),
    fullPage: true
  })
  console.log("saved stage3_guest_preparing.png")

  await setBaristaStatus("ready")
  await page.reload({ waitUntil: "networkidle" })
  await page.locator(".status-subtitle", { hasText: subtitles.ready }).waitFor({
    timeout: 30000
  })
  const readyText = await page.locator(".status-subtitle").innerText()
  await page.screenshot({
    path: join(outDir, "stage3_guest_ready.png"),
    fullPage: true
  })
  console.log("saved stage3_guest_ready.png")
} finally {
  await browser.close()
}
