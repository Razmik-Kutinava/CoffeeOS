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

При создании TV/kiosk контроллер генерирует `SecureRandom.hex(24)` и показывает token **один раз** в flash/notice:

- TV: redirect с URL `/tv_board?token=…`
- Kiosk: notice «Токен: …»

Повторный просмотр полного token в UI **не предусмотрен** (Phase 3 без auto-rotation).

## Включить / выключить (отзыв)

| Действие | Как |
|----------|-----|
| **Деактивировать** | `device.update!(is_active: false)` — manager UI или Rails console |
| **Активировать снова** | `is_active: true` (если token ещё валиден) |
| **Полный отзыв** | deactivate → при необходимости создать новое устройство |

Проверка при auth: `Device#token_valid?` + `is_active`.

**Out of scope Phase 3:** auto-rotation, `last_seen_at` audit.

## Runbook ротации (manual)

1. В manager → Устройства: деактивировать старое (`is_active=false`) или удалить из клиента.
2. Создать новое устройство (privileged manager) — сохранить token из notice.
3. Обновить клиент (TV URL / kiosk config) новым token.
4. Проверить: TV board открывается, kiosk auth проходит.

Без автоматизации — отдельная задача при prod kiosk/TV.

## Tenant / RLS при lookup

Device lookup по token **до** установки GUC: политика `rls_devices_token_lookup` + `SET LOCAL app.device_token_lookup = 'on'` через `Rls::GucContext` / `Devices::TokenResolver`. **Без** `row_security off`.

После lookup — `SET LOCAL app.current_tenant_id` из `device.tenant_id`.

## Manager UI (отзыв / ротация)

| Действие | Route | Эффект |
|----------|-------|--------|
| **Отозвать** | `PATCH /manager/devices/:id/revoke` | `is_active=false`, auth 401 |
| **Новый токен** | `PATCH /manager/devices/:id/rotate_token` | новый `device_token`, старый недействителен |

Policy: `DevicePolicy#revoke?`, `#rotate_token?` → `privileged_manager?`.

## Rate limit (Rack::Attack)

- Kiosk: `kiosk/device`, `kiosk/auth/ip` (см. `config/initializers/rack_attack.rb`)
- TV: `tv_board/token`, `tv_board/ip`

## Out of scope

- Kiosk prod flows (продукт не в prod)
- TV deep security / ActionCable refactor
- Token TTL / scheduled rotation
- `last_seen_at` changes
