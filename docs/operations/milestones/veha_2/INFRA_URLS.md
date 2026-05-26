# URL и инфраструктура (В2)

**Зачем:** новые точки получают рабочие `{slug}.domain` без ручной настройки DNS на каждый раз.

---

## Переменные

| ENV | Назначение |
|-----|------------|
| `SHOP_BASE_DOMAIN` | База поддоменов витрины/киоска. Прод: `coffeeos.fly.dev` (default в `UrlBuilder`) |
| `PORT` | Dev порт в URL (3001) |

**Код:** `Platform::TenantOnboarding::UrlBuilder`.

---

## Прод / demo-стенд (Fly, develop)

**В `fly.toml`:** `SHOP_BASE_DOMAIN=coffeeos.fly.dev` (задано для app `coffeeos`).

- Wildcard TLS: `fly certs add "*.coffeeos.fly.dev" -a coffeeos` — см. [`../../FLY_DEMO_STAND.md`](../../FLY_DEMO_STAND.md)
- Новый slug точки → витрина `https://{slug}.coffeeos.fly.dev/shop` (после cert)

---

## Локальная разработка

Без `SHOP_BASE_DOMAIN` витрина: `/shop?tenant_id={uuid}`.

С поддоменами: `/etc/hosts` или dnsmasq:

```
127.0.0.1 demo-point-a.localhost
```

Dev login hints: `auth/sessions/new` — `uk.localhost`, `barista.localhost` (роль, не точка).

---

## Зарезервированные slug

`www`, `app`, `admin`, `api`, `mail`, `ftp` — нельзя (`UrlBuilder::RESERVED_SUBDOMAINS`).

---

## Чеклист перед приёмкой новой org

- [ ] `SHOP_BASE_DOMAIN` задан на стенде
- [ ] Создали 3 slug → 3 URL открываются в браузере
- [ ] SSL без ошибки на поддомене

---

## Панели (не поддомен точки)

| Панель | URL |
|--------|-----|
| УК | `https://coffeeos.fly.dev/admin` |
| Manager | `…/manager` |
| Barista | `…/barista` |
| Prep kitchen | `…/prep_kitchen` |

Tenant выбирается **сессией**, не host.
