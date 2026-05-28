# Прогон приёмки Веха 2

**Зачем:** протокол, как [`../veha_1/QA_ACCEPTANCE_RUN.md`](../veha_1/QA_ACCEPTANCE_RUN.md) для В1 — заполнять **когда начнётся** приёмка В2 (не сейчас).

**Сценарии:** `docs/agents/AGENTS/qa_scenarios.md` — секции **[ВЕХА 2]**. **Чеклист:** [`CHECKLIST.md`](CHECKLIST.md) § I.

---

## Порядок этапов (план)

| Этап | Что | Инструмент | Статус |
|------|-----|------------|--------|
| **1. Сухой** | Тесты + новая org без demo seed | `bin/rails test`, integration | ✅ 541/0 *(2026-05-28)* |
| **2. MCP / браузер** | Онбординг, оплата, киоск | Chrome DevTools MCP | ✅ pre-prod *(2026-05-28)* |
| **3. Живое демо** | Заказчик | `LIVE_DEMO_SCENARIOS_PLAIN.md` | ⏳ |

---

## Подготовка (заполнить при прогоне)

| Шаг | Команда | Результат |
|-----|---------|-----------|
| Demo / чистая org | demo-point-a/b на Fly (`DEMO_LOGINS.md`) | ✅ |
| `bin/rails test` | полный suite | **541 runs, 0 failures** *(2026-05-28)* |
| `SHOP_SIMULATE_PAYMENT` | 0 на стенде | ✅ Fly secrets |

---

## Минимальный scope приёмки В2

1. Org + 3 точки из УК с address + карточка URL.
2. Витрина с **реальной** оплатой (или тестовым шлюзом).
3. QR URL открывается с телефона.
4. Kiosk — если § D чеклиста закрыт.
5. RBAC smoke всех ролей на **новой** org.

---

## Журнал прогонов

### Прогон 0 — pre-prod smoke (2026-05-28)

**Инструмент:** Chrome DevTools MCP на `coffeeos.fly.dev`  
**Цель:** smoke до переключения на боевой терминал (по запросу заказчика).

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| Health `/up` | PASS | |
| Suite 541/0 | PASS | |
| Shop A catalog | PASS | tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| Shop B catalog | PASS | tenant `655aaccb-004a-4bb9-a50a-ce618854dda3`, цены отличаются |
| Cart + checkout UI | PASS | |
| Order cash | PASS | `accepted`, 179₽ |
| Order card → T-Bank | **FAIL→PASS** | см. прогон 1 |
| Manager login | PASS | `shift-a@demo.coffeeos.local` → `/manager` |
| Kiosk | SKIP | Flutter |
| T-Bank callback E2E | SKIP | blocked by card FAIL |

**Блокер:** card/sbp — **закрыт** (`884cdea`).  
**Следующий шаг:** апрув → боевой терминал + smoke на prod.

### Прогон 1 — pre-prod smoke повтор (2026-05-28)

**Fix:** `80e38be` + `884cdea` — Circuit breaker на MemoryStore, не SolidCache.

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| Order card → T-Bank | **PASS** | 200, `payment_url` `https://pay.tbank.ru/liDXgYg9`, 179₽ на форме |
| Order cash | **PASS** | 200 `accepted` |
| Deploy | PASS | `884cdea` на Fly, release cleared CB cache |

**Вердикт:** готовы к боевому терминалу (ждёт апрув заказчика).
