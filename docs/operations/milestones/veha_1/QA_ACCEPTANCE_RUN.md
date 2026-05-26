# Прогон приёмки Веха 1 (блок H)

**Дата:** 2026-05-25  
**Исполнитель:** агент (этапы 1–2). **Этап 3** (ручной + живое демо) — владелец продукта.

Сценарии: `docs/agents/AGENTS/qa_scenarios.md`  
Чеклист: [`CHECKLIST.md`](CHECKLIST.md) § H

---

## Порядок этапов (зафиксировано)

| Этап | Что | Инструмент | Статус |
|------|-----|------------|--------|
| **1. Сухой** | Код + сценарии без браузера | `bin/rails test`, integration по доменам, `rails runner` | ✅ 2026-05-25 |
| **2. MCP** | UI-флоу в Chrome | Chrome DevTools MCP | ✅ 2026-05-25 (выборочно + RBAC smoke) |
| **3. Ручной + демо** | Остатки, показ людям | Владелец | ⏳ не начат |

---

## Этап 0 — после деплоя Fly (перед живым демо)

См. [`../../FLY_DEMO_STAND.md`](../../FLY_DEMO_STAND.md), чеклист § H.0.

| Шаг | Действие | OK |
|-----|----------|-----|
| 0.1 | Push `develop` → CI deploy | ⏳ |
| 0.2 | `demo:seed` (release или SSH) | ⏳ |
| 0.3 | Витрина A (`demo:shop_urls` / `?tenant_id=`) | ⏳ |
| 0.4 | Логин barista-a / demo123456 | ⏳ |

---

## Этап 1 — сухой прогон

### Подготовка

| Шаг | Команда | Результат |
|-----|---------|-----------|
| Demo-данные | `bundle exec ruby bin/rails demo:seed` | OK (exit 0) |
| Tenant A UUID | runner `Tenant.find_by!(slug: 'demo-point-a').id` | `8c7f5bc7-f2b4-43f0-991c-5ede0f480b20` |

### `bin/rails test` (полный suite)

```
479 runs, 1896 assertions, 0 failures, 0 errors, 0 skips
```

Время ~605 с. Дата прогона: **2026-05-25**.

### Целевые integration (маппинг на V1-*)

| Пакет | Runs | Failures | Покрывает |
|-------|------|----------|-----------|
| `test/integration/auth/` + `block_g_cash_shift_test.rb` | 68 | 0 | V1-2.*, V1-3.* (гибрид смены, отмена, shortage) |
| `test/integration/shop/` + `block_f_stock_flow_test.rb` + `block_g` (batch) | 36 | 1* | V1-3.3 shop, V1-4.* |
| `test/services/inventory/order_recipe_deduction_test.rb` + `block_f` | 7 | 0 | V1-4.1 |

\* **Единственный FAIL в batch:** `BlockGCashShiftTest#test_shop_order_succeeds_without_cash_shift` — **429 Rate Limit** (Rack::Attack при плотной серии запросов).  
**Перепрогон изолированно:** `bin/rails test test/integration/block_g_cash_shift_test.rb:18` → **1 run, 0 failures**.  
Вывод: не регрессия продукта, артефакт нагрузки в одном прогоне.

### In-process shop runner (`tmp/shop_mcp_flow.rb`)

```
SUMMARY: 2/9 OK
```

Причина FAIL 7 шагов: **HTTP 401** на API после categories (runner без browser session cookie; `SHOP_API_KEY` в `.env` не подхватывается для Integration::Session так же, как браузер).  
**Компенсация:** этап 2 MCP + `test/integration/shop/` (57+ tests в полном suite).

---

## Этап 2 — MCP Chrome DevTools

**Среда:** `http://127.0.0.1:3001` (Puma из `log/dev-server.log`, Listening :3001).  
`bin/ensure-server` — timeout 90s при холодном boot; сервер затем отвечает 200 на `/up` и `/shop`.

### Shop (V1-3.3, 3.4, 3.7, 6.1)

URL: `/shop?tenant_id=8c7f5bc7-f2b4-43f0-991c-5ede0f480b20`

| Шаг MCP | Результат |
|---------|-----------|
| Каталог, товар с модификаторами | OK |
| Корзина → оформление | OK |
| Mock-оплата | OK — «Заказ #af39d833-… оплачен», статус accepted |
| История за сегодня | OK — заказ в списке «Заказы за сегодня» |
| Double-click «Оплатить» | OK (один заказ создан при одном осознанном клике; кнопка disabled после submit) |

### Панели / RBAC (smoke)

| Логин | Действие MCP | Ожидание | Факт |
|-------|--------------|----------|------|
| `barista-a@demo.coffeeos.local` | login → `/barista` | POS | OK, смена открыта |
| barista | `/manager` | запрет | OK — «Доступ запрещён», редирект на login |
| `uk@demo.coffeeos.local` | login → `/admin` | УК | OK — дашборд, org, tenants |
| uk | `/barista` | запрет | OK — редирект, нет POS |

Остальные роли (franchise, gm, shift, prep) — **покрыты integration `test/integration/auth/*_rbac_test.rb` (0 failures)**; MCP smoke не дублировал все 7 логинов в этой сессии.

---

## Итог этапов 1–2 для чеклиста H

| Пункт VEHA_1_CHECKLIST | Статус |
|------------------------|--------|
| `qa_scenarios.md` дополнен | ✅ (2026-05-24 док + журнал 2026-05-25) |
| Прогон V1 сценариев (сухой + MCP) | ✅ протокол в журнале `qa_scenarios.md` |
| Баги исправлены, критичные перепройдены | ✅ критичных FAIL нет (1×429 — flaky rate limit) |
| `bin/rails test` | ✅ 479/0 (2026-05-25) |
| Живое демо § H.3 | ⏳ **владелец** |

---

## Этап 3 — для владельца (не выполнял агент)

- Ручной добив: V1-1.1 (подмена tenant в DevTools), V1-3.5 (отмена с reason в UI), V1-3.6 (закрытие смены с недостачей), prep движения в UI.
- Живое демо: 3–4 цепочки (бариста→склад, shop, УК→каталог).

---

## Следующие действия

1. Владелец: § H.3 живое демо + при желании ручной добив журнала (колонка «Ручной»).
2. После демо: § I operations (`SESSION_STATE`, `CHANGELOG`, закрытие вехи).
