#!/usr/bin/env node
/** Poll Fly until Product bundle contains mod-chip, then exit 0 */
const MANIFEST = "https://coffeeos.fly.dev/vite/.vite/manifest.json"

async function check() {
  const m = await fetch(MANIFEST).then((r) => r.json())
  const file = m["routes/Product.svelte"]?.file
  if (!file) return { ready: false, file: null }
  const js = await fetch(`https://coffeeos.fly.dev/vite/${file}`).then((r) => r.text())
  return { ready: js.includes("mod-chip"), file, hasRequired: js.includes("обязательно") }
}

async function main() {
  const max = Number(process.env.MAX_ATTEMPTS || 25)
  for (let i = 1; i <= max; i++) {
    const { ready, file, hasRequired } = await check()
    console.log(`${new Date().toISOString()} attempt ${i}: ${file} mod-chip=${ready} obязательно=${hasRequired}`)
    if (ready) process.exit(0)
    await new Promise((r) => setTimeout(r, 60_000))
  }
  process.exit(1)
}

main().catch((e) => {
  console.error(e)
  process.exit(1)
})
