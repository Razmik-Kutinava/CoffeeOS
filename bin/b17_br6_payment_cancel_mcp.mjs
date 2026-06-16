#!/usr/bin/env node
/**
 * B1.7 BR-6 — отмена заказа на #/payment (intro «Отменить заказ»).
 *
 *   ruby bin/b17_br6_payment_cancel_prep_fly.rb   # verified email в Fly БД
 *   node bin/b17_br6_payment_cancel_mcp.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const prepPath = join(root, "tmp/b17_br6_payment_cancel_prep.json")
const prep = JSON.parse(readFileSync(prepPath, "utf8"))

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const screenshotDir = join(artifactDir, "screenshots")
const reproPath = join(artifactDir, `b17_br6_payment_cancel_repro_${prep.date}.json`)
const postPath = join(artifactDir, `b17_br6_payment_cancel_post_deploy_${prep.date}.json`)

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

async function run() {
  mkdirSync(artifactDir, { recursive: true })
  mkdirSync(screenshotDir, { recursive: true })

  const browser = await chromium.launch({ headless: true })
  let overall = true
  let orderId = null

  try {
    const ctx = await browser.newContext()
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

    await page.goto(prep.shop_url, { waitUntil: "domcontentloaded", timeout: 60000 })
    await page.waitForTimeout(1000)

    await apiOnPage(page, prep.tenant_id, "/cart", { method: "DELETE" })
    const addRes = await apiOnPage(page, prep.tenant_id, "/cart/add", {
      method: "POST",
      body: { product_id: prep.product_id, quantity: 1, selected_modifiers: [] }
    })
    overall =
      step("00", "cart add via API", addRes.status === 200, addRes) && overall

    await page.goto(`${prep.shop_url}#/checkout`, { waitUntil: "domcontentloaded" })
    await page.getByRole("heading", { name: "Оформление" }).waitFor({ timeout: 30000 })

    const statusRes = await apiOnPage(
      page,
      prep.tenant_id,
      `/email_otp/status?email=${encodeURIComponent(prep.email)}`
    )
    overall =
      step("01a", "email verified on server", statusRes.body?.verified === true, statusRes.body) && overall

    const payBtn = page.getByRole("button", { name: /^Оплатить/ })
    await payBtn.waitFor({ state: "visible", timeout: 30000 })

    let payEnabled = false
    for (let i = 0; i < 12; i += 1) {
      payEnabled = await payBtn.isEnabled()
      if (payEnabled) break
      await page.waitForTimeout(1000)
    }

    overall = step("01", "checkout pay button enabled", payEnabled) && overall
    if (!payEnabled) {
      const snippet = await page.locator("body").innerText()
      throw new Error(`pay disabled: ${snippet.slice(0, 300)}`)
    }

    await payBtn.click()
    await page.waitForURL(/#\/payment/, { timeout: 60000 })
    await page.getByRole("heading", { name: "Оплата" }).waitFor({ timeout: 30000 })
    await page.waitForTimeout(1000)

    const bodyIntro = await page.locator("body").innerText()
    orderId = bodyIntro.match(/Заказ #([a-f0-9-]+)/i)?.[1] || prep.order_id
    overall =
      step("02", "payment intro after checkout", /#\/payment/.test(page.url()) && !!orderId, {
        orderId,
        url: page.url()
      }) && overall

    await page.screenshot({
      path: join(screenshotDir, `b17_br6_payment_cancel_before_${prep.date}.png`),
      fullPage: true
    })

    await page.getByRole("button", { name: /Отменить заказ/ }).click()
    await page.waitForURL(/#\/payment-result/, { timeout: 30000 })
    await page.waitForTimeout(1500)

    const body = await page.locator("body").innerText()
    overall =
      step("03", "redirect #/payment-result after cancel", /#\/payment-result/.test(page.url())) &&
      overall
    overall = step("04", "cancel message visible", /отменена/i.test(body)) && overall
    overall =
      step("05", "«В корзину» on result screen", (await page.getByRole("button", { name: /В корзину/ }).count()) > 0) &&
      overall

    const orderStatus = await apiOnPage(page, prep.tenant_id, `/orders/${orderId}`)
    const cancelled = orderStatus.body?.status === "cancelled"
    overall = step("06", "order status cancelled in API", cancelled, orderStatus.body) && overall

    await page.screenshot({
      path: join(screenshotDir, `b17_br6_payment_cancel_after_${prep.date}.png`),
      fullPage: true
    })
  } finally {
    await browser.close()
  }

  const artifact = {
    scenario: "b17_br6_payment_cancel",
    stand: prep.base,
    tenant_id: prep.tenant_id,
    order_id: orderId,
    started_at: startedAt,
    finished_at: new Date().toISOString(),
    pass: overall,
    steps,
    fix_note: "Payment.svelte cancel flow; abandon + reconnect_token"
  }

  const outPath = process.env.BR6_REPRO_ONLY ? reproPath : postPath
  writeFileSync(outPath, JSON.stringify(artifact, null, 2))
  console.log(`Artifact: ${outPath}`)
  if (!overall) process.exit(1)
}

run().catch((e) => {
  console.error(e)
  process.exit(1)
})
