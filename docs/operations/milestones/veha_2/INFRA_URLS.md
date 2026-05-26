# URL и инфраструктура (В2)

**Зачем:** новые точки получают рабочие `{slug}.{SHOP_BASE_DOMAIN}` без ручной настройки DNS на каждый раз.

**Два режима (Fly demo vs прод):** [`../../SHOP_URL_MODES.md`](../../SHOP_URL_MODES.md) — **источник правды**.

---

## Переменные

| ENV | Назначение |
|-----|------------|
| `SHOP_BASE_DOMAIN` | База поддоменов: витрина/киоск = `https://{tenants.slug}.{SHOP_BASE_DOMAIN}/shop`. **Только если задан явно** — иначе fallback `?tenant_id=` |
| `PORT` | Dev: порт в URL поддомена (3001) |

**Код:** `Platform::TenantOnboarding::UrlBuilder`, `Shop::Concerns::TenantResolution`.

---

## Режим A — прод / сеть (целевой)

| Элемент | Значение |
|---------|----------|
| Пример домена | `shop.бренд.ru` |
| Витрина точки A | `https://demo-point-a.shop.бренд.ru/shop` |
| Резолв tenant | Host → `Tenant.slug` |
| ENV | `SHOP_BASE_DOMAIN=shop.бренд.ru` |
| DNS | `*.shop.бренд.ru` CNAME → `coffeeos.fly.dev` |
| TLS | `fly certs add "*.shop.бренд.ru" -a coffeeos` |

---

## Режим B — Fly demo (сейчас, app `coffeeos`)

| Элемент | Значение |
|---------|----------|
| `fly.toml` | **без** `SHOP_BASE_DOMAIN` |
| Витрина | `https://coffeeos.fly.dev/shop?tenant_id=<uuid>` |
| Slug в БД | `demo-point-a`, `demo-point-b` — **те же**, что в проде |
| Почему не поддомен на Fly | Нет DNS/TLS на `{slug}.coffeeos.fly.dev` — не баг CoffeeOS |

Инструкция стенда: [`../../FLY_DEMO_STAND.md`](../../FLY_DEMO_STAND.md).

---

## Локальная разработка

См. [`../../SHOP_URL_MODES.md`](../../SHOP_URL_MODES.md) § «Локальная разработка».

- Поддомены: `SHOP_BASE_DOMAIN=localhost` + `/etc/hosts` → `http://{slug}.localhost:3001/shop`
- Без hosts: пустой `SHOP_BASE_DOMAIN` → `/shop?tenant_id={uuid}`

---

## Зарезервированные slug

`www`, `app`, `admin`, `api`, `mail`, `ftp` — нельзя (`UrlBuilder::RESERVED_SUBDOMAINS`).

---

## Чеклист перед приёмкой новой org (режим A)

- [ ] `SHOP_BASE_DOMAIN` задан на стенде
- [ ] Wildcard DNS + TLS Ready
- [ ] Создали 3 slug → 3 URL `https://{slug}.{base}/shop` открываются
- [ ] SSL без ошибки на поддомене
- [ ] Меню различается между точками (разные PTS)

---

## Панели (не поддомен точки)

| Панель | URL (Fly demo) |
|--------|----------------|
| УК | `https://coffeeos.fly.dev/admin` |
| Manager | `…/manager` |
| Barista | `…/barista` |
| Prep kitchen | `…/prep_kitchen` |

Tenant в панелях — **сессия**, не Host.
