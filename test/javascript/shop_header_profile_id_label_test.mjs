/**
 * TASK_107: в правом верхнем углу витрины — только текст «Профиль ID»
 * (реверс B1.13-S1 «Профиль › 655a…a3» и узкой ветки с иконкой и бейджем ID).
 * Узкая ширина включалась в onMount через matchMedia — SSR её не видит,
 * поэтому отсутствие узкой ветки проверяется по исходнику.
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { register } from "node:module"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import { renderSvelte } from "./svelte_ssr_helper.mjs"

const stubs = {
  "svelte-spa-router": "export function push() {}\nexport function link() {}\n",
  "lucide-svelte": [
    "const Icon = function () {}",
    "export default Icon",
    "export const User = Icon, ChevronDown = Icon, MessageCircle = Icon, X = Icon, Send = Icon, Mail = Icon",
    ""
  ].join("\n")
}
const stubUrls = Object.fromEntries(
  Object.entries(stubs).map(([name, code]) => [name, `data:text/javascript,${encodeURIComponent(code)}`])
)
const resolverSource = `
const stubUrls = ${JSON.stringify(stubUrls)}
export async function resolve(specifier, context, nextResolve) {
  if (stubUrls[specifier]) return { url: stubUrls[specifier], shortCircuit: true }
  return nextResolve(specifier, context)
}
`
register(`data:text/javascript,${encodeURIComponent(resolverSource)}`, import.meta.url)

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const headerPath = join(root, "app/frontend/components/Header.svelte")
const headerSource = readFileSync(headerPath, "utf8")

function profileButtonHtml(html) {
  const m = html.match(/<button[^>]*data-testid="shop-header-profile"[^>]*>([\s\S]*?)<\/button>/)
  assert.ok(m, "ожидалась кнопка shop-header-profile")
  return m[1]
}

function visibleText(fragment) {
  return fragment.replace(/<!--[\s\S]*?-->/g, "").replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim()
}

describe("TASK_107: «Профиль ID» в шапке витрины", () => {
  it("Subtask 1: обычная ширина — в кнопке профиля ровно «Профиль ID»", async () => {
    const html = await renderSvelte(headerPath, {})
    const button = profileButtonHtml(html)

    assert.match(button, /data-testid="shop-header-profile-label"/)
    assert.equal(visibleText(button), "Профиль ID")
    assert.doesNotMatch(button, /›|…/)
    assert.doesNotMatch(button, /shop-header-profile-id-badge/)
    assert.doesNotMatch(button, /<svg/)
  })

  it("Subtask 2: узкой ветки с иконкой и бейджем ID в исходнике нет", () => {
    assert.doesNotMatch(headerSource, /\{#if narrow\}/)
    assert.doesNotMatch(headerSource, /shop-header-profile-id-badge/)
    assert.doesNotMatch(headerSource, /<User\b/)
    assert.doesNotMatch(headerSource, /formatProfileIdShort\(/)
    assert.doesNotMatch(headerSource, /Профиль ›/)
  })

  it("клик по подписи по-прежнему ведёт в ЛК", () => {
    assert.match(headerSource, /data-testid="shop-header-profile"/)
    assert.match(headerSource, /push\("\/profile"\)/)
  })

  it("Subtask 3: адрес и часы работы в шапке на месте", () => {
    assert.match(headerSource, /data-testid="shop-header-tenant-address"/)
    assert.match(headerSource, /data-testid="shop-hours-display"/)
    assert.match(headerSource, /shop-tenant-dropdown/)
  })
})
