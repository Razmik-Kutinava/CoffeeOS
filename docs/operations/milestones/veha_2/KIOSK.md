# Киоск — Веха 2

**Чеклист:** [`CHECKLIST.md`](CHECKLIST.md) § D. **Оплата:** [`PAYMENT.md`](PAYMENT.md) — **с оплатой сразу**, не «киоск без денег».

---

## Зачем документ

В В1 модуль `kiosk` — только `FeatureFlag` и `devices.device_type = kiosk`. В2 — **рабочий канал на точку** (отдельный UI, тот же tenant по slug).

---

## Модель

| Аспект | Решение |
|--------|---------|
| Изоляция | Один киоск = `Device` + `tenant_id` точки |
| URL | Поддомен точки `{slug}.{SHOP_BASE_DOMAIN}` + путь _TBD_ (`/kiosk`?) |
| Смена | Как shop: **без** `CashShift` (пока гибрид В1) |
| Заказ | Сервис по аналогии `Shop::OrderCreator` или общий |
| Оплата | Та же цепочка, что витрина § PAYMENT |

---

## Что есть в БД (В1)

- `devices` — `device_type: kiosk`
- `kiosk_settings`, `kiosk_carts`, `kiosk_sessions` — schema есть
- **Маршрутов / UI нет** в `config/routes.rb`

---

## План реализации

- [ ] Зафиксировать путь (например `/kiosk` на tenant host)
- [ ] Регистрация устройства из manager или УК
- [ ] Минимальный UI: каталог → корзина → оплата
- [ ] Строка в [`ORDER_ENTRY_AUDIT.md`](ORDER_ENTRY_AUDIT.md)
- [ ] URL в карточке онбординга [`ONBOARDING.md`](ONBOARDING.md)
- [ ] QA-сценарии в `qa_scenarios.md`

---

## Flutter

Если киоск на Flutter — см. [`FLUTTER.md`](FLUTTER.md); Rails-first MVP киоска может быть Hotwire на том же хосте.

---

## Статус

**2026-05-25:** документ и план; код **не начат**.
