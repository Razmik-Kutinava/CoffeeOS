#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const jsonPath = join(root, "tmp/b14_lighthouse_pwa.report.json")
const j = JSON.parse(readFileSync(jsonPath, "utf8"))
const ids = [
  "installable-manifest",
  "service-worker",
  "splash-screen",
  "themed-omnibox",
  "content-width",
  "viewport",
  "maskable-icon"
]
const relevant = ids.map((id) => ({ id, audit: j.audits[id] })).filter((x) => x.audit)
const failed = relevant.filter((x) => x.audit.score !== null && x.audit.score < 1).map((x) => x.id)
const pass = failed.length === 0 && relevant.length === ids.length
const score = relevant.length ? Math.round((relevant.filter((x) => x.audit.score === 1).length / ids.length) * 100) : 0
const out = { score_percent: score, pass, failed_audit_ids: failed, audits: relevant.map((x) => ({ id: x.id, score: x.audit.score, title: x.audit.title })) }
writeFileSync(join(root, "tmp/b14_lighthouse_result.json"), JSON.stringify(out, null, 2))
console.log(JSON.stringify(out, null, 2))
