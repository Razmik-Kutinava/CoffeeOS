# HANDOFF — Веха 2

## Шапка (агент читает только это + todo + ISSUES «🔴 Открыто»)

**Дата:** 2026-09-29 (TASK_97 intake)  
**Ветка:** `develop`

| Сейчас | Дальше |
|--------|--------|
| **`/crit-audit`** — конечный аудит критических: C1–C5 + падающий тест · журнал [`CRITICAL_LEDGER.md`](../dev/CRITICAL_LEDGER.md) · сам в `/review` шаг 2 · вердикт CLEAN/BLOCKED | первый запуск: дифф от `0a3ac0db` (v504) или «полный аудит» |
| **Fly v504** задеплоен (`0a3ac0db`, TASK_95–99) · CI green [36578912741](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36578912741) · миграции offer_states + marketing_events на проде · Sentry 24h 0 · logs без 5xx · [MCP_RESULT](../milestones/veha_2/artifacts/mcp/fly_v504_2026-09-29/MCP_RESULT.md) PASS wire/bundle | TASK_99 G4 iPhone · live offer после billing UI · `/review` #96, #98 |
| **TASK_98** события воронки + UTM · [Google Doc](https://docs.google.com/document/d/1XSqPUfCJYxBsEU8oxr8R6Exj9VibgQIPMsBqtYJUNzM/edit?usp=drivesdk) · ⊂ TASK_96 (код уже в `63a317a1`) · [GATES](../milestones/veha_2/artifacts/subscription_offer_funnel_utm/GATES.md) G1–G6 met (`--reverify`) · тест пустого отчёта `00bdcf64` (код не менялся) · /regress PASS 172/0 + JS 39/0 · G7 Fly после deploy | `/review` #98 |
| **TASK_99** iOS: системный диалог WebPush · [Google Doc](https://docs.google.com/document/d/1RFadqCs70QvUX2dFZmL98SEtPd1N5sGSEy-hNNrlVwU/edit) · GREEN `48fa2646` · [GATES](../milestones/veha_2/artifacts/ios_webpush_permission/GATES.md) G1–G3 met · REVIEW bugbot+security чисто · **CI green** [36578386943](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36578386943) на `180d88fc` · Entire `01M3PPE93CDW728HQ2PP4ZNDM8` | deploy по апруву → G4 физический iPhone (диалог сразу после клика, токен в БД) · G5 Fly MCP Point A |
| **TASK_97** intake `[x]` · [ТЗ](../milestones/veha_2/requirements/customer_tasks/TASK-97-Push-оффер-подписки.md) · [Google Doc](https://docs.google.com/document/d/1VN1VSBHuGtIjluoNFATbmAw0OsfL_UBqKnPho_fTtU4/edit?usp=drivesdk) · ⊂ TASK_96 Subtask 14–21 · [GATES](../milestones/veha_2/artifacts/subscription_offer_push/GATES.md) G1–G3 PASS · REVIEW: GREEN `c187fd81` (advisory lock) · Local 176/0 · bugbot+security чисто · GATES 5/6 · Entire `01M3PPMM60JNSPFRJXPD7PSENG` на `8473e541` · push `180d88fc` · CI/Semgrep/CodeQL green ([run](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36578386943)) | deploy только по апруву → G4 Fly MCP Point A |
| **TASK_96** intake `[x]` · [ТЗ](../milestones/veha_2/requirements/customer_tasks/TASK-96-Оффер-подписки-frontend-push-и-аналитика.md) · [Google Doc](https://docs.google.com/document/d/1kbB0iDYgFoioln0I2xUXeMBXWaKo_cKqDEfproHJN1M/edit?usp=drivesdk) | SPEC `[x]` ([todo](todo.md)) · **BLOCKED** — нет экрана оформления подписки (billing UI, Задача-3) → `/sbr` после · [GATES](../milestones/veha_2/artifacts/subscription_offer_frontend_push_analytics/GATES.md) G5–G6 PASS |
| **TASK_95** intake `[x]` · [ТЗ](../milestones/veha_2/requirements/customer_tasks/TASK-95-Состояние-оффера-подписки-на-гостя.md) · [Google Doc](https://docs.google.com/document/d/18f25SUyeTWwixkcDX9XvTedfkd8GzSO6lfjoCTNWzPA/edit?usp=drivesdk) | REVIEW `[x]` · **CI green** [36567405779](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36567405779) на `23565015` → deploy по апруву · G7 Fly MCP |
| **Fly v503** задеплоен (`2a9adacb`) · MCP Point A PASS · [MCP_RESULT](../milestones/veha_2/artifacts/mcp/fly_v503_2026-09-29/MCP_RESULT.md) | фото `/uploads` 404 — решение по хранилищу · OrderCreator wiring backlog |
| Point A offer OFF | повторное включение — после billing UI · live purchase подписки |

**last_done:** TASK_95 REVIEW — GREEN `42b61e1c` + bugbot fix `bb64f742` · Local 194/0 · bugbot+security чисто · Entire `01M3P4QA99DMBM0JSZYKKWSHZ5` · [GATES](../milestones/veha_2/artifacts/subscription_offer_guest_state/GATES.md) G1–G6 met  
**next_step:** TASK_95 CI green `23565015` (bump rack-proxy 2.0.1 / vite_ruby 3.11.0, GHSA-42qh-8mx8-7wqm) → deploy по апруву → G7 Fly MCP Point A · ⚠ локальный `develop` с RED `0a32d8fe` (#96) — не пушить до GREEN #96 · сообщить заказчику пробел ТЗ (`shown` endpoint) · параллельно — хранилище фото

**ctx_trim:** `2026-09-22`  
**Fly:** v504 · https://codeblack.coffee · app `coffeeos`  
**Витрина Point A:** https://codeblack.coffee/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Док Задачи-3:** https://docs.google.com/document/d/11AlzRrp8PomEvwrLPtp04ZhrbG2bYR9abSpjhwDnuCU/edit  
**CI:** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36253473587  
**Entire:** `01M3F6KCQVG7SF39R9KE8EEARD` на `0fe747a0`

**Архив session:** [`archive/README.md`](archive/README.md)  
**Архив journal:** [`../journal/archive/README.md`](../journal/archive/README.md)

---
