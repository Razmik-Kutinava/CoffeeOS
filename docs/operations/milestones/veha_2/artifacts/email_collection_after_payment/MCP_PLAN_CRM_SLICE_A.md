# MCP Plan — #71 Slice A: CRM sync после оплаты (Brevo Contacts)

**После** `fly deploy`. Не Local-only: Fly Point A + Brevo / logs / Solid Queue.

| | |
|---|---|
| **CBR** | #71 Email-сбор · ST-9 CRM (Slice A) |
| **Код** | GREEN `cb1e336d` · `retry_on` `fecee7e3` · tip ≥ `23b59a7e` |
| **CI** | green [34207477722](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34207477722) |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Артефакт** | `mcp/fly_vNNN_YYYY-MM-DD/MCP_RESULT_CRM_SLICE_A.md` |

**Не путать:** #71 remember UX (v481) · #72 ОФД · Slice B bounce opt-out.

## Safety

- Тестовый email: `mcp71-crm-{YYYYMMDD}-{hex}@example.com`
- Не OTP/PAN в профиль Арама · `BREVO_API_KEY` не в скрины

## ENV

| Var | Нужно |
|-----|--------|
| `BREVO_API_KEY` | MUST (xkeysib API) |
| `BREVO_CRM_LIST_ID` | опц. |
| `CRM_SYNC_ENABLED` | ≠ `0` на smoke |

## Preflight

P0 `/up` · P1 shop · P2 release · P3 `Shop::CrmContactSync` + retry · P4 Brevo key set

## Сценарии

| # | Суть | PASS |
|---|------|------|
| C0 | pay Point A guest | order + email block |
| C1 | consent=false | email OK · **нет** контакта Brevo |
| C2 | consent=true | контакт Brevo + attrs |
| C3 | повтор sync | один контакт (upsert) |
| C4 | CRM fail | email API всё равно 200 · job retry |
| C5 | bounced | job no-op (Slice B OUT) |
| C6 | kill-switch | skip если не трогали |
| E1–E2 | email save / receipt | без reopen remember |

## Вердикт

**PASS** = C1+C2+C3 (+C5) · **PARTIAL** = контакт есть, attrs/list неполные · **FAIL** = consent gate / stub / email 5xx
