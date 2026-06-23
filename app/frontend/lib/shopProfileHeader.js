/** B1.13-S1: короткий ID в шапке витрины (> 8 символов → «1002…34»). */
export function formatProfileIdShort(id) {
  const s = String(id ?? "").trim()
  if (!s) return ""
  if (s.length <= 8) return s
  return `${s.slice(0, 4)}…${s.slice(-2)}`
}
