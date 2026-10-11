// TASK_107 — замер шапки витрины через CDP (headless Chrome).
// node measure_header.mjs <shop-url> <outDir>
// Снимает 390×844 и 320×640: подпись профиля, адрес, часы, пересечения, скрин.
import { spawn } from "node:child_process"
import { mkdtempSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"

const url = process.argv[2]
const outDir = process.argv[3] || "."
const chromePath = process.env.CHROME_PATH || "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
const port = 9333

const chrome = spawn(chromePath, [
  "--headless=new",
  `--remote-debugging-port=${port}`,
  `--user-data-dir=${mkdtempSync(join(tmpdir(), "task107-"))}`,
  "--no-first-run",
  "about:blank"
], { stdio: "ignore" })

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

async function targetWs() {
  for (let i = 0; i < 50; i++) {
    try {
      const list = await (await fetch(`http://127.0.0.1:${port}/json`)).json()
      const page = list.find((t) => t.type === "page")
      if (page) return page.webSocketDebuggerUrl
    } catch {}
    await sleep(200)
  }
  throw new Error("chrome devtools not reachable")
}

const ws = new WebSocket(await targetWs())
await new Promise((r) => ws.addEventListener("open", r, { once: true }))
let seq = 0
const pending = new Map()
ws.addEventListener("message", (e) => {
  const msg = JSON.parse(e.data)
  if (msg.id && pending.has(msg.id)) {
    pending.get(msg.id)(msg)
    pending.delete(msg.id)
  }
})
const send = (method, params = {}) =>
  new Promise((resolve) => {
    const id = ++seq
    pending.set(id, resolve)
    ws.send(JSON.stringify({ id, method, params }))
  })

const measure = `(() => {
  const rect = (el) => {
    if (!el) return null
    const b = el.getBoundingClientRect()
    return { left: Math.round(b.left), right: Math.round(b.right), top: Math.round(b.top), bottom: Math.round(b.bottom), w: Math.round(b.width), h: Math.round(b.height) }
  }
  const q = (s) => document.querySelector(s)
  const btn = q('[data-testid="shop-header-profile"]')
  const addr = q('[data-testid="shop-header-tenant-address"]')
  const header = q('header')
  const a = rect(addr), p = rect(btn)
  return {
    viewport: { w: innerWidth, h: innerHeight },
    profileText: btn ? btn.textContent.trim() : null,
    profileHasSvg: !!btn?.querySelector('svg'),
    badge: !!q('[data-testid="shop-header-profile-id-badge"]'),
    profile: p,
    address: a,
    addressText: addr ? addr.textContent.trim() : null,
    hours: q('[data-testid="shop-hours-display"]')?.textContent.trim() || null,
    header: rect(header),
    overlapAddressProfile: !!(a && p && a.right > p.left && a.top < p.bottom && p.top < a.bottom),
    profileInsideViewport: !!(p && p.right <= innerWidth)
  }
})()`

await send("Page.enable")
await send("Runtime.enable")
const results = {}
for (const [w, h] of [[390, 844], [320, 640]]) {
  await send("Emulation.setDeviceMetricsOverride", { width: w, height: h, deviceScaleFactor: 2, mobile: true })
  await send("Page.navigate", { url })
  await sleep(6000)
  const r = await send("Runtime.evaluate", { expression: measure, returnByValue: true })
  results[`${w}x${h}`] = r.result.result.value
  const shot = await send("Page.captureScreenshot", { format: "png", clip: { x: 0, y: 0, width: w, height: 120, scale: 2 } })
  writeFileSync(join(outDir, `header_${w}x${h}.png`), Buffer.from(shot.result.data, "base64"))

  // Длинный адрес (как у реальной точки): подпись профиля не должна сжиматься и наезжать.
  await send("Runtime.evaluate", {
    expression: `(() => { const a = document.querySelector('[data-testid="shop-header-tenant-address"]'); const t = a.querySelector('span') || a; t.textContent = 'г. Москва, ул. Большая Дмитровка, д. 32, стр. 1, Витрина А'; })()`
  })
  await sleep(300)
  const long = await send("Runtime.evaluate", { expression: measure, returnByValue: true })
  results[`${w}x${h}_long_address`] = long.result.result.value
  const shotLong = await send("Page.captureScreenshot", { format: "png", clip: { x: 0, y: 0, width: w, height: 120, scale: 2 } })
  writeFileSync(join(outDir, `header_${w}x${h}_long_address.png`), Buffer.from(shotLong.result.data, "base64"))
}

console.log(JSON.stringify(results, null, 2))
ws.close()
chrome.kill()
process.exit(0)
