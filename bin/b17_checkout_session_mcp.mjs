#!/usr/bin/env node
/**
 * B1.7 баг-3 — checkout: повторный визит без «сессия истекла» (новый cookie, тот же email в localStorage).
 * Prep создаёт verified email в Fly БД; этот скрипт симулирует return visit.
 *
 *   ruby bin/b17_checkout_session_fly.rb
 *   node bin/b17_checkout_session_mcp.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const prepPath = join(root, "tmp/b17_checkout_session_prep.json")
const prep = JSON.parse(readFileSync(prepPath, "utf8"))
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

function profilePayload() {
  return {
    name: prep.name,
    email: prep.email,
    emailVerified: true
  }
}

async function run() {
  const browser = await chromium.launch({ headless: true })
  let pass = true

  try {
    const ctx = await browser.newContext()
    const page = await ctx.newPage()
    await page.addInitScript(
      ({ key, profile }) => {
        localStorage.setItem(key, JSON.stringify(profile))
      },
      { key: prep.profile_storage_key, profile: profilePayload() }
    )
    await page.goto(`${prep.shop_url}${prep.checkout_hash}`, { waitUntil: "networkidle", timeout: 60000 })
    await page.waitForTimeout(3000)

    const bodyText = await page.locator("body").innerText()
    const hasExpired = /сессия истекла/i.test(bodyText)
    const hasContacts = /Контакты/i.test(bodyText) && new RegExp(prep.name).test(bodyText)
    const payEnabled = await page.locator('button:has-text("Оплатить")').isEnabled().catch(() => false)

    await page.screenshot({ path: join(outDir, "01_return_visit_no_session_expired.png"), fullPage: true })

    pass =
      step("01", "no «сессия истекла» on return visit (new browser session)", !hasExpired, { hasExpired }) &&
      step("02", "contacts block or pay enabled after email restore", hasContacts || payEnabled, {
        hasContacts,
        payEnabled
      }) &&
      pass
  } finally {
    await browser.close()
  }

  const artifact = {
    task: prep.task,
    date: prep.date,
    status: pass ? "PASS" : "FAIL",
    verdict: pass ? "PASS" : "FAIL",
    base: prep.base,
    email: prep.email,
    fix: {
      root_cause: "OTP verification bound only to session_id; mobile browsers rotate cookies",
      files: [
        "app/services/shop/email_verification.rb",
        "app/models/shop_email_verification.rb",
        "app/controllers/shop/api/email_otp_controller.rb",
        "app/services/shop/order_creator.rb",
        "app/frontend/routes/Checkout.svelte"
      ]
    },
    playwright: {
      script: "bin/b17_checkout_session_mcp.mjs",
      steps,
      started_at: startedAt,
      finished_at: new Date().toISOString()
    },
    screen_dir: prep.screen_dir
  }

  writeFileSync(join(root, prep.artifact), JSON.stringify(artifact, null, 2))
  console.log(`Artifact: ${prep.artifact}`)
  if (!pass) process.exit(1)
}

run().catch((e) => {
  console.error(e)
  process.exit(1)
})
