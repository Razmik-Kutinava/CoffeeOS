# MCP #71 CRM Slice A · Fly v490 · 2026-09-08

| Поле | Значение |
|------|----------|
| Point A | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| Вердикт | **PASS** (attrs custom PARTIAL) |
| Guest | `mcp77-d746c70f@demo.coffeeos.local` (не Арам) |
| Order | `379472aa-7258-4858-b7e4-e00988cc9f9f` (ready) |

## Preflight
- P0–P2 PASS (v490)
- P3 `Shop::CrmContactSync` на машине PASS
- P4 `BREVO_API_KEY` set; `CRM_SYNC_ENABLED` unset (≠0) PASS

## Сценарии
| # | Result | Notes |
|---|--------|-------|
| C0 | SKIP live pay | использован существующий ready order |
| C1 consent=false | **PASS** | email save 200; Brevo GET → 404 document_not_found |
| C2 consent=true | **PASS** | email `mcp71-crm-yes-20260908-a1b2@example.com`; job enqueued+performed ~495ms; Brevo GET **200** contact exists |
| C2 attrs | **PARTIAL** | `attributes` slice пустой в Brevo (custom attrs не видны / не созданы в кабинете) |
| C3 idempotency | **PASS** | `perform_now` повтор без ошибки |
| C4 | PASS smoke | email API 200 при CRM async |
| C5 bounce | SKIP | не гоняли webhook |
| C6 kill-switch | SKIP | не трогали |
| E1–E2 | PASS | save + receipt queued (`queued_receipt:true`, status sent) |

## Пачка
- Sentry 24h unresolved: **0**
- Fly logs: SyncContactToCrmJob ok; API key не утекал
- Neon MCP: local mirror ≠ Fly (пусто) — проверка через `fly ssh` rails runner

## Не сделано
- Slice B opt-out
- Live pay C0 (не обязателен при готовом ready order)
