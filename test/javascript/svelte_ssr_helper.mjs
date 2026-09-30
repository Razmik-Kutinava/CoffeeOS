/**
 * SSR-рендер Svelte-компонента в node --test без jsdom:
 * loader-хук компилирует *.svelte (generate: "server"), render() из svelte/server.
 */
import { register } from "node:module"
import { pathToFileURL } from "node:url"

const loaderSource = `
import { readFile } from "node:fs/promises"
import { fileURLToPath } from "node:url"
import { compile } from ${JSON.stringify(import.meta.resolve("svelte/compiler"))}

export async function load(url, context, nextLoad) {
  if (!url.endsWith(".svelte")) return nextLoad(url, context)
  const filename = fileURLToPath(url)
  const source = await readFile(filename, "utf8")
  const { js } = compile(source, { filename, generate: "server", dev: false })
  return { format: "module", source: js.code, shortCircuit: true }
}
`

register(`data:text/javascript,${encodeURIComponent(loaderSource)}`, import.meta.url)

/**
 * @param {string} componentPath абсолютный путь к .svelte
 * @param {Record<string, unknown>} props
 * @returns {Promise<string>} body HTML
 */
export async function renderSvelte(componentPath, props) {
  const { render } = await import("svelte/server")
  const { default: Component } = await import(pathToFileURL(componentPath).href)
  return render(Component, { props }).body
}
