# db — схема и данные

## Структура

| Путь | Назначение |
|------|------------|
| `migrate/` | **Основные миграции** PostgreSQL (схема приложения, RLS) |
| `schema.rb` | Снимок схемы после `db:migrate` |
| `seeds.rb` | Точка входа сидов — **не переносить**, пути захардкожены |
| `seeds_*.rb` | Частичные сиды (demo, barista, shop catalog…) — подключаются из `seeds.rb` или rake |
| `cache_migrate/` | Миграции **Solid Cache** (отдельная БД/схема) |
| `cache_schema.rb` | Схема кэша |
| `queue_migrate/` | Миграции **Solid Queue** (фоновые задачи) |
| `queue_schema.rb` | Схема очереди |
| `cable_migrate/` | Миграции **Solid Cable** (Action Cable) |
| `cable_schema.rb` | Схема cable |

## Команды

```bash
bin/rails db:migrate              # основная схема
bin/rails db:seed                 # dev/test сиды (не prod)
bin/rails db:prepare              # create + migrate + seed (dev)
```

Миграции кэша/очереди — через отдельные задачи Rails 8 multi-db (см. `config/database.yml`).

## Важно

- Сиды в `db/seeds*.rb` — **источник правды** для demo-данных; rake-задачи ссылаются на эти пути.
- RLS-политики — в миграциях и триггерах; перед правками смотри `.cursor/rules/coffeeos-core.mdc`.
