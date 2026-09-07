# MCP #80 — Fly v482 — 2026-09-07

Point A · tip `4f980e96` · **v482**

| ID | Result | Notes |
|----|--------|-------|
| P0–P2 | PASS | `/up` 200 · shop 200 · v482 |
| P3 bundle | PASS | `phone-auth-tel-btn` / `init_callcheck` / `check_status` / регистрац в Checkout chunk |
| K0 | PASS | `#/checkout` → «Вход по телефону» + шторка `+2₽` |
| K1 | SKIP | MCP desktop: visualViewport не сжимается (нет soft KB) — hide CTA не воспроизводится |
| K2 | SKIP | зависит от K1 |
| C0–C3 | PASS | Callcheck screen: hint «регистрация» + «номер в кнопке»; link `tel:` +7 (499)…; SMS fallback; без Email/radio |
| V0 | PASS | poll path present (`check_status` in bundle); UI «Ждем ваш звонок…» |
| V1–V2 live | PARTIAL | `SHOP_OTP_LOG_FALLBACK=true` на Fly — live Callcheck не обязателен; owner-skip live |
| S1–S3 | PASS | нет Email/radio; «Изменить номер» есть; CTA витрины жив |

**Local:** skip (CI green)  
**Fly MCP:** **PARTIAL** (K desktop skip + V without live Callcheck due to OTP log fallback)

Screens: `01_phone_input.png`, `02_callcheck_or_sms_step.png`
