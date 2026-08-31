# IB-3-4 — Device tokens (runbook)

**Фаза:** 3 · дата: 2026-08-31 · **код готов к prod kiosk/TV (железа пока нет)**

## Кто создаёт устройства

Создание TV и kiosk — только **privileged manager**:

| Роль | Создание | Policy / gate |
|------|----------|---------------|
| `general_manager` | ✅ | `DevicePolicy#privileged_manager?` + `require_privileged_manager!` |
| `franchise_manager` | ✅ | то же |
| `ук_global_admin` (в manager context) | ✅ | то же |
| `shift_manager` | ❌ | redirect с `manager_devices_path`; Pundit deny |

Канон в коде:

- `app/policies/device_policy.rb` — все actions через `privileged_manager?`
- `app/controllers/manager/devices_controller.rb` — `before_action :require_privileged_manager!`
- `ApplicationPolicy#privileged_manager?` = GM \| franchise \| UK

**shift_manager не создаёт** — подтверждено тестами (`shift_manager_rbac_test`, `tenant_rls_isolation_test`).

## Показ token once

При создании TV/kiosk контроллер генерирует token через `Devices::TokenCredentials` и показывает его **один раз** в flash/notice:

- TV: redirect с URL `/tv_board?token=…`
- Kiosk: notice «Токен: …`

Повторный просмотр полного token в UI **не предусмотрен** — только ротация.

## Валидность токена

Проверка при auth: `Device#token_valid?` + `is_active`.

| Условие | Результат |
|---------|-----------|
| `is_active: false` | 401 |
| `token_expires_at` в прошлом | 401 |
| `token_expires_at` nil | без срока (OK) |
| token пустой | 401 |

## TTL (срок действия)

ENV **`DEVICE_TOKEN_TTL_DAYS`** (опционально):

| Значение | Поведение |
|----------|-----------|
| не задан / пусто | `token_expires_at = nil` (без срока) |
| `> 0` | при создании и ротации — срок = now + N дней |

Пример prod: `DEVICE_TOKEN_TTL_DAYS=365`.

**Предупреждение до истечения:** ENV **`DEVICE_TOKEN_ROTATE_WARN_DAYS`** (default `14`) — совпадает с pill «скоро» в manager UI.

## Cron (IB-P-02)

| Компонент | Назначение |
|-----------|------------|
| `Devices::RotateExpiringTokensJob` | Solid Queue recurring, **06:00 daily** (`config/recurring.yml`) |
| `Devices::ExpiringTokensProcessor` | Логика: деактивация + алерты |

**Политика (не ломает kiosk/TV без процесса):**

| Состояние | Действие cron |
|-----------|---------------|
| `token_expires_at` в прошлом, `is_active: true` | `is_active=false` + Telegram алерт GM |
| истекает ≤ `DEVICE_TOKEN_ROTATE_WARN_DAYS` | Telegram алерт (раз в 7 дн. max), **без** auto-rotate |
| `DEVICE_TOKEN_TTL_DAYS` не задан | job no-op |

Ротация token — **только вручную** manager → «Новый токен»; cron metadata сбрасывается при `TokenCredentials.assign_new!`.

## Manager UI (отзыв / ротация)

| Действие | Route | Эффект |
|----------|-------|--------|
| **Отозвать** | `PATCH /manager/devices/:id/revoke` | `is_active=false`, auth 401 |
| **Новый токен** | `PATCH /manager/devices/:id/rotate_token` | новый `device_token`, сброс TTL, старый недействителен |
| **Восстановить + токен** | тот же `rotate_token` на отозванном | `is_active=true` + новый token |

Policy: `DevicePolicy#revoke?`, `#rotate_token?` → `privileged_manager?`.

## Tenant / RLS при lookup

Device lookup по token **до** установки GUC: политика `rls_devices_token_lookup` + `SET LOCAL app.device_token_lookup = 'on'` через `Rls::GucContext` / `Devices::TokenResolver`. **Без** `row_security off`.

После lookup — `SET LOCAL app.current_tenant_id` из `device.tenant_id`.

## Rate limit (Rack::Attack)

- Kiosk: `kiosk/device`, `kiosk/auth/ip` (см. `config/initializers/rack_attack.rb`)
- TV: `tv_board/token`, `tv_board/ip`

## ActionCable (G-03)

| Актор | Lookup | RLS |
|-------|--------|-----|
| Staff (`session[:user_id]`) | `Rls::GucContext.with_auth_login` → `User` | `rls_users_auth_login` |
| TV board (`tv_device_token` cookie) | `Devices::TokenResolver` | `rls_devices_token_lookup` |
| Shop guest | `current_user` nil | `Shop::GuestOrderChannel` — reconnect_token / customer session |

`OrdersChannel` использует `connection.current_user` (User или Device), без повторного `User.find_by` без GUC.

Тесты: `test/channels/application_cable/connection_test.rb`

## Out of scope

- Kiosk prod flows (продукт не в prod)
- TV deep security / ActionCable refactor
- `last_seen_at` audit changes
