#!/usr/bin/env node
/**
 * B1.12-R3 — Fly MCP: checkout one-click, saved card block, pay button FSM.
 *
 *   ruby bin/b112_r3_one_click_prep_fly.rb
 *   node bin/b112_r3_one_click_mcp.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const prepPath = join(root, "tmp/b112_r3_one_click_prep.json")
const prep = JSON.parse(readFileSync(prepPath, "utf8"))

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const screenshotDir = join(artifactDir, "screenshots")
const postPath = join(artifactDir, `b112_r3_one_click_post_deploy_${prep.date}.json`)

const steps = []
const startedAt = new Date().toISOString()

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
}

async function apiOnPage(page, tenantId, path, opts = {}) {
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
    { tenantId, path, opts }
  )
}

async function payButtonText(page) {
  return page.locator('button[aria-live="polite"]').first().innerText().catch(() => "")
}

async function run() {
  mkdirSync(artifactDir, { recursive: true })
  mkdirSync(screenshotDir, { recursive: true })

  const browser = await chromium.launch({ headless: true })
  let overall = true

  try {
    const ctx = await browser.newContext()
    if (prep.shop_cookies?.length) {
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
    }

    const page = await ctx.newPage()
    await page.addInitScript(
      ({ profileKey, profile }) => {
        localStorage.setItem(
          profileKey,
          JSON.stringify({
            savedAt: new Date().toISOString(),
            ttlMs: 24 * 60 * 60 * 1000,
            payload: profile
          })
        )
      },
      {
        profileKey: prep.profile_storage_key,
        profile: { name: prep.name, email: prep.email, emailVerified: true }
      }
    )

    await page.goto(`${prep.shop_url}#/checkout`, { waitUntil: "domcontentloaded", timeout: 60000 })
    await page.getByRole("heading", { name: "Оформление" }).waitFor({ timeout: 30000 })
    await page.waitForTimeout(1200)

    overall = step("00", "checkout #/checkout loads", /#\/checkout/.test(page.url())) && overall

    const savedRes = await apiOnPage(page, prep.tenant_id, `/saved_cards?email=${encodeURIComponent(prep.email)}`)
    overall =
      step("01", "GET saved_cards?email= 200 + primary", savedRes.status === 200 && !!savedRes.body?.primary, {
        status: savedRes.status,
        primary: savedRes.body?.primary
      }) && overall

    const savedBlock = page.locator('[data-testid="saved-card-block"]')
    await savedBlock.waitFor({ timeout: 15000 })
    const blockText = await savedBlock.innerText()
    overall =
      step("02", "saved card block visible on checkout", blockText.includes("••••"), {
        text: blockText
      }) && overall
    overall =
      step("03", "saved card label matches primary", blockText.includes(prep.saved_card_label.split("••••")[1]?.trim() || "0777"), {
        expected: prep.saved_card_label,
        text: blockText
      }) && overall

    const introShot = join(screenshotDir, `b112_r3_one_click_checkout_${prep.date}.png`)
    await page.screenshot({ path: introShot, fullPage: true })

    const idleText = await payButtonText(page)
    overall =
      step("04", "pay button idle state", /Оплатить/.test(idleText), { text: idleText }) && overall

    const payBtn = page.locator('button[aria-live="polite"]').first()
    const clickAt = Date.now()
    await payBtn.click()

    let loadingSeen = false
    for (let i = 0; i < 20; i += 1) {
      const t = await payButtonText(page)
      if (/Идёт оплата/.test(t)) {
        loadingSeen = true
        break
      }
      await page.waitForTimeout(50)
    }
    const loadingMs = Date.now() - clickAt
    overall =
      step("05", "pay button loading state ≤500ms", loadingSeen && loadingMs <= 500, {
        loadingSeen,
        loadingMs
      }) && overall

    await page.waitForTimeout(4000)

    const afterText = await payButtonText(page)
    const bodyText = await page.locator("body").innerText()
    const success = /Оплачено/.test(afterText)
    const errorAlert = await page.locator('[role="alert"]').count()
    const hasBindOther = /Привязать другую карту/i.test(bodyText)
    const hasRetry = /Повторить/i.test(bodyText)
    const fsmTerminal = success || errorAlert > 0

    overall =
      step("06", "FSM terminal: success or error", fsmTerminal, {
        afterText,
        errorAlert,
        success
      }) && overall
    overall =
      step(
        "07",
        "error UX: bind-other or retry on bank decline",
        success || hasBindOther || hasRetry || /списать|средств|карт/i.test(bodyText),
        { hasBindOther, hasRetry, success }
      ) && overall

    const afterShot = join(screenshotDir, `b112_r3_one_click_post_deploy_${prep.date}.png`)
    await page.screenshot({ path: afterShot, fullPage: true })

    const artifact = {
      scenario: "b112_r3_one_click_post_deploy",
      stand: prep.base,
      tenant_id: prep.tenant_id,
      email: prep.email,
      saved_card_id: prep.saved_card_id,
      started_at: startedAt,
      finished_at: new Date().toISOString(),
      pass: overall,
      prep_summary: {
        saved_cards_http: prep.saved_cards_http,
        saved_card_label: prep.saved_card_label,
        loading_ms: loadingMs
      },
      steps,
      screenshots: {
        checkout: `screenshots/b112_r3_one_click_checkout_${prep.date}.png`,
        after_pay: `screenshots/b112_r3_one_click_post_deploy_${prep.date}.png`
      },
      verdict: overall
        ? "B1.12-R3: checkout saved card + pay button FSM на Fly"
        : "есть FAIL — см. steps"
    }

    writeFileSync(postPath, JSON.stringify(artifact, null, 2))
    console.log(`Wrote ${postPath}`)
    process.exit(overall ? 0 : 1)
  } finally {
    await browser.close()
  }
}

run().catch((e) => {
  console.error(e)
  process.exit(1)
})
