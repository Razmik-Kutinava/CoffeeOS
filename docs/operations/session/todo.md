# todo — #80 Registration UI/UX + Callcheck cascade

| Поле | Значение |
|------|----------|
| **CBR** | #80 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Регистрация%20PWA%20UI%20UX%20и%20каскад%20Callcheck%20x2%20SMS.md) |
| **Тип** | Fix / hot-path витрина · phone auth + CartSheet |
| **Цель** | P0: скрыть сумму при клавиатуре; копирайт Callcheck (номер = CTA); переход в PWA после подтверждённого звонка |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **Артефакты** | [`…/registration_callcheck_cascade_ui_ux/`](../milestones/veha_2/artifacts/registration_callcheck_cascade_ui_ux/) |

## SBR

- [x] **SPEC**
- [ ] **RED**
- [ ] **GREEN**
- [ ] **/regress**
- [ ] **REVIEW**

## Решение (slice)

| # | Решение |
|---|---------|
| 1 | Канон канала = **Callcheck** (`init_callcheck` / `check_status`). ТЗ-чек-лист с `flash_call` / `code/call` — **не внедрять** (deprecated с 2026-08-12). |
| 2 | При открытой цифровой клавиатуре на экране телефона — **скрыть** CTA суммы заказа в `CartSheet` (и/или свернуть pay-stack); после закрытия клавиатуры — снова peek/заказ. |
| 3 | Копирайт Callcheck: номер для звонка — **кнопка/ссылка** (`tel:`); текст «позвони / пройди регистрацию» → ясная инструкция + номер как CTA (см. скрин 02 / UX Guide). |
| 4 | После `check_status` = confirmed — гарантированный `onVerified` → сессия (`refresh_token`) → checkout без «застряли на звонке»; починить poll/linker, если confirmed не доезжает. |
| 5 | **Вне slice:** Callcheck×2 (повторный звонок 20+20) из Google Doc — backlog (сейчас Callcheck×1 → SMS @40s). SMS = свой код (не код звонка). |

## Файлы (ожидаемо)

- `app/frontend/components/CartSheet.svelte` — скрыть `+N₽` / checkout CTA при keyboard open на phone-auth
- `app/frontend/lib/shopWebViewLayout.js` — `isShopKeyboardOpen` / `--shop-keyboard-inset` (сигнал для шторки)
- `app/frontend/routes/Checkout.svelte` — хост `PhoneAuthWizard` + pad/peek при вводе телефона
- `app/frontend/lib/phoneAuthCascade.js` — константы копирайта / фазы Callcheck→SMS
- `app/frontend/components/PhoneAuthCodeStep.svelte` — UI звонка (номер-кнопка), poll, `onVerified`
- `app/frontend/components/PhoneAuthWizard.svelte` — экран 1 телефона (фокус/маска; сигнал keyboard→sheet)
- `app/services/shop/phone_otp.rb` — Callcheck session / `check_status` → linker (если confirmed не закрывает auth)

### Blast-radius (+3)

- `app/frontend/lib/cartSheetStore.js` — checkout peek / `checkoutPayOpen` при фокусе телефона
- `app/services/shop/phone_verified_customer_linker.rb` — сессия после confirmed call / SMS
- `app/controllers/shop/api/phone_otp_controller.rb` — API surface init/check/send_sms/verify

## Не ломать

- Оплата card One-Click / SBP (CTA `+сумма` вне phone-auth)
- Повтор заказа / peek шторки на витрине (не `#/checkout` auth)
- Callcheck→SMS fallback @40s + rate limit (20s callcheck / 60s SMS)
- Статусная шторка #35 / Compact status (не auth)

## Проверка

- `node --test test/javascript/shop_phone_auth_cascade_smsru_test.mjs test/javascript/phone_auth_wizard_test.mjs test/javascript/shop_telegram_webview_ui_test.mjs`
- `bin/rails test test/integration/shop/api/phone_otp_test.rb test/integration/shop/auth_funnel_wizard_ui_test.rb test/services/shop/phone_otp_test.rb`
