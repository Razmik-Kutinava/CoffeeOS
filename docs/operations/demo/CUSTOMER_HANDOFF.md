# Передача заказчику — стенд Fly (прод, одна точка)

**Стенд:** https://coffeeos.fly.dev  
**Пароли:** переданы владельцу лично, в репозитории не хранятся.  
**Обновлено:** 2026-10-07 (после очистки прода 2026-10-06 демо-логины `*@demo.coffeeos.local` и `demo123456` не действуют).

---

## Вход

| Кто | Логин | Куда попадёте |
|---|---|---|
| Вход | https://coffeeos.fly.dev/login | — |
| УК (владелец) | `razmikg1988@gmail.com` | https://coffeeos.fly.dev/admin |
| Бариста «Витрины А» | `barista-code-black@codeblack.coffee` | табло https://coffeeos.fly.dev/barista |

---

## Витрина (гость, без логина)

| Точка | URL |
|-------|-----|
| «Витрина А» (`code_black`) | https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789 |

На проде одна точка; её `tenant_id` после деплоя не меняется.

**Поддомены** `*.coffeeos.fly.dev` на Fly **не используем** — см. [`../dev/SHOP_URL_MODES.md`](../dev/SHOP_URL_MODES.md).

---

## Техподдержка стенда

- Health: https://coffeeos.fly.dev/up  
- Ops: [`FLY_DEMO_STAND.md`](FLY_DEMO_STAND.md), [`../session/HANDOFF.md`](../session/HANDOFF.md)
