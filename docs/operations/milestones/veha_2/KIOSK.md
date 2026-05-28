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

## Что готово сейчас (2026-05-28)

| Компонент | Статус |
|-----------|--------|
| БД: `devices`, `kiosk_settings`, `kiosk_carts`, `kiosk_sessions` | ✅ готово |
| `Device` модель + `device_token`, `tenant_id`, `online?` | ✅ готово |
| Оплата Т-Банк (`TbankAdapter`, callback, `PaymentStatusUpdater`) | ✅ готово, переиспользуется |
| Заказ (`Shop::OrderCreator`) | ✅ готово, переиспользуется |
| Маршруты `/kiosk/api/...` | ❌ нет |
| Аутентификация планшета по `device_token` | ❌ нет |
| UI регистрации устройства в УК/manager | ❌ нет |

---

## Что ждёт Flutter

Блок заморожен до появления Flutter-приложения. Когда будет готово:

1. **Регистрация устройства** — кнопка в УК/manager → создаёт `Device(device_type: kiosk)` → выдаёт `device_token` (QR или ручной ввод на планшете)
2. **Auth API** — `POST /kiosk/api/auth` → Flutter даёт `device_token` → получает `tenant_id` + подтверждение
3. **Kiosk API** — меню, корзина, заказ (переиспользует логику shop)
4. **Тест приёмки** — симуляция через браузер/Postman с `X-Device-Token` заголовком, потом на реальном планшете

---

## API контракт (черновик для Flutter)

```
POST /kiosk/api/auth
  Header: X-Device-Token: <token>
  Response: { tenant_id, tenant_name, kiosk_settings }

GET  /kiosk/api/products        (те же что /shop/api/products)
POST /kiosk/api/cart/add
POST /kiosk/api/orders          (те же что /shop/api/orders → payment_url)
GET  /kiosk/api/orders/:id
```

---

## Симуляция на приёмке (без Flutter)

Пока Flutter нет — имитируем через браузер или Postman:
1. Создать `Device(device_type: kiosk, tenant_id: ...)` через Rails console
2. Открыть витрину `/shop?tenant_id=...` — это тот же pipeline
3. Оформить заказ с оплатой картой → проверить `accepted`
4. **Полноценный тест** — только когда будет реальный Flutter на планшете

---

## Статус

**2026-05-25:** документ и план; код не начат.  
**2026-05-28:** фундамент (БД, оплата, заказ) готов; ждём Flutter-приложение.
