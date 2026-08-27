# #72 MCP Point A — чеклист для агента (после deploy)

**Кому:** агент, который делает **deploy + пачку приёмки + MCP**.  
**Этот файл:** что проверять по CBR **#72** (Receipt.Email / Phone в Init).  
**Не делать сейчас:** owner **не** деплоит в этой сессии (экономия) — чеклист на потом.

---

## Контекст (коротко)

| | |
|---|---|
| **CBR** | #72 |
| **Цель** | В Init Т-Банк уходит `Receipt` с контактом: приоритет **Email**, иначе **Phone** из `MobileCustomer` заказа. Чек шлёт **касса**, не наш mailer (#71). |
| **GREEN** | `5f68efea` · Entire `01M11269FD48FXF42NCW98AG0X` |
| **CI** | green [33051192100](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/33051192100) (и последующие docs на `develop`) |
| **Ветка** | `develop` (актуальный HEAD на момент handoff) |
| **ТЗ** | `docs/operations/milestones/veha_2/requirements/customer_tasks/Доработка бэкенда — передача email покупателя в Receipt для фискальных чеков.md` |
| **Bridge** | `docs/integrations/tbank.md` § Receipt contact policy (#72) |
| **Артефакты результата** | `docs/operations/milestones/veha_2/artifacts/receipt_email_fiscal_checks/mcp/fly_vNNN_YYYY-MM-DD/MCP_RESULT.md` |

**Point A:**  
`https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`

---

## Safety (обязательно)

- **Не** писать OTP / телефон / PAN / имя в профиль заказчика (Арам).
- Для live pay — отдельный **test-customer** / гостевая сессия Point A, не прод-профиль.
- Секреты Т-Банка **не** логировать и **не** класть в артефакт.

---

## Порядок работы агента

1. **Deploy** (только если owner явно апрувнул) → зафиксировать Fly version (`vNNN`).
2. **Пачка** (`coffeeos-dev-gates`): Sentry 24ч · Fly logs · Neon · УК Point A (лента сегодня/вчера) · **MCP** ниже.
3. Записать `MCP_RESULT.md` + скрины/логи в папку артефактов.
4. Ops: SESSION_STATE / HANDOFF / CHANGELOG · вердикт PASS / PARTIAL / FAIL.
5. **Не** ставить `[x]` заказчику без «ок» владельца.

---

## Preflight (до сценариев)

| # | Проверка | Как | PASS если |
|---|----------|-----|-----------|
| P0 | App up | `GET https://coffeeos.fly.dev/up` | 200 |
| P1 | Shop Point A | открыть Point A URL | каталог, не вечный skeleton |
| P2 | Release | `fly releases -a coffeeos` / статус | версия ≥ deploy с #72 |
| P3 | ENV ОФД | Fly secrets/env | `TBANK_TAXATION` / `TBANK_TAX` заданы или дефолты ок (`usn_income` / `none`) |
| P4 | Не путать с #71 | помнить | post-pay email-блок = mailer; Receipt = Init payload |

---

## MCP сценарии #72

### A — Smoke UI (без доказательства Receipt)

| # | Сценарий | Как | PASS / SKIP |
|---|----------|-----|-------------|
| A1 | Checkout identity | Point A → корзина → checkout | Callcheck/телефон; **нет** обязательного email-гейта на pay (#71) |
| A2 | Каталог/оплата не сломаны | меню + кнопка оплаты видна | нет 5xx на `/shop/api/*` |

### B — Live Init + Receipt.Phone (основной happy path Point A)

Callcheck даёт **phone** → после Init в Receipt должен быть **Phone** (если у customer нет валидного email).

| # | Сценарий | Как | PASS |
|---|----------|-----|------|
| B1 | Создать заказ + Init | test-guest: Callcheck → товар → оплата (СБП **или** карта) до Init | Init Success у банка / `provider_payment_id` на payment |
| B2 | Контакт = Phone | Neon/Postgres: `orders` → `mobile_customers.phone` (email NULL или пустой) | phone есть |
| B3 | Доставка чека | кабинет Т-Банк / Чеки Т-Бизнес **или** SMS/email от кассы на этот phone | чек прихода с контактом phone **или** явный лог Init без ErrorCode 329 |
| B4 | Fly logs | `fly logs -a coffeeos` вокруг Init | нет Exception на `TbankReceiptBuilder` / Init; нет «Нужен email или телефон» |

**Если live pay нельзя:** B1–B4 = **SKIP** + почему; тогда обязателен блок **D** (доказательство кода на стенде) — иначе вердикт только PARTIAL.

### C — Live Init + Receipt.Email (приоритет)

| # | Сценарий | Как | PASS |
|---|----------|-----|------|
| C1 | Customer с email+phone | test-customer: verified phone **и** валидный email на `MobileCustomer` | оба в БД |
| C2 | Init | оплата до Init | Success |
| C3 | Приоритет Email | кабинет кассы / факт доставки | чек на **email**, не дублировать канал как «только phone» |
| C4 | Невалидный email не уходит | (опц.) customer с битым email + phone → Init | контролируемая ошибка **до** банка; Init в Т-Банк **не** ушёл |

### D — Доказательство без live pay (минимум, если B/C SKIP)

| # | Сценарий | Как | PASS |
|---|----------|-----|------|
| D1 | Код на релизе | убедиться что release содержит `TbankReceiptBuilder.for_order!` / Init+receipt на SBP/card (diff `5f68efea` в deploy) | да |
| D2 | Разделение #71 | `Orders::EmailService` / `order_emails` **не** источник Receipt | как в #71 D5: mailer ≠ ОФД |
| D3 | Confirm без Receipt | docs + код: `confirm_payment` без Receipt | ожидаемо (не баг) |
| D4 | Cancel полный без Receipt | guest cancel / #40 | Cancel без Receipt; чек возврата — поведение кассы (зафиксировать) |

### E — Не ломать (регресс)

| # | Сценарий | PASS |
|---|----------|------|
| E1 | Callcheck / phone wizard | работает |
| E2 | #71 success email-блок (если смотреть UI) | опциональный; не гейтит pay |
| E3 | #69 ЛК / история | открывается |
| E4 | Полный Cancel #40 | не регресснуть Refund |

### F — Вне scope этого MCP (не FAIL #72)

| Тема | Статус |
|------|--------|
| Partial Cancel + Receipt | нет в продукте — не требовать |
| SendClosingReceipt / prepayment | N/A — только `full_payment` |
| Хранение чеков в ЛК | следующая задача серии |
| Собственная отправка ОФД-чека почтой | запрещено ТЗ |

---

## Пачка приёмки (вместе с MCP)

| Слой | Норма |
|------|--------|
| **Sentry 24h** | нет новых Issues после этой версии |
| **Fly logs** | нет 5xx / `TbankReceiptBuilder::Error` на happy path |
| **Neon** | заказ + customer phone/email согласованы с сценарием |
| **УК Point A** | лента сегодня/вчера; не чинить древний `pending_payment` |
| **MCP** | таблица A–E выше → `MCP_RESULT.md` |

---

## Шаблон `MCP_RESULT.md`

```markdown
# #72 MCP Point A — Fly vNNN — Receipt.Email/Phone

**Дата:** …
**Fly deploy:** vNNN · …
**Browser / tools:** …
**Live pay:** yes / no / partial

## Вердикт: PASS | PARTIAL | FAIL

| # | Result | Notes |
|---|--------|-------|
| P0–P4 | | |
| A1–A2 | | |
| B1–B4 | | или SKIP + почему |
| C1–C4 | | или SKIP |
| D1–D4 | | обязательно если B/C SKIP |
| E1–E4 | | |
| Sentry / logs / Neon / УК | | |

## Open
- полный Cancel: факт доставки чека кассой — …
```

---

## Копипаст промпта для агента

```
Задача: после deploy CoffeeOS на Fly — пачка приёмки + MCP Point A по CBR #72.

Канон чеклиста:
docs/operations/milestones/veha_2/artifacts/receipt_email_fiscal_checks/MCP_DEPLOY_CHECKLIST.md

Point A:
https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789

Правила:
- не OTP/PAN в профиль заказчика;
- результат → artifacts/receipt_email_fiscal_checks/mcp/fly_vNNN_YYYY-MM-DD/MCP_RESULT.md;
- вердикт PASS/PARTIAL/FAIL; live pay SKIP только с почему + блок D;
- не требовать SendClosingReceipt / partial Cancel / ЛК-чеки;
- отличить #71 mailer от ОФД Receipt.

Deploy уже сделан: vNNN (подставь). Сделай пачку + MCP, закоммить артефакт + ops.
```

---

## Локальный статус на момент handoff (без deploy)

| Слой | Статус |
|------|--------|
| Local / CI | PASS · CI green |
| Fly deploy | **не делали** (экономия) |
| Fly MCP | **ждёт** этот чеклист после deploy |
