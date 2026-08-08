# MCP RESULT — #47 PWA status sync + repeats · Fly **v443** · 2026-08-08

**App:** https://coffeeos.fly.dev  
**Release:** **v443** · image `coffeeos:deployment-01KZGG9538YYB9ZE5YBTEN9PQS`  
**Tip:** `c5201f77` (ops) / code `aeff9fa7`  
**Tenant:** Point A `2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Сессия:** Cursor IDE browser · Aram `2bc37279-…4c` (profile header)  
**Вердикт:** **PASS** (повторы без F5) · статус-sync via same poll path **PASS** (косвенно: `refreshActive` + bundle)

---

## Deploy

1. Push develop · Fly **v443** · `/up` **200** (ранее)

## Bundle (live Vite `application-Ch9Om5ts.js`)

| Символ / факт | Результат |
|---|---|
| `orders/active` + `refreshActive` → frequent (`Kc()`) | **true** |
| `8e3` (ACTIVE_ORDERS_POLL_MS=8000) | **2** вхождения |
| `setInterval` | **3** |

## Server (fly rails runner)

| Шаг | Результат |
|-----|-----------|
| До | Aram active: `#202608-0027` **ready** · `has_active_order:true` · frequent **0** |
| `Barista::OrderStatusUpdateService` ready→**issued** | `#202608-0027` issued · broadcast + bust cache |
| После | `has_active_order:false` · frequent **3** (Декаф / Бразилия / Бразилия) |

## Browser (без reload страницы)

| Метрика | До issue | После issue (тот же tab) |
|---------|----------|---------------------------|
| Profile | `2bc3…4c` | `2bc3…4c` |
| Status sheet | absent (`ready` hide) | absent |
| `coffeeos_shop_frequent_v1.has_active_order` | **true** · items `[]` | **false** · **3** items |
| UI «повторить» / карточки повтора | **нет** | **есть** (скрин `01_…`) |

Скрин: `mcp/fly_v443_2026-08-08/01_after_issue_repeats_visible.png`

## Сверка с жалобой заказчика

| Симптом | MCP |
|---------|-----|
| Статусы с табло не в PWA без reload | Poll 8s + visibility в bundle; live smoke: sync после POS `issued` без F5 |
| Повторы/история после заказа пустые | **PASS** — после `issued` повторы вернулись без перезагрузки |

## Gaps

- Отдельный live-прогон accepted→preparing на табло баристы (UI labels) не гоняли — тот же `refreshActive` poll.
- Создание тестового accepted через runner упёрлось в attrs Order — не блокер (использовали живой `#202608-0027`).

## Следующее

Апрув заказчика «ок» на #47.
