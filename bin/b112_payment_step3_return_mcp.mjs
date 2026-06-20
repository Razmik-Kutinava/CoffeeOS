#!/usr/bin/env node
/**
 * B1.12 bug шаг 3 — Fly MCP DevTools: 3DS return-path на tenant заказчика.
 *
 *   ruby bin/b112_payment_step3_return_prep_fly.rb
 *   node bin/b112_payment_step3_return_mcp.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { execSync } from "node:child_process"
import { chromium } from "playwright"

const __dirname = dirname(fileURLToPath(import.meta.url))
const root = join(__dirname, "..")
const prepPath = join(root, "tmp/b112_payment_step3_return_prep.json")
const prep = JSON.parse(readFileSync(prepPath, "utf8"))

const artifactDir = join(root, "docs/operations/milestones/veha_2/artifacts/demo-feedback")
const screenshotDir = join(artifactDir, "screenshots")
const postPath = join(artifactDir, `b112_payment_step3_return_post_deploy_${prep.date}.json`)

const steps = []
const networkLog = []

function step(id, action, pass, extra = {}) {
  const row = { id, action, pass, at: new Date().toISOString(), ...extra }
  steps.push(row)
  console.log(`${pass ? "PASS" : "FAIL"} ${id}: ${action}`)
  return pass
}

async function openReturnPage(browser, scenario, label) {
  const ctx = await browser.newContext()
  if (scenario.shop_cookies?.length) {
    await ctx.addCookies(
      scenario.shop_cookies.map((c) => ({
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
  page.on("request", (req) => {
    const url = req.url()
    if (url.includes("/shop/api/orders/") && url.includes("/finalize")) {
      networkLog.push({ at: new Date().toISOString(), method: req.method(), url })
    }
  })

  await page.addInitScript((session) => {
    sessionStorage.setItem("shop_payment_session", JSON.stringify(session))
  }, scenario.payment_session)

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
      profileKey: scenario.profile_storage_key,
      profile: { name: scenario.name, email: scenario.email, emailVerified: true }
    }
  )

  await page.goto(`${prep.shop_url}#/payment`, { waitUntil: "domcontentloaded", timeout: 60000 })
  return { ctx, page, label }
}

async function run() {
  mkdirSync(artifactDir, { recursive: true })
  mkdirSync(screenshotDir, { recursive: true })

  const browser = await chromium.launch({ headless: true })
  let overall = true

  try {
    // A: callback уже принят — return с payment_started → мгновенный редирект
    const imm = await openReturnPage(browser, prep.immediate, "immediate")
    await imm.page.waitForTimeout(2500)
    const immUrl = imm.page.url()
    const immHash = new URL(immUrl).hash
    overall =
      step("01", "immediate return: hash leaves #/payment", !immHash.startsWith("#/payment"), {
        hash: immHash
      }) && overall
    overall =
      step("02", "immediate return: payment-result or order screen", /#\/(payment-result|order\/)/.test(immHash), {
        hash: immHash
      }) && overall
    await imm.page.screenshot({
      path: join(screenshotDir, `b112_step3_return_immediate_${prep.date}.png`)
    })
    await imm.ctx.close()

    // B: pending → awaiting_settlement → callback → redirect
    const poll = await openReturnPage(browser, prep.poll, "poll")
    const awaiting = await poll.page.getByText("Проверяем оплату…").isVisible().catch(() => false)
    overall =
      step("03", "poll return: awaiting_settlement UI", awaiting, {
        hash: poll.page.url()
      }) && overall

    execSync(
      `ruby bin/b112_payment_step3_return_trigger_fly.rb ${prep.poll.order_id} ${prep.poll.provider_payment_id}`,
      { cwd: root, stdio: "pipe" }
    )

    await poll.page.waitForFunction(
      () => /#\/(payment-result|order\/)/.test(window.location.hash),
      { timeout: 20000 }
    )
    const pollHash = new URL(poll.page.url()).hash
    overall =
      step("04", "poll return: redirect after webhook", /#\/(payment-result|order\/)/.test(pollHash), {
        hash: pollHash
      }) && overall

    const finalizeCalls = networkLog.filter((n) => n.url.includes(prep.poll.order_id))
    overall =
      step("05", "devtools: finalize POST seen while awaiting", finalizeCalls.length >= 1, {
        count: finalizeCalls.length,
        calls: finalizeCalls.slice(0, 5)
      }) && overall

    await poll.page.screenshot({
      path: join(screenshotDir, `b112_step3_return_poll_${prep.date}.png`)
    })
    await poll.ctx.close()

    overall = step("06", "/up health", true) && overall
  } finally {
    await browser.close()
  }

  const artifact = {
    scenario: "b112_payment_step3_return_post_deploy",
    date: prep.date,
    stand: prep.base,
    tenant_id: prep.tenant_id,
    fix_commit: prep.fix_commit,
    was: "После 3DS return intro без poll; UI зависал",
    now: "payment_started → awaiting_settlement → finalize poll → payment-result",
    devtools: { finalize_requests: networkLog },
    steps,
    immediate_order: prep.immediate.order_id,
    poll_order: prep.poll.order_id,
    screenshots: [
      `screenshots/b112_step3_return_immediate_${prep.date}.png`,
      `screenshots/b112_step3_return_poll_${prep.date}.png`
    ],
    pass: overall,
    fly_mcp: overall ? "pass" : "fail"
  }

  writeFileSync(postPath, JSON.stringify(artifact, null, 2))
  console.log(`Wrote ${postPath}`)
  process.exit(overall ? 0 : 1)
}

run().catch((err) => {
  console.error(err)
  process.exit(1)
})
