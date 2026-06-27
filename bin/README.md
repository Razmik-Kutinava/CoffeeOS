# bin — исполняемые скрипты

## Ежедневная разработка

| Скрипт | Назначение |
|--------|------------|
| `dev` | Rails + Vite (витрина `/shop`), порт 3001 |
| `server` | Только Rails-сервер |
| `setup` | Первичная настройка проекта |
| `rails` / `rake` | Стандартные Rails binstubs |
| `bundle` | Bundler |

## Качество и CI

| Скрипт | Назначение |
|--------|------------|
| `smoke` | Smoke-тесты: `tests` \| `ci` \| `lint` \| `rls` |
| `ci` | Полный CI-прогон локально |
| `rubocop` / `brakeman` / `bundler-audit` | Линт и безопасность |

## Деплой и инфра

| Скрипт | Назначение |
|--------|------------|
| `fly_deploy.sh` | Деплой на Fly (`coffeeos`): `--remote-only --depot=false`; WSL `/mnt/c/` → staging в `~/.cache/coffeeos-fly-deploy` |
| `kamal` | Деплой на Fly через Kamal |
| `docker-entrypoint` | Entrypoint контейнера |
| `ensure-server` | Проверка/подъём сервера |

## CoffeeOS — prog10 (ручной smoke / demo)

Скрипты `prog10_*` — **не binstubs**, а проектные Ruby-скрипты для проверок на Fly/локально:

| Скрипт | Назначение |
|--------|------------|
| `prog10_fly_smoke.rb` | Общий smoke Fly-стенда |
| `prog10_connectivity_fly.rb` | Сеть / доступность |
| `prog10_shop_vitrina.rb` | Витрина |
| `prog10_shop_vitrina_card.rb` | Карточка товара |
| `prog10_shop_urls_check.rb` | URL-режимы витрины |
| `prog10_shop_shp03.rb` | Сценарий SHP-03 |
| `prog10_kiosk_barista.rb` | Киоск + бариста |
| `prog10_kiosk_auth_fly_verify.rb` | Auth киоска на Fly |
| `prog10_staff_rbac_isolation.rb` | RBAC / изоляция staff |
| `prog10_setup_staff.rb` | Заведение staff |
| `prog10_collect_kiosk_tokens.rb` | Сбор токенов киоска |
| `prog10_stress_wave2.rb` | Нагрузочный прогон |

Запуск: `ruby bin/prog10_fly_smoke.rb` или `./bin/prog10_fly_smoke.rb` (если executable).

## Fly MCP (приёмка витрины)

| Скрипт | Назначение |
|--------|------------|
| `b113_s2_cart_popup_prep_fly.rb` | B1.13-S2: очистка корзины + product_id для MCP |
| `b113_s2_cart_popup_mcp.mjs` | B1.13-S2: поп-ап корзины на Fly (после deploy) |
| `b113_s2a_s2b_rev2_mcp.mjs` | B1.13-S2a/S2b rev2: приёмка на Fly (после deploy) |

```bash
ruby bin/b113_s2_cart_popup_prep_fly.rb
node bin/b113_s2a_s2b_rev2_mcp.mjs
```

## Остальное

`puma`, `vite`, `jobs`, `irb`, `dotenv` и т.д. — **gem binstubs** от Bundler; не редактировать вручную, обновляются через `bundle binstubs`.
