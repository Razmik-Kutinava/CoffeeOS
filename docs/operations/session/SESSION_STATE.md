# SESSION_STATE

## Шапка (агент читает только это + todo + ISSUES «🔴 Открыто»)

**Дата:** 2026-09-04 (Sentry RUBY-1F / RUBY-16)  
**Ветка:** `develop`

| Сейчас | Дальше |
|--------|--------|
| RUBY-1F / RUBY-16 | fixed · deploy апрув |
| Fly **v479** MCP | PASS |

### Sentry (2026-09-04)

| Issue | Root cause | Fix |
|-------|------------|-----|
| RUBY-16 | `Current.set!` в `rails runner` (MCP mint); transaction пустой → шум проходил фильтр | `tags.source=runner` + CLI drop |
| RUBY-1F | `Current.set` без блока → LocalJumpError | LocalJumpError в CLI_CLASSES |
| API | — | `Current.assign!(…)` без блока |

### Deploy + MCP (2026-09-04)

| Что | Статус |
|-----|--------|
| `fly deploy` | **v479** (release retry после ConcurrentMigrationError; fix `fly_release` soft-skip) |
| #76 UK promo | A=PASS B=PASS C=SKIP D=PASS |
| #75 binding/promo UI | PASS (live charge SKIP) |
| #77 subscription offer | A–F PASS |
| Point A restore | promo on · sub offer on |

**Sentry 24h:** check in report · **Fly logs:** shop API 200; 406 allow_browser = bot UA noise · **Fly MCP:** PASS

**ctx_trim:** `2026-09-02`
