# Demo-логины стенда В2

**Демо-данные:** `demo-coffeeos`, пароль `demo123456` — полный список [`../veha_1/DEMO_LOGINS.md`](../veha_1/DEMO_LOGINS.md).

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

## Текущие демо-логины

| Email | Роль | Tenant | Панель |
|-------|------|--------|--------|
| uk@demo.coffeeos.local | uk_global_admin | demo-point-a | `/admin` |
| franchise@demo.coffeeos.local | franchise_manager | demo-point-a | `/manager` |
| gm-a@demo.coffeeos.local | general_manager | demo-point-a | `/manager` |
| gm-b@demo.coffeeos.local | general_manager | demo-point-b | `/manager` |
| **shift-a@demo.coffeeos.local** | **shift_manager** | demo-point-a | `/manager` |
| barista-a@demo.coffeeos.local | barista | demo-point-a | `/barista` |
| barista-b@demo.coffeeos.local | barista | demo-point-b | `/barista` |
| pk-manager@demo.coffeeos.local | prep_kitchen_manager | demo-prep-kitchen | `/prep_kitchen` |
| pk-worker@demo.coffeeos.local | prep_kitchen_worker | demo-prep-kitchen | `/prep_kitchen` |

> **⚠️ shift_manager (AUTH-06):** логин `shift-a@demo.coffeeos.local` через `/manager` — **PASS** *(прогон 6, 2026-05-30)*.

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

**Обновлено 2026-08-09:** канон Point A для MCP/приёмки.  
**Обновлено 2026-05-28:** добавлены все роли включая shift_manager; замечание AUTH-06 SKIP.
