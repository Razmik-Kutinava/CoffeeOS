# Передача заказчику — живое демо В1 (Fly)

**Стенд:** https://coffeeos.fly.dev  
**Пароль всех демо-аккаунтов:** `demo123456`  
**Сценарии:** [`../milestones/veha_1/qa/LIVE_DEMO_SCENARIOS_PLAIN.md`](../milestones/veha_1/qa/LIVE_DEMO_SCENARIOS_PLAIN.md) (§ 10 — минимум 4 истории)

---

## Вход

| | |
|---|---|
| Страница | https://coffeeos.fly.dev/login |
| УК | `uk@demo.coffeeos.local` |
| Бариста точка A | `barista-a@demo.coffeeos.local` |
| Менеджер точка A | `gm-a@demo.coffeeos.local` |
| Полная таблица | [`../milestones/veha_1/reference/DEMO_LOGINS.md`](../milestones/veha_1/reference/DEMO_LOGINS.md) |

---

## Витрины (гость, без логина)

| Точка | URL |
|-------|-----|
| A | https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789 |
| B | https://coffeeos.fly.dev/shop?tenant_id=655aaccb-004a-4bb9-a50a-ce618854dda3 |

После нового деплоя UUID могут смениться — см. [`FLY_DEMO_STAND.md`](FLY_DEMO_STAND.md) § «Узнать URL без SSH».

**Поддомены** `demo-point-a.coffeeos.fly.dev` на Fly **не используем** — см. [`../dev/SHOP_URL_MODES.md`](../dev/SHOP_URL_MODES.md).

---

## Техподдержка стенда

- Health: https://coffeeos.fly.dev/up  
- Ops: [`FLY_DEMO_STAND.md`](FLY_DEMO_STAND.md), [`../session/HANDOFF.md`](../session/HANDOFF.md)
