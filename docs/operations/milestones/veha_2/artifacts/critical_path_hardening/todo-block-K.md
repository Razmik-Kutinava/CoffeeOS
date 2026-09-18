# todo — #93 TASK_93-K: Hygiene pack (K1–K7)

Зеркало session `todo.md` (параллельные блоки не затирают канон K).

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-K** |
| **Тип** | SBR · hygiene pack (blog / demo / paymentUrl / merger / ops) |
| **Статус** | **GREEN** · Next: `/regress` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата K1–K7 · зонтик [`TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта K |
| **GATES** | [`GATES-block-K.md`](GATES-block-K.md) (канон; `session/GATES.md` может быть чужим блоком) |
| **Цель** | Один GREEN/PR: K1–K7 PASS или явный DEFER в REVIEW; без молчаливых хвостов |
| **OUT** | A–J продуктовые · полный RLS (G) · deploy (L) · расширение Blog allowlist · fake subdomain |
| **Зависимость** | после стабилизации A–J или параллельно мелкий pack; L закрывает K5-in-prod |
| **DEFER** | *(пусто)* |

## Канон продукта (зафиксировано SPEC)

| ID | Решение |
|----|---------|
| **R1 (K1)** | View/helper sanitize **только** `BlogPost::ALLOWED_TAGS` / `ALLOWED_ATTRIBUTES`. Не расширять allowlist в ERB. `<img>`/`style`/`h1` strip на save + на render |
| **R2 (K2)** | `Demo::EnvironmentSetup.call` / `demo:seed`: в `Rails.env.production?` — **abort**, кроме `DEMO_AUTO_SEED=true`. `DEMO_LOGINS.md`: warning «не для prod». T-K2c: нет `demo123456` под `app/` (docs/bin/artifacts ок) |
| **R3 (K3)** | `adapter_payment_url`: non-http(s) в **production** → **не** `securepayments.tinkoff.ru/#{pid}`; вернуть ошибку (**422**/JSON error) вызывающему widget/pay path. simulate/test/dev — fallback ок. `SHOP_BASE_DOMAIN` blank → `?tenant_id=` (уже UrlBuilder); док ok, fake subdomain запрещён |
| **R4 (K4)** | `ALLOWED_OPTIONAL_TABLES = %w[order_feedback promo_code_usages].freeze`; иначе `ArgumentError` |
| **R5 (K5)** | Код RUBY-1K уже в git; T-K5a must stay green; REVIEW: «RUBY-1K fix shipped in this release train» |
| **R6 (K6)** | После GREEN/REVIEW: шапка HANDOFF/SESSION sha = `git rev-parse --short HEAD` + next_step (L / остаток) |
| **R7 (K7)** | **B** (зафиксировано): collector уже batch + 1× `SET LOCAL row_security=off`; T-K7a assert ≤1 SET LOCAL на `call`; T-K7c PASS. **Не** Sentry ignore как DoD (A = не выбран). REVIEW: закрыть/отметить RUBY-1J после verify |

## SBR

- [x] PHASE 0 `/start` — бриф TASK_93-K в чате
- [x] `/unlazy` — GATES K (`GATES-block-K.md` · unmet 4 · G5→L)
- [x] PHASE 1 `/spec` — этот todo (+ зеркало session)
- [x] PHASE 2 RED — пачка T-K1a/b/c · T-K2* · T-K3a · T-K4a · (T-K7a) · коммит `[RED]`
- [x] PHASE 2 GREEN — R1–R7 · коммит `[GREEN]` · все T-K* PASS
- [ ] `/regress` — GATES G4 § Проверка
- [ ] PHASE 3 `/review` — таблица K1–K7 · K6 sha sync · push · **без deploy**

## Файлы (ожидаемо)

- `app/views/blog/posts/show.html.erb` — sanitize → `BlogPost::ALLOWED_*`
- `app/models/blog_post.rb` — канон allowlist (без расширения)
- `app/controllers/shop/api/payments_controller.rb` — `adapter_payment_url` prod fail
- `app/services/shop/customer_profile_merger.rb` — `ALLOWED_OPTIONAL_TABLES` + raise
- `app/services/demo/environment_setup.rb` — production guard / DEMO_AUTO_SEED
- `docs/operations/milestones/veha_1/reference/DEMO_LOGINS.md` — warning «не prod»
- `app/services/analytics/channel_order_stats_collector.rb` — только если T-K7a потребует правки (baseline уже B)

### Blast-radius (+соседи)

- `test/models/blog_post_sanitize_consistency_test.rb` (+ integration show) — T-K1*
- `test/controllers/shop/api/widget_payment_url_test.rb` — T-K3a/b
- `test/integration/platform/onboarding_infra_test.rb` — T-K3c регресс (не ломать)

## Матрица приёмки (RED → GREEN)

| ID | Assert |
|----|--------|
| T-K1a | ERB/helper без отдельного широкого `%w[h1 img style…]` |
| T-K1b | save strips `<img>` |
| T-K1c | blog show не re-introduce disallowed |
| T-K2a | production + DEMO_AUTO_SEED false → seed abort / no overwrite |
| T-K2b | DEMO_LOGINS содержит warning не-prod |
| T-K2c | (opt) no `demo123456` under `app/` |
| T-K3a | production-like blank/non-http → error, не fake tinkoff URL |
| T-K3b | valid https as-is |
| T-K3c | UrlBuilder без SHOP_BASE_DOMAIN → tenant_id URL |
| T-K4a | `reassign_optional_table!("orders")` raises |
| T-K4b | allowed tables merge |
| T-K5a | `menu_category_sort_order_update_test` PASS |
| T-K6a/b | REVIEW ops sha + next_step |
| T-K7a | SET LOCAL count ≤ bound на collector.call |
| T-K7c | `channel_order_stats_collector_test` PASS |

Без **T-K1a + T-K3a + T-K4a** блок не закрыт.

## Не ломать

1. Widget/pay happy path с валидным https PaymentURL
2. Blog publish/edit + render allowed tags (p/a/h2…)
3. Profile merge email/phone + allowed optional tables
4. Demo seed на local / `DEMO_AUTO_SEED=true`
5. Menu category blank `sort_order` update (RUBY-1K)

## Проверка

```bash
bin/rails test \
  test/integration/platform/menu_category_sort_order_update_test.rb \
  test/services/shop/customer_profile_merger_test.rb \
  test/services/analytics/channel_order_stats_collector_test.rb \
  test/models/blog_post_test.rb \
  test/controllers/shop/api/payments_controller_test.rb
# + новые T-K* файлы (sanitize / widget_payment_url / demo guard)
```

GATES: G1–G3 после GREEN `--approve`; G4 = этот regress; G5→L.
