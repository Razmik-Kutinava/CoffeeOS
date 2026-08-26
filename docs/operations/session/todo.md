# todo — #70 Telegram bot support в ЛК

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| intake + SPEC #70 | gap: два конфига URL | RED — тесты единого URL |

**CBR:** #70  
**ТЗ:** [`customer_tasks/Связь через Telegram-бота поддержки в ЛК.md`](../milestones/veha_2/requirements/customer_tasks/Связь%20через%20Telegram-бота%20поддержки%20в%20ЛК.md)  
**Артефакты:** [`artifacts/telegram_bot_support_lk/`](../milestones/veha_2/artifacts/telegram_bot_support_lk/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Серия:** задача 1 из трёх (TG-support → ЛК #69 → email-after-pay). Не ломать #64–#69, CartSheet, checkout, payments.

## Цель (1 предложение)

Обе точки входа ЛК (иконка чата на hub + «Написать нам») открывают один и тот же deep link `https://t.me/code_black_support_bot` без user/order-параметров и без iframe/WebApp; email — stub без новой логики.

## Gap (после Cloud Code + #69)

| Есть | Не закрыто |
|------|------------|
| `supportConfig.js` + `SupportContactSheet` + Header (`dc69366e`) | ЛК `ContactSupportSheet` → `shopSupportTelegramUrl()` default **""** |
| `telegram_support_test.mjs` (config/deepLink) | Subtask 11: один URL из обеих точек |
| Email stub в Header-sheet | Email в ЛК-sheet уже жмёт mailto (#69) — **не расширять** email-бизнес; не ломать stub Header |

## Acceptance (DoD)

1. Hub `#/profile` chat icon → sheet Email/Telegram.
2. Settings «Написать нам» → тот же sheet/логика URL.
3. Telegram → `https://t.me/code_black_support_bot` без query/hash user/order.
4. Один source of truth URL (config), не хардкод в разметке sheet.
5. Нет iframe / Telegram WebApp / bot API credentials в PWA.
6. Email без новой бизнес-логики (disabled/скоро **или** существующий mailto без расширения scope).
7. Регресс ЛК: profile / history / receipt / logout живы.

## Фазы SBR

- [x] PHASE 0 intake
- [x] PHASE 1 SPEC
- [ ] RED
- [ ] GREEN
- [ ] /regress
- [ ] REVIEW

## Файлы (ожидаемо)

- `app/frontend/lib/supportConfig.js` — канон URL Telegram (+ fallback для ЛК)
- `app/frontend/lib/shopAboutConfig.js` — `shopSupportTelegramUrl` → тот же URL по умолчанию
- `app/frontend/components/ContactSupportSheet.svelte` — ЛК sheet: Telegram через общий URL/openDeepLink
- `app/frontend/components/SupportContactSheet.svelte` — Header sheet (не ломать)
- `app/frontend/routes/Profile.svelte` — иконка чата → sheet
- `app/frontend/routes/AccountSettings.svelte` — «Написать нам» → sheet
- `test/javascript/telegram_support_test.mjs` — единый URL + no PII in link

### Blast-radius (+2)

- `app/frontend/lib/deepLink.js` — *почему: общая open без params*
- `app/frontend/components/Header.svelte` — *почему: не сломать уже рабочий Header-sheet*

## Не ломать

- Auth / logout / session API (#69)
- Checkout / payments / CartSheet / WebView #64–#68
- Email-канал как отдельная фича (не реализовывать inbox)
- Передачу user_id / phone / order_id в t.me URL

## Проверка

- `node --test test/javascript/telegram_support_test.mjs`
- `node --test test/javascript/shop_personal_account_lk_test.mjs`
- `bundle exec ruby -Itest test/integration/shop/pwa_personal_account_lk_test.rb test/integration/shop/profile_ui_contract_test.rb`

Ручное: mobile с/без Telegram app · desktop новая вкладка. Fly MCP Point A — после GREEN + deploy.

## Subtasks (трекер)

- [ ] S1 config URL без хардкода в markup
- [ ] S2 sheet из иконки hub ЛК
- [ ] S3 Telegram из hub-sheet
- [ ] S4 Email stub / без новой логики
- [ ] S5 sheet из «Написать нам»
- [ ] S6 Telegram из profile/settings sheet
- [ ] S7 нет iframe/WebApp
- [ ] S8–S9 mobile/desktop deep link (ручное + MCP)
- [ ] S10 нет context params в URL
- [ ] S11 один URL обе точки
- [ ] S12 регресс ЛК
