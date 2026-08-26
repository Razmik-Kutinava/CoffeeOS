# #71 — MCP / Fly приёмка после deploy (для агента)

**Не деплоить из этого файла** — только чеклист **после** `fly deploy` по апруву владельца.

**ТЗ:** [Email-сбор после оплаты (Callcheck-флоу)](../requirements/customer_tasks/Email-сбор%20после%20оплаты%20(Callcheck-флоу).md)  
**CBR:** #71 · **GREEN/fix:** `94f36822` · **CI:** [32971396113](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/32971396113) · **Entire:** `01M0Z3E52ZCDTRECJT1F22G954`

**Point A:**  
`https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`

**Артефакты MCP:** класть сюда `mcp/fly_vNNN_YYYY-MM-DD/` (скрины + `MCP_RESULT.md`).

---

## 0. Перед MCP (обязательно)

| # | Проверка |
|---|----------|
| 0.1 | CI green на `develop` после merge/deploy-кандидата |
| 0.2 | Deploy только по **апруву владельца** |
| 0.3 | На Fly задан секрет bounce: `EMAIL_BOUNCE_WEBHOOK_SECRET` **или** уже есть `CALLBACK_SHARED_SECRET` (HMAC для `POST /callbacks/email/bounce`) |
| 0.4 | Миграция `order_emails` применена на prod (`fly ssh` / release migrate — как принято в репо) |
| 0.5 | `/up` → 200 · версия release = ожидаемый deploy |

**Safety:** не OTP/PAN/реальный email заказчика в профиль Арама; для эксперимента — отдельный test-customer / guest-сессия.

---

## 1. Hot-path MCP Point A (Chrome / cursor browser)

### 1.1 Checkout — нет email-гейта

| # | Шаг | Ожидание | PASS? |
|---|-----|----------|-------|
| A1 | Открыть Point A → корзина → оформление | Нет поля `type=email`, нет email-OTP на экране оплаты | |
| A2 | Identity = Callcheck/телефон | Кнопка оплаты доступна при верифицированном телефоне **без** email | |
| A3 | (опц.) Новая карта | Toggle «Сохранить карту…» есть и **не** блокирует Pay | |

### 1.2 Success — email-блок после оплаты

| # | Шаг | Ожидание | PASS? |
|---|-----|----------|-------|
| B1 | Успешная оплата (simulate / тестовая карта / СБП test — что разрешено на стенде) | Экран success: текст **«Чек сформирован»** | |
| B2 | На том же экране | Блок **«Куда прислать чек и предложения»** + поле email + чекбокс маркетинга (opt-in off) + **Пропустить** | |
| B3 | Не заполняя email → Пропустить / дальше | Навигация без ошибки, без повторного обязательного запроса | |
| B4 | Невалидный email (`bad@`) | Inline «Некорректный email», **без** успешного сетевого save | |
| B5 | Валидный email + Submit | 200 / success; уход на заказ; **не** ждать отправки письма в UI | |
| B6 | (СБП) «Я оплатил» при CONFIRMED | После confirm виден **тот же** email-блок (не застревает на waiting-for-bank) | |

### 1.3 Не ломать (smoke)

| # | Шаг | Ожидание | PASS? |
|---|-----|----------|-------|
| C1 | Callcheck/phone wizard | Работает как до #71 | |
| C2 | История / ЛК (#69) | Открывается | |
| C3 | Telegram support (#70) | Deep link `t.me/code_black_support_bot` | |

---

## 2. API / backend на Fly (по возможности)

| # | Проверка | Ожидание |
|---|----------|----------|
| D1 | `POST /shop/api/orders/:id/email` с session/reconnect_token | 200, `success: true`; без OTP |
| D2 | Тот же POST **без** session/token на чужой order | 404 |
| D3 | `POST /callbacks/email/bounce` **без** `X-Webhook-Signature` | 401 |
| D4 | Bounce с валидным HMAC | 200; `order_emails.status=bounced` (если есть строка) |
| D5 | Заказ без email | Кассовый/ОФД чек не зависит от email (нет регресса fiscal) |

Сеть: путь клиента = `api('/orders/:id/email')` → `/shop/api/orders/:id/email` (не двойной `/shop/api/shop/api/...`).

---

## 3. Пачка приёмки (вместе с MCP, не вместо)

| Слой | Что смотреть |
|------|----------------|
| Sentry 24h | Нет всплеска ошибок `OrderEmail` / `EmailBounce` / PaymentResult |
| Fly logs | Нет 5xx на `orders/.../email` и `/callbacks/email/bounce` |
| Neon | Таблица `order_emails` существует; RLS/tenant на orders ок |
| УК Point A | Лента заказов сегодня; не чинить древний `pending_payment` мусор |

---

## 4. Отчёт агента (обязательный формат)

```
Local: skip (уже CI green) | или повтор smoke
Fly deploy: vNNN
Fly MCP Point A: PASS | FAIL | PARTIAL
  A1–A3: …
  B1–B6: …
  C1–C3: …
Sentry / logs / Neon / УК: …
Артефакты: artifacts/email_collection_after_payment/mcp/fly_vNNN_…
ENV bounce secret: set | missing
```

**FAIL →** не ставить апрув заказчику; фикс через `/sbr` или ISSUES.

---

## 5. Вне scope этого MCP

- Реальный CRM-провайдер (job пока placeholder/log)
- OTP для email
- SMS-копия чека
- Профиль Арама / боевой PAN
