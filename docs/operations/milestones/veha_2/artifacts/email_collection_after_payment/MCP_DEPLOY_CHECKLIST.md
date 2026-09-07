# #71 QA reopen — MCP Point A чеклист (remember receipt email)

**Кому:** агент, который делает **deploy + пачку приёмки + MCP** (не эта сессия — deploy один раз другим агентом).  
**Этот файл:** что проверить по QA reopen **#71**: после первого email для чека — **не спрашивать** на следующих заказах.  
**Не делать сейчас:** deploy в этой сессии **нет**.

---

## Контекст (коротко)

| | |
|---|---|
| **CBR** | #71 · QA reopen 2026-09-06 |
| **Цель заказчика** | «когда спрашиваем почту после оплаты для чека, запомнить не спрашивать в последующем заказы» |
| **Канон кода** | `loadReceiptEmail` / `saveReceiptEmail` (`shop_receipt_email:{tenant_id}` LS) · `shouldAskReceiptEmail(savedReceipt)` · hide `OrderSuccessEmailBlock` **только** если LS receipt не пуст (не guest profile email) |
| **GREEN** | `870df0be` · bugbot fix `0c17ee9f` |
| **Entire** | `01M1V2FH9A8C7J6X35YF5RQSFE` |
| **CI** | green [34026912791](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34026912791) (+ follow-ups на `develop`) |
| **Ветка** | `develop` |
| **ТЗ** | `docs/operations/milestones/veha_2/requirements/customer_tasks/Email-сбор после оплаты (Callcheck-флоу).md` § QA reopen |
| **Артефакты результата** | `docs/operations/milestones/veha_2/artifacts/email_collection_after_payment/mcp/fly_vNNN_YYYY-MM-DD/` → `MCP_RESULT.md` + PNG |

**Point A:**  
`https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`

**Не путать:**
- #71 mailer / post-pay UI ≠ #72 Receipt в Init ОФД
- Prefill из `loadGuestProfile().email` **не** скрывает блок (bugbot); скрытие = только `shop_receipt_email` после успешного submit

---

## Safety (обязательно)

- **Не** писать OTP / телефон / PAN / имя в профиль заказчика (Арам).
- Тестовый email только вида `mcp71-remember-…@example.com` (не личный inbox заказчика).
- Секреты / `CALLBACK_*` / API keys **не** в скрины и не в `MCP_RESULT.md` целиком.
- Live pay — отдельный test-guest / чистая сессия (incognito / clear site data Point A), не прод-профиль.

---

## Порядок работы агента

1. **Deploy** (только если owner апрувнул в **той** сессии) → зафиксировать Fly `vNNN`.
2. Preflight P0–P3 ниже.
3. Прогнать сценарии **R** (remember) + smoke **A/B** из старого #71 при необходимости.
4. Пачка (`coffeeos-dev-gates`): Sentry 24ч · Fly logs · Neon · УК Point A · MCP.
5. Записать `mcp/fly_vNNN_YYYY-MM-DD/MCP_RESULT.md` + скрины.
6. Ops: SESSION_STATE / HANDOFF / CHANGELOG · вердикт PASS / PARTIAL / FAIL.
7. **Не** `[x]` заказчику без «ок» владельца.

---

## Preflight

| # | Проверка | Как | PASS если |
|---|----------|-----|-----------|
| P0 | App up | `GET https://coffeeos.fly.dev/up` | 200 |
| P1 | Shop Point A | открыть Point A URL | каталог, не вечный skeleton |
| P2 | Release | `fly releases -a coffeeos` | версия ≥ deploy с #71 remember (`0c17ee9f`+ в бандле) |
| P3 | Bundle marker | в shop JS есть `loadReceiptEmail` / `shop_receipt_email` / `askReceiptEmail` | строки в бандле (не старый FE) |

---

## MCP сценарии — QA reopen (главное)

> Можно **без live pay**: форсировать success через `#/payment-result?status=ok&order_id=<существующий_order_id>` (как B1 в v458). Live pay = бонус, не блокер для этого QA, если forced path честный.

### R — Remember / don’t re-ask

| # | Сценарий | Как | PASS |
|---|----------|-----|------|
| R0 | Чистый старт | Incognito **или** Application → Local Storage: удалить ключи `shop_receipt_email:2fdee1ac-4674-41ee-b89e-87b45643f789` и при необходимости `shop_guest_profile:…` | ключа receipt нет |
| R1 | Первый success — блок **есть** | Point A → `#/payment-result?status=ok&order_id=…` (валидный order Point A) | «✔ Чек сформирован» + блок «Куда прислать чек и предложения» (`data-testid=order-success-email-block`) |
| R2 | Submit email | ввести `mcp71-remember-<ts>@example.com` → отправить | 200 / UI уходит дальше (каталог); **нет** ошибки; в LS появился `shop_receipt_email:…` с этим email |
| R3 | Второй success — блока **нет** | снова `#/payment-result?status=ok&order_id=…` (тот же или другой order, **та же** вкладка/origin) | «✔ Чек сформирован» · **нет** `order-success-email-block` · есть CTA «В каталог» (`payment-result-continue`) |
| R4 | Skip не запоминает | **новая** чистая сессия (R0) → success → **Пропустить** без email → снова success | блок **снова есть** (Skip не пишет LS) |
| R5 | Profile email ≠ hide | чистая LS receipt + (опционально) guest profile с email **без** `shop_receipt_email` → success | блок **есть** (не скрывать по profile) — регресс bugbot |
| R6 | Tenant key | при смене `tenant_id` в URL другой точки (если есть Demo B) LS ключ другой | не подмешивает email Point A на чужой tenant |

### A — Smoke (не ломать старое #71)

| # | Сценарий | PASS |
|---|----------|------|
| A1 | `#/checkout` без `input[type=email]` / OTP email | как раньше |
| A2 | Invalid email `bad@` → inline «Некорректный email», без POST | как B4 v458 |
| A3 | Callcheck/phone wizard жив | нет 5xx на identity |

### D — API (опционально, если трогаете backend)

| # | Сценарий | PASS |
|---|----------|------|
| D1 | `POST /shop/api/orders/:id/email?tenant_id=PointA` + shop API key + `reconnect_token` | 200 `success` / `queued_receipt` |
| D2 | без `tenant_id` | не принимать ложный 404 на `test-cafe` как PASS для Point A |

---

## Скрины (минимум в артефакт)

| Файл | Содержание |
|------|------------|
| `01_first_success_email_block.png` | R1 — блок виден |
| `02_after_submit_ls_or_catalog.png` | R2 — после submit |
| `03_second_success_no_block.png` | R3 — блока нет, «В каталог» |
| `04_skip_then_block_again.png` | R4 — после Skip блок снова |
| `05_profile_email_still_asks.png` | R5 — (если делали) |

---

## Пачка приёмки (вместе с MCP)

| Слой | Норма |
|------|--------|
| Sentry 24h | нет новых Unresolved после этой версии |
| Fly logs | нет 5xx на `EmailController` / shop payment-result вокруг прогона |
| Neon | опционально: `order_emails` после D1 |
| УК Point A | лента сегодня/вчера OK (не чинить демо-мусор) |

---

## Вердикт

| Итог | Когда |
|------|--------|
| **PASS** | R0–R4 PASS (+ R5 желательно); P0–P3; скрины в папке; пачка без аварии |
| **PARTIAL** | Forced success OK, но live pay / R5 / tenant R6 SKIP с причиной |
| **FAIL** | R3 показывает блок снова после submit **или** R5 скрывает блок только из profile **или** бандл без `loadReceiptEmail` |

---

## Шаблон `MCP_RESULT.md`

```markdown
# #71 QA reopen MCP — Fly vNNN — remember receipt email

**Дата:** YYYY-MM-DD  
**Fly:** vNNN  
**Browser:** Chrome MCP  
**Point A:** tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789

## Preflight
P0–P3: …

## R — Remember
| # | Result | Notes |
|---|--------|-------|
| R0 | | |
| R1 | | |
| R2 | | |
| R3 | | |
| R4 | | |
| R5 | | |
| R6 | SKIP/… | |

## A — Smoke
…

## Вердикт
PASS | PARTIAL | FAIL — …
```

---

## Команды агенту (копипаст)

```text
После deploy Fly coffeeos:
1) Читать этот чеклист целиком.
2) Point A shop URL + tenant выше.
3) Прогнать R0–R4 (R5 обязательно если есть время).
4) Артефакты → artifacts/email_collection_after_payment/mcp/fly_vNNN_YYYY-MM-DD/
5) MCP_RESULT.md + PNG; ops HANDOFF/CHANGELOG; вердикт.
6) Не трогать профиль Арама; не деплоить повторно без апрува.
```
