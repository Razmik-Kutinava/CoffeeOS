#!/usr/bin/env node
import { chromium } from "playwright"
import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"

const html = resolve(process.argv[2])
const png = resolve(process.argv[3])
const browser = await chromium.launch({ headless: true })
const page = await browser.newPage()
await page.goto(`file://${html}`, { waitUntil: "load", timeout: 60000 })
await page.screenshot({ path: png, fullPage: true })
await browser.close()
