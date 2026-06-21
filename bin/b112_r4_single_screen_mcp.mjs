#!/usr/bin/env node
/**
 * B1.12-R4 — Fly MCP: single-screen checkout, no #/payment, inline iframe.
 *
 *   ruby bin/b112_r4_single_screen_prep_fly.rb
 *   node bin/b112_r4_single_screen_mcp.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const prepPath = join(root, "tmp/b112_r4_single_screen_prep.json")
const prep = JSON.parse(readFileSync(prepPath, "utf8"))

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const screenshotDir = join(artifactDir, "screenshots")
const postPath = join(artifactDir, `b112_r4_single_screen_post_deploy_${prep.date}.json`)

const steps = []

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

async function openCheckout(ctx, guest) {
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
      profile: { name: guest.name, email: guest.email, emailVerified: true }
    }
  )

  await page.goto(`${prep.shop_url}#/checkout`, { waitUntil: "domcontentloaded", timeout: 60000 })
  await page.getByRole("heading", { name: "Оформление" }).waitFor({ timeout: 30000 })
  await page.waitForTimeout(2500)
  return page
}

async function run() {
  mkdirSync(artifactDir, { recursive: true })
  mkdirSync(screenshotDir, { recursive: true })

  const browser = await chromium.launch({ headless: true })
  let overall = true

  try {
    const upRes = await fetch(`${prep.base}/up`)
    overall = step("00", "/up 200", upRes.status === 200) && overall

    // —— New card: inline on checkout, no #/payment ——
    const ctxNew = await browser.newContext()
    if (prep.new_card.shop_cookies?.length) {
      await ctxNew.addCookies(
        prep.new_card.shop_cookies.map((c) => ({
          name: c.name,
          value: c.value,
          domain: c.domain,
          path: c.path || "/",
          secure: c.secure,
          httpOnly: c.httpOnly
        }))
      )
    }

    const pageNew = await openCheckout(ctxNew, prep.new_card)
    overall = step("01", "new card: checkout loads", /#\/checkout/.test(pageNew.url())) && overall

    const savedBlockNew = await pageNew.locator('[data-testid="saved-card-block"]').count()
    overall = step("02", "new card: no saved-card block", savedBlockNew === 0) && overall

    const payBtnNew = pageNew.locator('button[aria-live="polite"]').first()
    await payBtnNew.click()

    await pageNew.waitForTimeout(3000)
    const urlAfterPay = pageNew.url()
    overall =
      step("03", "new card: stays on #/checkout (not #/payment)", /#\/checkout/.test(urlAfterPay) && !/#\/payment/.test(urlAfterPay), {
        url: urlAfterPay
      }) && overall

    const inlineVisible = await pageNew.locator('[data-testid="checkout-inline-payment"]').isVisible().catch(() => false)
    overall = step("04", "new card: inline payment panel on checkout", inlineVisible) && overall

    const btnTextNew = await payButtonText(pageNew)
    overall =
      step("05", "new card: button pay state", /Идёт оплата|Оформляем|Ждём банк/.test(btnTextNew), {
        text: btnTextNew
      }) && overall

    const shotNew = join(screenshotDir, `b112_r4_inline_checkout_${prep.date}.png`)
    await pageNew.screenshot({ path: shotNew, fullPage: true })
    await ctxNew.close()

    // —— Stale #/payment: route removed ——
    const ctxStale = await browser.newContext()
    const pageStale = await ctxStale.newPage()
    await pageStale.goto(`${prep.shop_url}#/payment`, { waitUntil: "domcontentloaded", timeout: 60000 })
    await pageStale.waitForTimeout(1500)
    const stalePaymentHeading = await pageStale.getByRole("heading", { name: "Оплата", exact: true }).count()
    const staleCancelBtn = await pageStale.getByRole("button", { name: /Отменить заказ/ }).count()
    overall =
      step("06", "stale #/payment: no legacy payment screen", stalePaymentHeading === 0 && staleCancelBtn === 0, {
        url: pageStale.url()
      }) && overall
    await ctxStale.close()

    // —— One-click: no #/payment, no inline panel ——
    const ctx1c = await browser.newContext()
    if (prep.one_click.shop_cookies?.length) {
      await ctx1c.addCookies(
        prep.one_click.shop_cookies.map((c) => ({
          name: c.name,
          value: c.value,
          domain: c.domain,
          path: c.path || "/",
          secure: c.secure,
          httpOnly: c.httpOnly
        }))
      )
    }

    const page1c = await openCheckout(ctx1c, prep.one_click)

    const savedRes = await apiOnPage(
      page1c,
      prep.tenant_id,
      `/saved_cards?email=${encodeURIComponent(prep.one_click.email)}`
    )
    overall =
      step("07a", "one-click: GET saved_cards primary", savedRes.status === 200 && !!savedRes.body?.primary, {
        status: savedRes.status,
        primary: savedRes.body?.primary
      }) && overall

    const savedBlock = page1c.locator('[data-testid="saved-card-block"]')
    await savedBlock.waitFor({ timeout: 20000 })
    overall = step("07", "one-click: saved card block visible", true) && overall

    const payBtn1c = page1c.locator('button[aria-live="polite"]').first()
    await payBtn1c.click()

    let loadingSeen = false
    for (let i = 0; i < 20; i += 1) {
      const t = await payButtonText(page1c)
      if (/Идёт оплата/.test(t)) {
        loadingSeen = true
        break
      }
      await page1c.waitForTimeout(50)
    }
    overall = step("08", "one-click: button loading state", loadingSeen) && overall

    await page1c.waitForTimeout(4000)
    const url1c = page1c.url()
    overall =
      step("09", "one-click: never navigates to #/payment", !/#\/payment/.test(url1c), { url: url1c }) && overall

    const inline1c = await page1c.locator('[data-testid="checkout-inline-payment"]').isVisible().catch(() => false)
    overall = step("10", "one-click: no inline iframe panel", !inline1c) && overall

    const shot1c = join(screenshotDir, `b112_r4_one_click_checkout_${prep.date}.png`)
    await page1c.screenshot({ path: shot1c, fullPage: true })
    await ctx1c.close()

    const artifact = {
      scenario: "b112_r4_single_screen_post_deploy",
      date: prep.date,
      stand: prep.base,
      tenant_id: prep.tenant_id,
      fix_commit: prep.fix_commit,
      was: "push('/payment') — отдельный экран Оплата",
      now: "inline iframe на checkout, кнопка статусов, 1 клик без #/payment",
      steps,
      screenshots: [
        `screenshots/b112_r4_inline_checkout_${prep.date}.png`,
        `screenshots/b112_r4_one_click_checkout_${prep.date}.png`
      ],
      pass: overall,
      fly_mcp: overall ? "pass" : "fail"
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
