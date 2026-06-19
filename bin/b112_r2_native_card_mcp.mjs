#!/usr/bin/env node
/**
 * B1.12-R2 — Fly MCP: T-Bank web-frame на #/payment (integration.js + iframe).
 *
 *   ruby bin/b112_r2_native_card_prep_fly.rb
 *   node bin/b112_r2_native_card_mcp.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const prepPath = join(root, "tmp/b112_r2_native_card_prep.json")
const prep = JSON.parse(readFileSync(prepPath, "utf8"))

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const screenshotDir = join(artifactDir, "screenshots")
const postPath = join(artifactDir, `b112_r2_native_card_post_deploy_${prep.date}.json`)

const steps = []
const startedAt = new Date().toISOString()

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
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
      ({ profileKey, profile, paymentSession }) => {
        localStorage.setItem(
          profileKey,
          JSON.stringify({
            savedAt: new Date().toISOString(),
            ttlMs: 24 * 60 * 60 * 1000,
            payload: profile
          })
        )
        sessionStorage.setItem("shop_payment_session", JSON.stringify(paymentSession))
      },
      {
        profileKey: prep.profile_storage_key,
        profile: { name: prep.name, email: prep.email, emailVerified: true },
        paymentSession: prep.payment_session
      }
    )

    await page.goto(`${prep.shop_url}#/payment`, { waitUntil: "domcontentloaded", timeout: 60000 })
    await page.getByRole("heading", { name: "Оплата" }).waitFor({ timeout: 30000 })
    await page.waitForTimeout(800)

    overall =
      step("00", "payment intro on #/payment", /#\/payment/.test(page.url())) && overall
    overall =
      step("01", "payment_iframe flag from API", prep.payment_iframe === true, {
        payment_iframe: prep.payment_iframe
      }) && overall
    overall =
      step("02", "card_binding flag from API", prep.card_binding === true, {
        card_binding: prep.card_binding
      }) && overall

    const introShot = join(screenshotDir, `b112_r2_native_card_intro_${prep.date}.png`)
    await page.screenshot({ path: introShot, fullPage: true })

    await page.getByRole("button", { name: /^Оплатить/ }).click()
    await page.waitForTimeout(2500)

    const frameState = await page.evaluate(() => {
      const host = document.querySelector(".payment-shell__host")
      const iframes = host ? Array.from(host.querySelectorAll("iframe")) : []
      const srcs = iframes.map((f) => f.src || "")
      const bodyText = document.body.innerText || ""
      const hasIntegration = !!document.querySelector('script[data-tbank-integration="1"]')
      return {
        iframeCount: iframes.length,
        srcs,
        hasCardChrome: /Введите данные карты/i.test(bodyText),
        hasIntegration,
        hasTbankSrc: srcs.some((s) => /tbank\.ru/i.test(s))
      }
    })

    overall =
      step("03", "payment shell chrome visible", frameState.hasCardChrome, frameState) && overall
    overall =
      step(
        "04",
        "T-Bank iframe mounted in host",
        frameState.iframeCount > 0 && frameState.hasTbankSrc,
        frameState
      ) && overall
    overall =
      step(
        "05",
        "integration.js loaded or iframe fallback",
        frameState.hasIntegration || frameState.iframeCount > 0,
        frameState
      ) && overall

    const frameShot = join(screenshotDir, `b112_r2_native_card_post_deploy_${prep.date}.png`)
    await page.screenshot({ path: frameShot, fullPage: true })

    const artifact = {
      scenario: "b112_r2_native_card_post_deploy",
      stand: prep.base,
      tenant_id: prep.tenant_id,
      order_id: prep.order_id,
      started_at: startedAt,
      finished_at: new Date().toISOString(),
      pass: overall,
      prep_summary: {
        payment_iframe: prep.payment_iframe,
        card_binding: prep.card_binding,
        terminal_key_present: !!prep.terminal_key
      },
      steps,
      screenshots: {
        intro: `screenshots/b112_r2_native_card_intro_${prep.date}.png`,
        iframe: `screenshots/b112_r2_native_card_post_deploy_${prep.date}.png`
      },
      verdict: overall
        ? "B1.12-R2: web-фрейм Т-Банка на #/payment — iframe + card_binding"
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
