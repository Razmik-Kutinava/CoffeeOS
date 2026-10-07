# Логины стенда В2

**Прод (с 2026-10-06):** демо-логины `*@demo.coffeeos.local` точек и пароль `demo123456` удалены. Пароли реальных аккаунтов — у владельца, в репо не пишем.

---

## Канон приёмки Fly (агент / MCP)

| | |
|--|--|
| **Точка** | **Point A** только |
| **tenant_id** | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Shop URL** | `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |

**Запрещено для приёмки заказчика:** Fly Overnight / «ул. Fly Test» / inactive tenant как основной стенд.  
**Prod (2026-09-02):** одна active sales_point — Point A; см. [`runbooks/SINGLE_POINT_A.md`](../runbooks/SINGLE_POINT_A.md).  
**Профиль Арама:** читать/смотреть сценарии можно; **не** писать тестовый OTP/телефон/PAN в его customer.

---

## Текущие логины (прод)

Вход: https://coffeeos.fly.dev/login

| Email | Роль | Точка | Панель |
|-------|------|-------|--------|
| razmikg1988@gmail.com | uk_global_admin + franchise_manager | «Витрина А» (`code_black`) | https://coffeeos.fly.dev/admin |
| barista-code-black@codeblack.coffee | barista | «Витрина А» (`code_black`) | https://coffeeos.fly.dev/barista |
| pk-manager@demo.coffeeos.local | prep_kitchen_manager | цех `demo-prep-kitchen` (не тронут) | `/prep_kitchen` |
| pk-worker@demo.coffeeos.local | prep_kitchen_worker | цех `demo-prep-kitchen` (не тронут) | `/prep_kitchen` |

Удалены 2026-10-06: `uk@demo`, `franchise@demo`, `gm-a`/`gm-b`, `shift-a`, `barista-a`/`barista-b` (точки `demo-point-b` больше нет).

---

## Шаблон для новой org (заполнить после онбординга)

| Email | Роль | Точка (slug) | Панель / URL |
|-------|------|--------------|--------------|
| | uk_global_admin | — | `/admin` |
| | franchise_manager | org | `/manager` |
| | general_manager | | `/manager` |
| | shift_manager | | `/manager` |
| | barista | | `/barista` |
| | prep_kitchen_manager | кухня | `/prep_kitchen` |

**Пароль:** ____________

**Витрины:**

| Точка | Shop URL |
|-------|----------|
| | Режим A: `https://{slug}.{SHOP_BASE_DOMAIN}/shop` · Fly: `demo:shop_urls` |

---

**Обновлено 2026-10-07:** прод — одна точка, реальные логины УК и бариста; демо-логины точек удалены.  
**Обновлено 2026-08-09:** канон Point A для MCP/приёмки.  
**Обновлено 2026-05-28:** добавлены все роли включая shift_manager; замечание AUTH-06 SKIP.
