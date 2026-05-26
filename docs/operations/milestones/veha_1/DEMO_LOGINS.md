# Demo-логины (единый источник правды)

**Код:** `app/services/demo/environment_setup.rb`  
**Задачи:** `bin/rails demo:seed`, `bin/rails test:create_test_users` (дубль, те же данные)

**Пароль всех пользователей:** `demo123456` (`Demo::EnvironmentSetup::DEMO_PASSWORD`)

**Организация:** `demo-coffeeos`  
**Точки:** `demo-point-a`, `demo-point-b`, `demo-prep-kitchen` (цех)

### Витрины на Fly (режим B, без поддомена)

| Точка | Shop URL |
|-------|----------|
| A | https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789 |
| B | https://coffeeos.fly.dev/shop?tenant_id=655aaccb-004a-4bb9-a50a-ce618854dda3 |

См. [`../../CUSTOMER_HANDOFF.md`](../../CUSTOMER_HANDOFF.md), [`../../SHOP_URL_MODES.md`](../../SHOP_URL_MODES.md).

| Email | Роль | Tenant | После login |
|-------|------|--------|-------------|
| uk@demo.coffeeos.local | ук_global_admin | A | `/admin` |
| franchise@demo.coffeeos.local | franchise_manager | A (+ org) | `/manager` |
| barista-a@demo.coffeeos.local | barista | A | `/barista` |
| barista-b@demo.coffeeos.local | barista | B | `/barista` |
| gm-a@demo.coffeeos.local | general_manager | A | `/manager` |
| gm-b@demo.coffeeos.local | general_manager | B | `/manager` |
| shift-a@demo.coffeeos.local | shift_manager | A | `/manager` |
| pk-manager@demo.coffeeos.local | prep_kitchen_manager | цех | `/prep_kitchen` |
| pk-worker@demo.coffeeos.local | prep_kitchen_worker | цех | `/prep_kitchen` |

**Блок D (UI):** логин из таблицы → Chrome DevTools MCP → журнал в [`PRACTICES.md`](PRACTICES.md) § Block D.
