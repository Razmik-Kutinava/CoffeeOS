/**
 * Задача_2 (ЛК в PWA) Патч 3: в шапке витрины нет отдельной иконки поддержки
 * (`shop-header-support-chat`) ни на обычной, ни на узкой ширине; «Профиль ID» на месте.
 * Узкая ширина включается в onMount через matchMedia — SSR её не видит, поэтому
 * для неё проверяется исходник (обе ветки `{#if narrow}`).
 */
import assert from "node:assert/strict"
import { describe, it } from "node:test"
import { readFileSync } from "node:fs"
import { register } from "node:module"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import { renderSvelte } from "./svelte_ssr_helper.mjs"

// svelte-spa-router и lucide-svelte Node ESM не резолвит (нет "exports" / битые пути dist):
// шапке в SSR нужны только push и пустые иконки.
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

describe("Header: нет support-chat (ЛК Патч 3)", () => {
  it("обычная ширина: в DOM шапки нет кнопки поддержки, «Профиль» есть", async () => {
    const html = await renderSvelte(headerPath, {})

    assert.doesNotMatch(html, /shop-header-support-chat/)
    assert.doesNotMatch(html, /Связь с поддержкой/)
    assert.match(html, /data-testid="shop-header-profile"/)
    assert.match(html, /data-testid="shop-header-profile-label"/)
  })

  it("узкая ширина: в исходнике шапки нет кнопки поддержки ни в одной ветке", () => {
    assert.doesNotMatch(headerSource, /shop-header-support-chat/)
    assert.doesNotMatch(headerSource, /MessageCircle/)
    assert.doesNotMatch(headerSource, /onSupportChatClick/)
  })

  it("узкая ширина: badge «Профиль ID» в ветке narrow сохранён", () => {
    const narrowBranch = headerSource.match(/\{#if narrow\}([\s\S]*?)\{:else\}/)
    assert.ok(narrowBranch, "ожидалась ветка {#if narrow}")
    assert.match(narrowBranch[1], /shop-header-profile-id-badge/)
    assert.match(headerSource, /push\("\/profile"\)/)
  })
})
