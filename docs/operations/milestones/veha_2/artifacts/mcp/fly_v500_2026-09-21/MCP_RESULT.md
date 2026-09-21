# Fly v500 — post-deploy MCP (batch since v499)

**Date:** 2026-09-21 · **HEAD** `ad0421c6` · **Fly** v500 `deployment-01M31NTDXYAJYWZQK3ZYGHHEZX`  
**Point A:** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**CI:** [`35584900523`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35584900523) green (test/lint/system/scan)

## Пачка приёмки

| Где | Результат |
|-----|-----------|
| **Sentry 24h** | новых firstSeen нет; `RUBY-1M` (синтаксис MCP runner) → resolved |
| **Fly logs** | boot OK · health pass · worker SolidQueue started · нет 5xx после hot |
| **Neon** | skip (не смотрели UI billing) |
| **УК Point A** | skip (не открывали УК) |
| **Deep MCP** | [`../critical_path_hardening/mcp/fly_v500_deep_rerun_2026-09-21/`](../critical_path_hardening/mcp/fly_v500_deep_rerun_2026-09-21/) **19/21 PARTIAL** |

### Deep soft-fails (не регресс деплоя)

| ID | Почему |
|----|--------|
| `B_phone_verify_6digit` | 422 без live Callcheck/OTP (device) |
| `H_overflow_error_defined` | runner probe; класс `Shop::CartService::OverflowError` в коде есть |

## Коммиты с v499 → что проверили

| Фича | Коммиты | MCP | Статус |
|------|---------|-----|--------|
| **TASK_84** receipt `.aoa__receipt` | `4e84a4b4` | JS bundle `aoa__receipt`×4 · catalog/cart Point A | **PASS** smoke; expand active order — **skip** (нет active orders в сессии) |
| **#73** FN/FD/FP + Patch1 poll | `439a87af` `ced2ad97` | live fiscal RECEIPT | **skip** — нужен fiscal notify ON + live чек |
| **TASK_94** LK history 1-click | `ff63997d` | UI «оплатить в 1 клик» + `historyRepeat` в JS | **PASS** UI |
| **Patch 1** inline pay statuses | `9e0a295c` | кнопки 1-click видны; цикл статусов | **PASS** wire; live status cycle — device skip |
| **#69 Патч 2** Telegram label | `4f8ee541` | `Telegram` в shop JS | **PASS** bundle |

## Browser Point A (safety)

- Catalog + cart add 10₽ → CTA `+10₽` → `#/checkout` hash OK
- Повтор/1-click rows видны в шторке
- Корзину тестовую очистили; **live pay / OTP на профиле заказчика не гоняли**

## Next

- G5 TASK_84: expand active order → `.aoa__receipt` text (нужен active order)
- G5 #73: fiscal notify ON + ЛК чек FN/FD/FP
- Device: Callcheck + funded card smoke по желанию
