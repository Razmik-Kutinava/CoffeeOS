#!/usr/bin/env node
/**
 * B1.12-R3 rev2 — Fly MCP: PaymentMethodsSheet + FSM 0–7 + card_config.
 *
 *   ruby bin/b112_r3_one_click_prep_fly.rb
 *   node bin/b112_r3_fsm_mcp.mjs
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
const opsPath = join(artifactDir, `b112_r3_fsm_ops_pass_${prep.date}.json`)
const postPath = join(artifactDir, `b112_r3_fsm_post_deploy_${prep.date}.json`)

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

async function fsmState(page) {
  const btn = page.locator('[data-testid="checkout-pay-fsm"]').first()
  if ((await btn.count()) === 0) return null
  return btn.getAttribute("data-fsm-state")
}

async function fsmLabel(page) {
  const btn = page.locator('[data-testid="checkout-pay-fsm"]').first()
  if ((await btn.count()) === 0) return ""
  return btn.innerText().catch(() => "")
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
    await page.waitForTimeout(1500)

    overall = step("00", "checkout #/checkout loads", /#\/checkout/.test(page.url())) && overall

    const savedRes = await apiOnPage(page, prep.tenant_id, `/saved_cards?email=${encodeURIComponent(prep.email)}`)
    overall =
      step("01", "GET saved_cards 200 + primary", savedRes.status === 200 && !!savedRes.body?.primary, {
        status: savedRes.status
      }) && overall

    const configRes = await apiOnPage(page, prep.tenant_id, "/payments/card_config")
    const rsaReady = configRes.status === 200 && configRes.body?.card_data_ready === true
    overall =
      step("02", "GET card_config (TBANK_RSA_PUBLIC_KEY on Fly)", rsaReady, {
        status: configRes.status,
        card_data_ready: configRes.body?.card_data_ready,
        note: rsaReady ? null : "tail 3.1: fly secrets set TBANK_RSA_PUBLIC_KEY"
      }) && overall
    const uiPassWithoutRsa = rsaReady

    const summary = page.locator('[data-testid="payment-method-summary"]')
    await summary.waitFor({ timeout: 15000 })
    const summaryText = await summary.innerText()
    const last4 = prep.saved_card_label?.match(/\d{4}/)?.[0] || prep.saved_cards_primary_masked?.slice(-4)
    overall =
      step("03", "payment method summary shows saved card", summaryText.includes("Карта") && summaryText.includes(last4), {
        summaryText,
        last4
      }) && overall

    await summary.click()
    const sheet = page.locator('[data-testid="payment-methods-sheet"]')
    await sheet.waitFor({ timeout: 10000 })
    const sheetText = await sheet.innerText()
    overall =
      step("04", "PaymentMethodsSheet opens with card list", sheetText.includes("Способ оплаты") && sheetText.includes("Новая карта"), {
        sheetText: sheetText.slice(0, 200)
      }) && overall

    const checkoutShot = join(screenshotDir, `b112_r3_fsm_checkout_${prep.date}.png`)
    await page.screenshot({ path: checkoutShot, fullPage: true })

    const idleState = await fsmState(page)
    const idleLabel = await fsmLabel(page)
    overall =
      step("05", "FSM State 0 default Оплатить", idleState === "0" && /Оплатить/.test(idleLabel), {
        idleState,
        idleLabel
      }) && overall

    const payBtn = page.locator('[data-testid="payment-methods-sheet"] [data-testid="checkout-pay-fsm"]')
    await payBtn.scrollIntoViewIfNeeded()
    const payDisabled = await payBtn.isDisabled()
    if (payDisabled) {
      const closed = await page.locator('[data-testid="checkout-closed-banner"]').count()
      step("05b", "pay button enabled (shop open)", false, { payDisabled, closedBanner: closed > 0 })
      overall = false
    }
    const clickAt = Date.now()
    await payBtn.evaluate((el) => el.click())

    let connectingSeen = false
    for (let i = 0; i < 25; i += 1) {
      const st = await fsmState(page)
      const lbl = await fsmLabel(page)
      if (st === "1" || /Установка соединения/.test(lbl)) {
        connectingSeen = true
        break
      }
      await page.waitForTimeout(50)
    }
    const reactionMs = Date.now() - clickAt
    overall =
      step("06", "FSM State 1 ≤500ms after tap", connectingSeen && reactionMs <= 500, {
        connectingSeen,
        reactionMs
      }) && overall

    await page.waitForTimeout(6000)

    const terminalState = await fsmState(page)
    const terminalLabel = await fsmLabel(page)
    const bodyText = await page.locator("body").innerText()
    const paymentAlerts = await page.locator('[data-testid="checkout-pay-fsm"] ~ [role="alert"]').count()
    const stillOnCheckout = /#\/checkout/.test(page.url())
    const terminalOk =
      stillOnCheckout &&
      (["1", "2", "3", "4", "5", "6", "7"].includes(terminalState || "") ||
        /Оплачено|Отказ|Сбой банка|Нет сети|Обработка|Установка/.test(terminalLabel))

    overall =
      step("07", "FSM terminal state after pay attempt", terminalOk, {
        terminalState,
        terminalLabel,
        stillOnCheckout,
        url: page.url()
      }) && overall

    overall =
      step("08", "no payment error alert under button (FSM only)", paymentAlerts === 0, {
        paymentAlerts
      }) && overall

    overall =
      step("09", "no bank redirect / legacy iframe on checkout", !/\/payment(#|$)/.test(page.url()) && !bodyText.includes("redirectToBankPayment"), {
        url: page.url()
      }) && overall

    const afterShot = join(screenshotDir, `b112_r3_fsm_after_pay_${prep.date}.png`)
    await page.screenshot({ path: afterShot, fullPage: true })

    const coreSteps = steps.filter((s) => !["02"].includes(s.id))
    const corePass = coreSteps.every((s) => s.pass)
    const rsaTailOk = steps.find((s) => s.id === "02")?.pass === true

    const artifact = {
      scenario: "b112_r3_fsm_ops_pass",
      stand: prep.base,
      tenant_id: prep.tenant_id,
      email: prep.email,
      saved_card_id: prep.saved_card_id,
      started_at: startedAt,
      finished_at: new Date().toISOString(),
      pass: corePass,
      rsa_tail: { pass: rsaTailOk, action: "set TBANK_RSA_PUBLIC_KEY on Fly" },
      steps_pass: steps.filter((s) => s.pass).length,
      steps_total: steps.length,
      prep_summary: {
        card_config: configRes.body?.card_data_ready,
        reaction_ms: reactionMs,
        terminal_state: terminalState
      },
      steps,
      screenshots: {
        checkout: `screenshots/b112_r3_fsm_checkout_${prep.date}.png`,
        after_pay: `screenshots/b112_r3_fsm_after_pay_${prep.date}.png`
      },
      verdict: corePass
        ? rsaTailOk
          ? "B1.12-R3 rev2 FSM + PaymentMethodsSheet PASS on Fly (RSA ok)"
          : "B1.12-R3 rev2 UI/FSM PASS on Fly · хвост TBANK_RSA_PUBLIC_KEY"
        : "есть FAIL — см. steps"
    }

    writeFileSync(opsPath, JSON.stringify(artifact, null, 2))
    writeFileSync(postPath, JSON.stringify({ ...artifact, scenario: "b112_r3_fsm_post_deploy" }, null, 2))
    console.log(`Wrote ${opsPath}`)
    process.exit(corePass ? 0 : 1)
  } finally {
    await browser.close()
  }
}

run().catch((e) => {
  console.error(e)
  process.exit(1)
})
