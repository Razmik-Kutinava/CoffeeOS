import { readFileSync } from "node:fs"
const j = JSON.parse(readFileSync("tmp/b14_lighthouse_pwa.report.json", "utf8"))
console.log(Object.keys(j.audits).filter(k => /install|manifest|service|pwa|mask|viewport|splash|theme|mobile/i.test(k)).sort().join("\n"))
