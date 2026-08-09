# todo — agent hot-path rules (2026-08-09)

**Сделано (этот шаг):** правила — «Не ломать»/«Проверка» обязательны; DoD Local+Fly Point A; anti-gem; MCP-safety; канон Point A в DEMO_LOGINS.

## Очередь продукта (следующее намерение владельца)

### A. UserCards / save_card (ISSUES 🔴)
- [ ] Апрув заказчика 3.5 (скрин 8925)
- [ ] E2E: реальная карта ≠ test PAN на Point A
- [ ] Не путать ErrorCode банка с багом приложения

### B. Витрина стабилизация (статусы ↔ корзина ↔ повторить)
Шаблон SPEC при старте:
```
## Файлы (ожидаемо)
- … (2–7)
## Не ломать
- оплата / 1-клик
- кнопка «повторить» / frequent
- табло бариста / статусы в PWA
- peek корзины / CartSheet layering
## Проверка
- bin/rails test test/integration/shop/   # или узже по зоне из dev-gates
```
- [ ] Проход стабилизации + Fly MCP Point A

### C. Legacy shop suite (~24 fail) — triage начат 2026-08-09
- [x] Regression `unknown keyword: :receipt` — фикс `1582f078`
- [x] Messenger OTP: по git log — осознанно снесён (`b2685910`/`8b76da10`), у заказчика сейчас только flash_call+SMS. Тесты (`phone_otp_test.rb`, `profile_merge_test.rb`, `auth_funnel_wizard_ui_test.rb`) актуализированы под реальный флоу — 17/17 green
- [ ] Остальные 4-5 failures (structural/ErrorCode 1051/active_orders_receipt) — отдельная итерация

**Статус шага правил:** done
