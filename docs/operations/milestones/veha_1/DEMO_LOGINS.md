# Demo-логины (единый источник правды)

**Код:** `app/services/demo/environment_setup.rb`  
**Задачи:** `bin/rails demo:seed`, `bin/rails test:create_test_users` (дубль, те же данные)

**Пароль всех пользователей:** `demo123456` (`Demo::EnvironmentSetup::DEMO_PASSWORD`)

**Организация:** `demo-coffeeos`  
**Точки:** `demo-point-a`, `demo-point-b`, `demo-prep-kitchen` (цех)

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
