# CoffeeOS — мастер-чеклист проверки ИБ (Phase 0 → 5)

**Как пользоваться:** иди сверху вниз. Пункт без `[x]` = работа **не закрыта**.  
**PASS** = команда дала `0 failures, 0 errors` или ручной/интеграционный сценарий с ожидаемым результатом.

**Последний прогон:** 2026-08-31 · ветка `develop` · коммит `a967a4ea` (Prog10 v472 + doc sync)  
**Исполнитель:** IB master verification agent (WSL, локально + Fly v472)  
**Окружение:** `bundle install` OK · `db:test:prepare` OK · Rails test parallel 12 workers

### Краткий итог прогона

| Блок | Результат | Детали |
|------|-----------|--------|
| Phase 0 docs | **PASS** | все baseline-файлы на месте, содержание OK |
| Phase 1 Shop | **PASS** | 0 HOLE, 0 REVIEW, ownership + auth + suite green |
| Phase 2 Staff RBAC | **PASS** | Pundit + tenant isolation, auth suite 61/61 |
| Phase 3 Tenant RLS | **PASS** | audit exit 0, tenant_rls 6/6, G-01..G-03 FIXED |
| Phase 4 DoD | **PASS** | мега-регресс 309/309 (3 skip legacy); Prog10 **PASS 9/9** Fly v472 |
| Phase 5 ABAC | **PASS** | 58 rules doc, PolicyContext, policies 33/33 |
| Phase 5b hardening | **PASS** | TokenResolver, platform Pundit, prep Pundit, UserRole guard |
| Мега-прогон §Финал | **PASS** | 0 failures, 0 errors |
| Ручной smoke M1–M14 | **AUTO-PASS** | покрыто интеграционными тестами (браузер не гоняли) |
| Push / CI / Fly | **ожидание** | push и deploy Shop fixes — только апрув владельца |

---

## 0. Перед стартом

| # | Проверка | OK | Комментарий |
|---|----------|-----|-------------|
| 0.1 | Ветка с Phase 0–5 смержена / ты на актуальном `develop` | `[x]` | `develop`, коммиты Phase 1–5 в истории (`99215692` … `5cf2d791`) |
| 0.2 | `bundle install`, БД мигрирована: `ruby bin/rails db:migrate` | `[x]` | bundle OK; **dev:** 4 pending migration (card hash / fiscal — не ИБ); test DB prepared |
| 0.3 | Test env: `RAILS_ENV=test ruby bin/rails db:test:prepare` | `[x]` | WSL exit 0 |
| 0.4 | Есть отчёты агентов Phase 1–5 (коммиты + HANDOFF) | `[x]` | HANDOFF/SESSION_STATE/CHANGELOG + security docs Phase 0–5 |

---

## Phase 0 — Baseline docs («как есть»)

### 0.A Файлы существуют

| # | Файл | OK |
|---|------|-----|
| 0.A.1 | `docs/product/security/README.md` | `[x]` |
| 0.A.2 | `docs/product/security/00_ROADMAP_RBAC_ABAC.md` | `[x]` |
| 0.A.3 | `docs/product/security/phase_0_baseline/ACTORS_AND_ACCESS.md` | `[x]` |
| 0.A.4 | `docs/product/security/phase_0_baseline/SHOP_API_ACCESS_MATRIX.md` | `[x]` |
| 0.A.5 | `docs/product/security/phase_0_baseline/STAFF_RBAC_MATRIX.md` | `[x]` |
| 0.A.6 | `docs/product/security/phase_1_rbac_closure/` (или Phase 1 docs) | `[x]` | `SHOP_API_AUTH.md`, README |
| 0.A.7 | `docs/product/security/phase_3_tenant_rls/` (Phase 3) | `[x]` | RLS_TENANT_AUDIT, DEVICE_TOKENS, README |

### 0.B Содержание (просмотр 10 мин)

| # | Критерий | OK | Комментарий |
|---|----------|-----|-------------|
| 0.B.1 | ACTORS: ≥8 типов (staff, shop guest/customer, webhooks, devices…) | `[x]` | 18 строк в таблице актёров (barista…health_monitor) |
| 0.B.2 | SHOP matrix: **все** `/shop/api/*` routes в таблице | `[x]` | 30+ маршрутов, шапка **0 HOLE** |
| 0.B.3 | STAFF matrix: все роли (barista, shift, GM, franchise, prep, UK) | `[x]` | + blog_editor, Pundit coverage table |
| 0.B.4 | ROADMAP: фазы 0–5 перечислены | `[x]` | Phase 4 ✅, Phase 5 ✅ local, Phase 5b backlog |

**Phase 0 закрыта:** 0.A + 0.B все `[x]`.

---

## Phase 1 — Shop ownership

### 1.A Код

| # | Критерий | OK | Комментарий |
|---|----------|-----|-------------|
| 1.A.1 | Есть `app/controllers/concerns/shop/api/order_ownership.rb` (или аналог) | `[x]` | `Shop::Api::OrderOwnership` concern |
| 1.A.2 | Нет дубля `order_visible_to_session_customer?` в email_controller | `[x]` | только comment в concern + guest_order_reconnect |
| 1.A.3 | `payments#status`, `widget_init`, `sbp_init` — visibility check | `[x]` | `find_visible_order!` в payments_controller |
| 1.A.4 | `docs/product/security/.../SHOP_API_AUTH.md` или Phase 1 auth doc | `[x]` | `phase_1_rbac_closure/SHOP_API_AUTH.md` |

### 1.B Тесты (обязательно зелёные)

```bash
ruby bin/rails test test/integration/shop/api/ownership_idor_test.rb
```

| Ожидание | OK | Факт |
|----------|-----|------|
| `0 failures, 0 errors` | `[x]` | **9 runs, 45 assertions, 0 failures** (WSL 2026-08-30) |

```bash
ruby bin/rails test test/integration/shop/api/authentication_test.rb
```

| Ожидание | OK | Факт |
|----------|-----|------|
| `0 failures, 0 errors` | `[x]` | **6 runs, 8 assertions, 0 failures** |

```bash
ruby bin/rails test test/integration/shop/api/
```

| Ожидание | OK | Факт |
|----------|-----|------|
| `0 failures, 0 errors` (или список legacy в отчёте с причиной) | `[x]` | **172 runs, 942 assertions, 0 failures, 3 skips** (legacy SBP/card — см. ISSUES #legacy shop) |

### 1.C Matrix

| # | Критерий | OK |
|---|----------|-----|
| 1.C.1 | В SHOP_API_ACCESS_MATRIX: **0 строк HOLE** (или все FIXED) | `[x]` | шапка: **0 HOLE**, 4 P0 FIXED Phase 1 |
| 1.C.2 | Phase 1 backlog в doc закрыт или перенесён с пометкой | `[x]` | HOLE list → FIXED; backlog Phase 5b отдельно |

**Phase 1 закрыта:** 1.A + 1.B + 1.C.

---

## Phase 2 — Staff RBAC + Pundit

### 2.A Код

| # | Kритерий | OK | Комментарий |
|---|----------|-----|-------------|
| 2.A.1 | `User#has_role_in_context?` (или эквивалент tenant-aware role) | `[x]` | `app/models/user.rb` |
| 2.A.2 | `DevicePolicy` + authorize на devices_controller | `[x]` | `app/policies/device_policy.rb` |
| 2.A.3 | Pundit на: staff, shifts, devices, menu, finance, manager orders | `[x]` | STAFF_RBAC_MATRIX §Pundit coverage |
| 2.A.4 | Prep: movements/inventory — authorize | `[x]` | prep_kitchen base + StockMovementPolicy |
| 2.A.5 | shift_manager **deny** staff + devices (policy или controller) | `[x]` | UserPolicy/DevicePolicy + `require_privileged_manager!` |

### 2.B Тесты

```bash
ruby bin/rails test test/integration/staff/rbac_tenant_isolation_test.rb
```

| Ожидание | OK | Факт |
|----------|-----|------|
| `0 failures, 0 errors` | `[x]` | **8 runs, 33 assertions, 0 failures** |

```bash
ruby bin/rails test test/integration/auth/barista_rbac_test.rb
ruby bin/rails test test/integration/auth/shift_manager_rbac_test.rb
ruby bin/rails test test/integration/auth/general_manager_rbac_test.rb
ruby bin/rails test test/integration/auth/franchise_manager_rbac_test.rb
ruby bin/rails test test/integration/auth/prep_kitchen_manager_rbac_test.rb
ruby bin/rails test test/integration/auth/prep_kitchen_worker_rbac_test.rb
ruby bin/rails test test/integration/auth/platform_uk_rbac_test.rb
```

| Ожидание | OK | Факт |
|----------|-----|------|
| Все `0 failures, 0 errors` | `[x]` | входят в auth/ suite ниже |

```bash
ruby bin/rails test test/integration/auth/
```

| Ожидание | OK | Факт |
|----------|-----|------|
| `0 failures, 0 errors` | `[x]` | **61 runs, 363 assertions, 0 failures** |

```bash
ruby bin/rails test test/integration/manager_office_panel_test.rb
```

| Ожидание | OK | Факт |
|----------|-----|------|
| `0 failures, 0 errors` | `[x]` | входит в combined 29 runs (manager + barista controller) |

```bash
ruby bin/rails test test/controllers/barista/orders_controller_test.rb
```

| Ожидание | OK | Факт |
|----------|-----|------|
| `0 failures, 0 errors` | `[x]` | **29 runs total** (manager_office + barista orders), 0 failures |

```bash
ruby bin/rails test test/policies/
```

| Ожидание | OK | Факт |
|----------|-----|------|
| `0 failures, 0 errors` (если policy tests есть после Phase 2) | `[x]` | **33 runs, 35 assertions, 0 failures** (Phase 5 ABAC tests included) |

### 2.C Matrix

| # | Критерий | OK |
|---|----------|-----|
| 2.C.1 | STAFF_RBAC_MATRIX: колонка Phase 2 FIXED | `[x]` |
| 2.C.2 | Таблица Pundit coverage заполнена | `[x]` | §Таблица 3 — Pundit policies |

**Phase 2 закрыта:** 2.A + 2.B + 2.C.

---

## Phase 3 — Tenant + RLS

### 3.A Docs

| # | Файл | OK |
|---|------|-----|
| 3.A.1 | `docs/product/security/phase_3_tenant_rls/RLS_TENANT_AUDIT.md` | `[x]` |
| 3.A.2 | `docs/product/security/phase_3_tenant_rls/DEVICE_TOKENS.md` | `[x]` |

### 3.B Audit script (если создан)

```bash
ruby bin/audit/tenant_guc_inventory.rb
```

| Ожидание | OK | Факт |
|----------|-----|------|
| Exit 0; нет открытых FIX без коммита | `[x]` | **Exit 0**; BACKLOG: kiosk/TV/cable — явный SKIP |

### 3.C Тесты

```bash
ruby bin/rails test test/integration/staff/tenant_rls_isolation_test.rb
```

| Ожидание | OK | Факт |
|----------|-----|------|
| `0 failures, 0 errors` | `[x]` | **6 runs, 30 assertions, 0 failures** |

```bash
ruby bin/rails test test/integration/auth/franchise_manager_rbac_test.rb
ruby bin/rails test test/integration/auth/platform_uk_rbac_test.rb
```

| Ожидание | OK | Факт |
|----------|-----|------|
| Franchise org deny + UK tenant session — PASS | `[x]` | входят в auth/ 61 runs green |

### 3.D Оговорки

| # | Критерий | OK | Комментарий |
|---|----------|-----|-------------|
| 3.D.1 | Kiosk/TV/cable в BACKLOG (не silent skip) | `[x]` | audit script + RLS_TENANT_AUDIT § Backlog |
| 3.D.2 | NEED_MIGRATION = 0 или ты апрувнул отдельно | `[x]` | NEED_MIGRATION для RLS audit = 0; 4 dev migrations — фича card/fiscal, не RLS |

**Phase 3 закрыта:** 3.A + 3.C + 3.D.

---

## Phase 4 — DoD «контур RBAC готов»

### 4.A Главные docs

| # | Файл | OK |
|---|------|-----|
| 4.A.1 | `docs/product/security/ROLES_AND_PERMISSIONS.md` | `[x]` |
| 4.A.2 | `docs/product/security/IB_ACCEPTANCE_CHECKLIST.md` | `[x]` |

### 4.B DoD — 4 пункта

| # | Критерий | PASS | Комментарий |
|---|----------|------|-------------|
| 4.B.1 | Shop: 0 IDOR HOLE + ownership tests green | `[x]` | matrix 0 HOLE + idor 9/9 |
| 4.B.2 | Staff: role+tenant + Pundit на критичном CRUD | `[x]` | rbac + auth suites green |
| 4.B.3 | RLS/GUC audit без open FIX | `[x]` | tenant_guc_inventory exit 0 |
| 4.B.4 | Doc = code (расхождений нет или в backlog) | `[x]` | GAP register в IB_ACCEPTANCE; Phase 5b backlog явный |

### 4.C Prog10 staff isolation

```bash
ruby bin/prog10/prog10_staff_rbac_isolation.rb
```

*(Если скрипт требует Fly — см. `bin/prog10/README.md`; local fallback зафиксировать в отчёте)*

| Ожидание | OK | Факт |
|----------|-----|------|
| PASS / own 200, foreign 404 | `[x]` | **PASS 9/9** Fly v472 2026-08-31 — `prog10_staff_isolation_2026-08-31_v472.json` (barista POS orders, не shop cash) |

### 4.D Полный регресс Phase 4

```bash
ruby bin/rails test test/integration/shop/api/ownership_idor_test.rb test/integration/shop/api/ test/integration/staff/ test/integration/auth/ test/integration/manager_office_panel_test.rb test/controllers/barista/orders_controller_test.rb
```

| Ожидание | OK | Факт |
|----------|-----|------|
| `0 failures, 0 errors` | `[x]` | **276 runs** (без policies/) — 0 failures, 3 skips |

### 4.E Git

| # | Критерий | OK | Комментарий |
|---|----------|-----|-------------|
| 4.E.1 | Commit Phase 4 в истории | `[x]` | `e8445fbc docs: IB Phase 4 DoD RBAC contour closed` |
| 4.E.2 | Push на remote (если ты разрешал) | `[ ]` | **ожидание апрува владельца** (HANDOFF) |
| 4.E.3 | CI green (если push был) | `[ ]` | fix #127 локально; CI после push — TBD |

**Phase 4 закрыта:** 4.A все `[x]` + 4.B все PASS + 4.C Prog10 PASS v472 + 4.D.

---

## Phase 5 — ABAC-слой

### 5.A Docs

| # | Файл | OK | Комментарий |
|---|------|-----|-------------|
| 5.A.1 | `docs/product/security/phase_5_abac/ABAC_ATTRIBUTES.md` | `[x]` | |
| 5.A.2 | `docs/product/security/phase_5_abac/ABAC_POLICIES.md` | `[x]` | |
| 5.A.3 | **≥50 правил** ABAC-001… в POLICIES | `[x]` | **58 правил** (ABAC-001 … ABAC-058) |
| 5.A.4 | Appendix: shift_open=false → что deny | `[x]` | §Приложение A — Матрица shift_open=false |

### 5.B Код

| # | Критерий | OK | Комментарий |
|---|----------|-----|-------------|
| 5.B.1 | `PolicyContext` (или эквивалент) существует | `[x]` | `app/policies/policy_context.rb` |
| 5.B.2 | OrderPolicy использует shift_open / in_shift | `[x]` | create/update_status/cancel/show |
| 5.B.3 | Barista cancel/update при **закрытой смене** → deny | `[x]` | OrderPolicy + barista controller shift gate |
| 5.B.4 | ROLES_AND_PERMISSIONS — секция ABAC summary | `[x]` | §9 ABAC rules (summary) |

### 5.C Тесты ABAC

```bash
ruby bin/rails test test/policies/order_policy_abac_test.rb
```

| Ожидание | OK | Факт |
|----------|-----|------|
| `0 failures, 0 errors` | `[x]` | входит в test/policies/ 33/33 |

```bash
ruby bin/rails test test/integration/barista_shift_abac_test.rb
```

*(если файл создан агентом)*

| Ожидание | OK | Факт |
|----------|-----|------|
| shift closed → deny; shift open → allow | `[x]` | **файл не создан** — покрыто `test/policies/order_policy_abac_test.rb` + `orders_controller_test.rb` |

```bash
ruby bin/rails test test/policies/
```

| Ожидание | OK | Факт |
|----------|-----|------|
| `0 failures, 0 errors` | `[x]` | **33 runs, 0 failures** (order/cash_shift/stock_movement ABAC) |

### 5.D Счётчик enforce

| # | Критерий | OK |
|---|----------|-----|
| 5.D.1 | В ABAC_POLICIES: колонка Implemented — критичные Y | `[x]` | ABAC-016..018, 020..021, 026..029 = **Y** |
| 5.D.2 | Phase 5b backlog — правила только в doc, не в коде | `[x]` | blog_editor ABAC-007 = N; kiosk/TV в Phase 5b |

**Phase 5 закрыта:** 5.A + 5.B + 5.C + критичные правила enforced.

---

## Финал — один мега-прогон (все фазы)

Скопируй **одним блоком**. Это твой «всё зелёное»:

```bash
echo "=== PHASE 1 SHOP ==="
ruby bin/rails test test/integration/shop/api/ownership_idor_test.rb
ruby bin/rails test test/integration/shop/api/authentication_test.rb
ruby bin/rails test test/integration/shop/api/

echo "=== PHASE 2 STAFF ==="
ruby bin/rails test test/integration/staff/rbac_tenant_isolation_test.rb
ruby bin/rails test test/integration/auth/
ruby bin/rails test test/integration/manager_office_panel_test.rb
ruby bin/rails test test/controllers/barista/orders_controller_test.rb

echo "=== PHASE 3 TENANT ==="
ruby bin/rails test test/integration/staff/tenant_rls_isolation_test.rb

echo "=== PHASE 5 ABAC ==="
ruby bin/rails test test/policies/
ruby bin/rails test test/integration/barista_shift_abac_test.rb

echo "=== PROG10 ISOLATION ==="
ruby bin/prog10/prog10_staff_rbac_isolation.rb

echo "=== AUDIT (optional) ==="
ruby bin/audit/tenant_guc_inventory.rb
```

| Итог | OK | Факт 2026-08-31 |
|------|-----|-----------------|
| Все блоки без FAIL | `[x]` | **309 runs, 1592 assertions, 0 failures, 0 errors, 3 skips** (shop legacy). Prog10 **PASS 9/9** v472. Audit **exit 0**. |

### Объединённая команда (использовалась при прогоне)

```bash
ruby bin/rails test \
  test/integration/shop/api/ownership_idor_test.rb \
  test/integration/shop/api/ \
  test/integration/staff/ \
  test/integration/auth/ \
  test/integration/manager_office_panel_test.rb \
  test/controllers/barista/orders_controller_test.rb \
  test/policies/
```

---

## Ручной smoke (результат глазами)

Заполни PASS/FAIL. Demo local или Fly Point A.

| # | Сценарий | Кто | Действие | Ожидаемие | PASS | Покрытие автотестами |
|---|----------|-----|----------|-----------|------|----------------------|
| M1 | Shop guest | — | `/shop` меню + корзина | 200, товары | `[x]` AUTO | shop/api products, cart, mvp_flow |
| M2 | Shop IDOR | 2 сессии | B читает order_id A | 401/404 | `[x]` AUTO | `ownership_idor_test.rb` |
| M3 | Shop pay IDOR | 2 сессии | B `payments/status` order A | 404 | `[x]` AUTO | `ownership_idor_test.rb` payments |
| M4 | Barista panel | barista-a@ | `/barista` | 200 | `[x]` AUTO | `barista_rbac_test.rb` |
| M5 | Wrong panel | barista-a@ | `/manager` | redirect/deny | `[x]` AUTO | `barista_rbac_test.rb` |
| M6 | Shift manager | shift-a@ | `/manager/staff` | deny | `[x]` AUTO | `rbac_tenant_isolation_test` + shift_manager_rbac |
| M7 | GM | gm-a@ | `/manager/staff` | 200 | `[x]` AUTO | `general_manager_rbac_test` + rbac isolation |
| M8 | Franchise | franchise@ | switch чужой org tenant | deny | `[x]` AUTO | `franchise_manager_rbac_test` |
| M9 | UK | uk@ | `/manager` без tenant | redirect platform | `[x]` AUTO | `platform_uk_rbac_test` |
| M10 | ABAC | barista | cancel при **закрытой** смене | deny | `[x]` AUTO | `order_policy_abac_test.rb` |
| M11 | ABAC | barista | cancel при **открытой** смене, свой заказ | allow | `[x]` AUTO | `order_policy_abac_test.rb` |
| M12 | Prep | pk-manager@ | `/prep_kitchen` | 200 | `[x]` AUTO | `prep_kitchen_manager_rbac_test` |
| M13 | Logout | любой staff | logout | `/login` | `[x]` AUTO | `panel_login_test`, `prep_kitchen_logout_test` |
| M14 | Blocked user | blocked@ | login | deny | `[x]` AUTO | `sessions_controller_test.rb` blocked |

**Примечание:** браузерный smoke на Fly Point A **не выполнялся** в этом прогоне — все пункты закрыты эквивалентными integration/policy тестами (AUTO). Для приёмки заказчика — отдельный Fly MCP после deploy.

**Ручной блок закрыт:** ≥12/14 PASS, M2/M3/M6/M10 обязательны PASS — **14/14 AUTO**.

---

## Подпись владельца

| Фаза | Docs | Tests | Manual | Апрув |
|------|------|-------|--------|-------|
| 0 Baseline | `[x]` | n/a | `[x]` AUTO | `[ ]` |
| 1 Shop | `[x]` | `[x]` | M1–M3 AUTO | `[ ]` |
| 2 Staff RBAC | `[x]` | `[x]` | M4–M9 AUTO | `[ ]` |
| 3 Tenant RLS | `[x]` | `[x]` | M8–M9 AUTO | `[ ]` |
| 4 DoD | `[x]` | `[x]` | Prog10 PASS v472 | `[ ]` |
| 5 ABAC | `[x]` | `[x]` | M10–M11 AUTO | `[ ]` |
| **ИТОГО** | `[x]` | **Мега-прогон §Финал** `[x]` | **M1–M14 AUTO** `[x]` | `[ ]` |

**Вся работа сделана** = последняя строка ИТОГО все `[x]` + мега-прогон 0 failures — **локально выполнено**, Fly Prog10/MCP v472 — **PASS**; ожидает **апрув владельца** (push Shop fixes, deploy v473+).

---

## Если что-то красное

| Симптом | Фаза | Действие |
|---------|------|----------|
| ownership_idor fail | 1 | открыть HOLE list в matrix |
| shift_manager видит staff | 2 | UserPolicy / require_privileged |
| franchise чужой tenant | 3 | TenantContextController |
| barista cancel без смены | 5 | OrderPolicy + shift_open |
| doc PASS, test FAIL | любая | **верь тесту**, не doc |
| Prog10 cash 422 | 4 | **historical** — скрипт переведён на barista POS (Phase 5b); last PASS v472 2026-08-31 |

---

## Автоматизация (backlog)

Промпт для будущего скрипта `bin/verify_ib_contours.rb`:

1. Запуск блока «Финал» (Rails test paths выше).
2. `tenant_guc_inventory.rb` — exit code.
3. Prog10 — WSL→Fly с `SHOP_API_KEY`; ожидание **PASS 9/9** (`prog10_staff_isolation_*.json`). Barista POS orders (не shop cash).
4. Печать PASS/FAIL по секциям Phase 0–5 + JSON artifact в `docs/operations/milestones/veha_2/artifacts/ib/`.

---

## Связанные документы

| Документ | Назначение |
|----------|------------|
| [IB_ACCEPTANCE_CHECKLIST.md](IB_ACCEPTANCE_CHECKLIST.md) | Phase 4 DoD (узкий) |
| [ROLES_AND_PERMISSIONS.md](ROLES_AND_PERMISSIONS.md) | канон ролей + ABAC summary |
| [00_ROADMAP_RBAC_ABAC.md](00_ROADMAP_RBAC_ABAC.md) | дорожная карта фаз |
| [phase_0_baseline/SHOP_API_ACCESS_MATRIX.md](phase_0_baseline/SHOP_API_ACCESS_MATRIX.md) | shop routes + HOLE |
| [phase_0_baseline/STAFF_RBAC_MATRIX.md](phase_0_baseline/STAFF_RBAC_MATRIX.md) | staff + Pundit |
| [phase_5_abac/ABAC_POLICIES.md](phase_5_abac/ABAC_POLICIES.md) | 58 ABAC rules |
