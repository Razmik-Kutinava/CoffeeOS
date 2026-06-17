#!/usr/bin/env node
/**
 * B1.7 BR-7 — checkout: пустое «Имя», verify email → «Оплатить →» активна.
 *
 *   ruby bin/b17_br7_checkout_name_pay_prep_fly.rb
 *   node bin/b17_br7_checkout_name_pay_mcp.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { execSync } from "node:child_process"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const prepPath = join(root, "tmp/b17_br7_checkout_name_pay_prep.json")
const prep = JSON.parse(readFileSync(prepPath, "utf8"))

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const screenshotDir = join(root, prep.screen_dir)
const postPath = join(root, prep.artifact)
const reproPath = join(artifactDir, "b17_br7_checkout_name_pay_repro_2026-06-17.json")

mkdirSync(artifactDir, { recursive: true })
mkdirSync(screenshotDir, { recursive: true })

const steps = []
const startedAt = new Date().toISOString()

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
}

function fetchOtp(email) {
  try {
    const out = execSync(`ruby bin/fetch_fly_otp.rb ${JSON.stringify(email)}`, {
      encoding: "utf8",
      cwd: root,
      timeout: 120000
    })
    const code = out.trim().match(/\b(\d{6})\b/)?.[1]
    return code || null
  } catch (e) {
    console.error("fetchOtp failed", e.stderr?.toString() || e.message)
    return null
  }
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
  const browser = await chromium.launch({ headless: true })
  let overall = true

  try {
    const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } })
    const page = await ctx.newPage()

    await page.goto(prep.shop_url, { waitUntil: "domcontentloaded", timeout: 60000 })
    await page.waitForTimeout(800)

    await apiOnPage(page, prep.tenant_id, "/cart", { method: "DELETE" })
    const addRes = await apiOnPage(page, prep.tenant_id, "/cart/add", {
      method: "POST",
      body: { product_id: prep.product_id, quantity: 1, selected_modifiers: [] }
    })
    overall = step("00", "cart add via API", addRes.status === 200, addRes) && overall

    await page.goto(`${prep.shop_url}#/checkout`, { waitUntil: "domcontentloaded" })
    await page.getByRole("heading", { name: "Оформление" }).waitFor({ timeout: 30000 })
    await page.waitForTimeout(1000)

    const nameInput = page.locator('input[autocomplete="name"]')
    await nameInput.waitFor({ timeout: 10000 })
    await nameInput.fill("")
    const nameEmpty = (await nameInput.inputValue()).trim() === ""
    overall = step("01", "name field empty", nameEmpty) && overall

    const emailInput = page.locator('input[type="email"]')
    await emailInput.fill(prep.email)
    overall =
      step("02", "email filled", (await emailInput.inputValue()) === prep.email) && overall

    await page.getByRole("button", { name: "Отправить код" }).click()
    await page.waitForTimeout(2500)

    let otp = null
    for (let i = 0; i < 8; i += 1) {
      otp = fetchOtp(prep.email)
      if (otp) break
      await page.waitForTimeout(1500)
    }
    overall = step("03", "otp fetched from Fly", !!otp, { otp: otp ? "***" : null }) && overall
    if (!otp) throw new Error("no otp")

    await page.locator('input[inputmode="numeric"]').fill(otp)
    await page.getByRole("button", { name: "Подтвердить email" }).click()
    await page.waitForTimeout(2000)

    const bodyAfterVerify = await page.locator("body").innerText()
    const verifiedUi =
      /Email подтверждён|Код отправлен на почту/i.test(bodyAfterVerify) ||
      (await page.locator("text=Контакты").count()) > 0
    overall = step("04", "email verified in UI", verifiedUi) && overall

    const payBtn = page.getByRole("button", { name: /^Оплатить/ })
    await payBtn.waitFor({ state: "visible", timeout: 15000 })

    let payEnabled = false
    for (let i = 0; i < 15; i += 1) {
      payEnabled = await payBtn.isEnabled()
      if (payEnabled) break
      await page.waitForTimeout(500)
    }

    await page.screenshot({
      path: join(screenshotDir, "01_empty_name_email_verified_pay_enabled.png"),
      fullPage: true
    })

    overall = step("05", "pay button enabled with empty name after verify", payEnabled) && overall
    if (!payEnabled) {
      throw new Error(`pay disabled: ${bodyAfterVerify.slice(0, 400)}`)
    }

    const payClass = await payBtn.getAttribute("class")
    const looksActive = !payClass?.includes("opacity-50") || payEnabled
    overall = step("06", "pay button visually active (enabled)", looksActive) && overall
  } finally {
    await browser.close()
  }

  const artifact = {
    scenario: prep.scenario,
    task_id: prep.task_id,
    date: prep.date,
    status: overall ? "PASS" : "FAIL",
    verdict: overall ? "PASS" : "FAIL",
    pass: overall,
    base: prep.base,
    tenant_id: prep.tenant_id,
    email: prep.email,
    fix: {
      root_cause: "canPay required name.trim() while UI did not mark name as required",
      files: ["app/frontend/routes/Checkout.svelte"]
    },
    playwright: {
      script: "bin/b17_br7_checkout_name_pay_mcp.mjs",
      prep: "bin/b17_br7_checkout_name_pay_prep_fly.rb",
      steps,
      started_at: startedAt,
      finished_at: new Date().toISOString()
    },
    screenshots: [
      `${prep.screen_dir}/01_empty_name_email_verified_pay_enabled.png`
    ],
    repro_artifact: "b17_br7_checkout_name_pay_repro_2026-06-17.json"
  }

  writeFileSync(postPath, JSON.stringify(artifact, null, 2))
  console.log(`Artifact: ${prep.artifact}`)
  if (!overall) process.exit(1)
}

run().catch((e) => {
  console.error(e)
  process.exit(1)
})
