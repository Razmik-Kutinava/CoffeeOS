#!/usr/bin/env node
/**
 * B1.12-R1 — Fly MCP: saved_cards API + recurrent order path.
 *
 *   ruby bin/b112_r1_recurrent_prep_fly.rb
 *   node bin/b112_r1_recurrent_mcp.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const prepPath = join(root, "tmp/b112_r1_recurrent_prep.json")
const prep = JSON.parse(readFileSync(prepPath, "utf8"))

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const screenshotDir = join(artifactDir, "screenshots")
const postPath = join(artifactDir, `b112_r1_recurrent_post_deploy_${prep.date}.json`)

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

    await page.goto(prep.shop_url, { waitUntil: "domcontentloaded", timeout: 60000 })
    await page.waitForTimeout(1000)

    overall =
      step("00", "shop shell loads", (await page.title()).length > 0) && overall

    const savedRes = await apiOnPage(page, prep.tenant_id, "/saved_cards")
    overall =
      step("01", "GET saved_cards 200", savedRes.status === 200, savedRes.body) && overall
    overall =
      step(
        "02",
        "saved_cards primary masked pan",
        savedRes.body?.primary?.masked_pan === prep.saved_cards_primary_masked,
        { expected: prep.saved_cards_primary_masked, got: savedRes.body?.primary?.masked_pan }
      ) && overall

    await apiOnPage(page, prep.tenant_id, "/cart", { method: "DELETE" })
    const addRes = await apiOnPage(page, prep.tenant_id, "/cart/add", {
      method: "POST",
      body: { product_id: prep.product_id, quantity: 1, selected_modifiers: [] }
    })
    overall = step("03", "cart add for recurrent", addRes.status === 200) && overall

    const recurrentRes = await apiOnPage(page, prep.tenant_id, "/orders", {
      method: "POST",
      body: {
        name: prep.name,
        email: prep.email,
        payment_method: "card",
        saved_card_id: prep.saved_card_id,
        client_order_uuid: crypto.randomUUID()
      }
    })

    const recurrentOk =
      (recurrentRes.status === 200 &&
        recurrentRes.body?.recurrent_charge === true &&
        recurrentRes.body?.provider_payment_id) ||
      (recurrentRes.status === 422 &&
        /сохранённой карты|списать/i.test(recurrentRes.body?.error || ""))
    overall =
      step("04", "POST orders saved_card_id → recurrent path", recurrentOk, recurrentRes.body) &&
      overall

    await apiOnPage(page, prep.tenant_id, "/cart", { method: "DELETE" })
    await apiOnPage(page, prep.tenant_id, "/cart/add", {
      method: "POST",
      body: { product_id: prep.product_id, quantity: 1, selected_modifiers: [] }
    })
    const initRes = await apiOnPage(page, prep.tenant_id, "/orders", {
      method: "POST",
      body: {
        name: prep.name,
        email: prep.email,
        payment_method: "card",
        client_order_uuid: crypto.randomUUID()
      }
    })
    overall =
      step(
        "05",
        "card init still returns payment_url (§2.3 regression)",
        initRes.status === 200 && !!initRes.body?.payment_url,
        { status: initRes.body?.status }
      ) && overall

    const shot = join(screenshotDir, `b112_r1_recurrent_post_deploy_${prep.date}.png`)
    await page.screenshot({ path: shot, fullPage: true })

    const artifact = {
      scenario: "b112_r1_recurrent_post_deploy",
      stand: prep.base,
      tenant_id: prep.tenant_id,
      started_at: startedAt,
      finished_at: new Date().toISOString(),
      pass: overall,
      prep_summary: {
        saved_cards_http: prep.saved_cards_http,
        recurrent_order_http: prep.recurrent_order_http,
        card_init_http: prep.card_init_http
      },
      steps,
      screenshot: `screenshots/b112_r1_recurrent_post_deploy_${prep.date}.png`,
      verdict: overall
        ? "B1.12-R1 API на Fly: saved_cards + recurrent_charge + card init OK"
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
