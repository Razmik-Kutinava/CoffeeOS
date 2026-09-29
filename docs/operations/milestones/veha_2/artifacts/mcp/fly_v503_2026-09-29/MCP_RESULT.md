# Fly v503 — post-deploy MCP (batch since v502)

**Date:** 2026-09-29 · **HEAD** `2a9adacb` · **Fly** v503 `deployment-01M3NZFK3A1M4H7CC5H02S188S`  
**Point A:** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**CI:** [`36253679528`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36253679528) + Semgrep + CodeQL green

## Пачка приёмки

| Где | Результат |
|-----|-----------|
| **Local** | Rails subscriptions/promo/eligibility/API **65/0** · JS CTA + promo i18n **22/0** |
| **Migration** | `20260926190000` на проде · колонки `utm_campaign/utm_content/offer_channel` · индекс `(subscription_id, created_at)` |
| **Fly** | `[fly:release] OK` · web+worker healthy · health passing · 5xx после деплоя нет |
| **Sentry** | skip — MCP OAuth timeout |
| **Neon / УК** | skip |

## Коммиты с v502 → что проверили

| Фича | Коммиты | MCP | Статус |
|------|---------|-----|--------|
| GrowthPromo `available?` + `amount_rub` UI | `b5653fa1` `ddf8e294` | `user/cards` → `growth_promo.amount_rub=11`; bundle без хардкода «сегодня 11» | **PASS** |
| CTA cache clear после оплаты | `e687317d` | `clearSubscriptionOfferCtaCache` в bundle | **PASS** bundle; live pay — skip |
| #77 Patch 1 приоритет 11₽ над оффером | `18c82b91` | eligibility false пока 11₽ доступен — unit/API | **PASS** local; live — skip (offer OFF) |
| Задача-1 Patch 1 emergency disable | `61b3fc79` | `config.subscription_offer.enabled=false` на Point A | **PASS** |
| Задачи-3 Patch 1 (7d usage, attribution, CTA no-tips) | `0fe747a0` | schema на проде; `subscriptions/*` без auth → 401 (не 500) | **PASS** wire; live purchase — skip |

## Browser Point A (safety)

- Catalog → product sheet → add 10₽ → CTA `+10₽` → `#/checkout` hash OK
- Тестовую корзину очистили (`DELETE cart` 200, items 0); **live pay / OTP не гоняли**

## Findings

- 🟡 **Product images `/uploads/products/*` → 404:** `Platform::ProductImageStorage` пишет в `public/uploads` на эфемерный диск машины, volume нет → фото стираются при каждом деплое (5 товаров ссылаются, на диске 1 файл). Не регресс v503. → `ISSUES.md`
- ⚪ Review: `idx_subscription_usage_events_sub (subscription_id)` теперь избыточен при составном `(subscription_id, created_at)` — backlog, не блокер.

## Next

- Live subscription purchase на Point A — после включения offer (billing UI)
- Решение по хранилищу фото (Active Storage + S3/Tigris или Fly volume)
