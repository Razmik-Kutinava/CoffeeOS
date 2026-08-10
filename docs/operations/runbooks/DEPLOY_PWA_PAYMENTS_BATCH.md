# Deploy runbook — PWA / payments batch

**Назначение:** выкат develop → Fly `coffeeos` с приёмкой hot-path витрины/оплаты/статусов на **Point A** только.

**Bridge:** [`docs/integrations/INTEGRATIONS.md`](../../integrations/INTEGRATIONS.md) · gap: [`gap-matrix-pwa-payments.md`](../../integrations/gap-matrix-pwa-payments.md)

**Point A:** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` · логины `DEMO_LOGINS` / `docs/operations/demo/FLY_DEMO_STAND.md`

**Не путать:** Fly Test / Overnight — не стенд приёмки.

---

## 1. Preflight (до deploy)

### 1.1 Локальные тесты (таргетные зоны)

Windows: **не** полный `test/integration/shop/` — только файлы ниже или CI.

```bash
# Оплата §2.3
bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb \
  test/integration/shop/api/qa_section_2_3_stage5_e2e_test.rb

# Session + identity
bin/rails test test/integration/shop/api/session_refresh_test.rb \
  test/integration/shop/api/profile_merge_test.rb \
  test/integration/shop/api/phone_otp_test.rb

# SBP + widget + cards
bin/rails test test/integration/shop/api/sbp_payment_init_test.rb \
  test/integration/shop/api/sbp_autopay_charge_test.rb \
  test/integration/shop/api/payment_widget_init_test.rb \
  test/integration/shop/shop_usercards_phase1_persist_test.rb

# Status sheet + repeat
bin/rails test test/integration/shop/api/active_orders_test.rb \
  test/integration/shop/api/frequent_products_test.rb

# T-Bank callback
bin/rails test test/controllers/callbacks/tbank_controller_test.rb \
  test/services/payments/tbank_adapter_test.rb

# Realtime / push
bin/rails test test/services/shop/guest_order_broadcaster_test.rb \
  test/integration/shop/api/push_register_test.rb
```

### 1.2 ISSUES 🔴 — блокеры / не код

| ID | Действие до «готово заказчику» |
|----|--------------------------------|
| **UserCards** | E2E real PAN на Point A; апрув скрин 8925 |
| **SBP 3001** | Включить СБП в кабинете Т-Кассы (не hotfix кода) |
| **Fly worker** | Worker running для `TbankCallbackJob` (RebillId delay) |
| **Legacy shop ~4-5 fail** | Не гейт deploy; triage отдельно |

### 1.3 Secrets & infra

| Переменная | Зачем |
|------------|-------|
| `TBANK_TERMINAL_KEY`, `TBANK_PASSWORD` | Init/Charge/Cancel |
| `TBANK_RETURN_URL` | `/payment/success\|fail` |
| NotificationURL в кабинете | `https://coffeeos.fly.dev/callbacks/tbank` (или prod host) |
| `SMS_RU_API_ID`, `SMS_RU_FROM` | OTP + cascade SMS |
| Firebase / VAPID | `push/register`, FCM |
| Apple Wallet certs | `wallet_pass`, APNs update |
| `CALLBACK_*` | legacy fiscal (если используется) |
| `SECRET_KEY_BASE` / `RAILS_MASTER_KEY` | Rails |

Сверка: `docs/operations/dev/INFRA_STACK.md` · `milestones/veha_2/runbooks/PAYMENT.md`

### 1.4 Preflight checklist

- [ ] Таргетные тесты §1.1 — PASS (или зафиксирован skip + причина)
- [ ] UserCards: понимание риска deploy без E2E real card
- [ ] T-Bank: NotificationURL + СБП enabled
- [ ] Fly worker / `perform_now` fallback понятен для webhook
- [ ] Нет незакоммиченных изменений в scope deploy
- [ ] **Не** писать тестовый OTP/PAN на профиль заказчика

---

## 2. Deploy

**Канон:** WSL, из корня репо:

```bash
cd /mnt/c/Tools/workarea/CoffeeOS
./bin/fly_deploy.sh
```

Скрипт: `--remote-only --depot=false` (см. `FLY_DEMO_STAND.md` §403 Depot).

**После deploy:**

1. `https://coffeeos.fly.dev/up` → 200
2. Release logs: `Shop A:` UUID Point A
3. `fly status -a coffeeos` — machine + worker (если отдельный process)

**Push:** только по явной просьбе владельца (`develop` → remote → deploy).

---

## 3. Post-deploy MCP matrix (Point A)

URL: `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`

| # | Задача / зона | Сценарий | PASS/FAIL/skip | Артефакт |
|---|---------------|----------|----------------|----------|
| 1 | UserCards | new_card save_card=true → GET user/cards | | `artifacts/usercards_*` |
| 2 | Durable session | cold start PWA + refresh_token → остаётся auth | | `pwa_durable_sessions_*` |
| 3 | Phone auth | flash_call×2 → sms wizard | | `auth_funnel_*` |
| 4 | Profile merge | link phone/email, cards на survivor | | `profile_merge_*` |
| 5 | One-click | saved card pay + poll status | | |
| 6 | Invalid token | reject → fallback sheet SBP/карта+ | | `tbank_widget_oneclick_*` |
| 7 | SBP deep link | sbp/init → bank app → return poll | | `sbp_deep_link_*` |
| 8 | Inline FSM | кнопка processing → CONFIRMED/REJECTED | | |
| 9 | Widget init | widget_init connection_type Widget | | |
| 10 | SBP autopay | bind + charge (если AccountToken есть) | skip если нет bind | |
| 11 | Active orders | barista status → sheet без reload (#47) | | |
| 12 | Quick repeat | frequent visible/hidden по active | | |
| 13 | Multi receipt | expanded accordion lines | | |
| 14 | Push register | POST push/register 200 | skip если FCM off | |
| 15 | Wallet | wallet_pass download iOS path | skip без certs | |
| 16 | Cancel refund | accepted → cancel → refunded | | `tbank_auto_refund_*` |
| 17 | Action buttons | cancel/chat/tips по status matrix | | |

Заполнять после MCP прогона. **Local green ≠ закрытие пункта** для заказчика.

---

## 4. Порядок приёмки (зависимости)

```
Session/auth → UserCards → payments (one_click/SBP/widget) → active_orders/frequent
  → barista status → push/wallet/cascade → cancel/refund
```

Не начинать payment MCP без рабочей session + email/phone verify.

---

## 5. Rollback triggers

| Симптом | Действие |
|---------|----------|
| Payment regression Point A (init/charge/webhook) | Stop rollout; revert deploy; ISSUES |
| Mass 401 на `session/refresh` | Проверить mobile_sessions migration; rollback |
| RebillId miss rate ↑ после deploy | Worker logs; TbankCallbackJob; GetState sync |
| Stuck active блокирует оплату | `abandon`/finalize smoke; не откатывать без данных |

Rollback: предыдущий Fly release (`fly releases -a coffeeos` → deploy image).

---

## 6. После приёмки

- [ ] SESSION_STATE + HANDOFF + CHANGELOG
- [ ] customer_tasks README: апрув `[ ]` → только после «ок» заказчика
- [ ] ISSUES: закрыть или обновить UserCards / #47 по факту MCP
- [ ] Entire `/review`: `entire checkpoint explain <sha>` vs gap-matrix

---

## Связанные runbooks

- [`FLY_DEMO_STAND.md`](../demo/FLY_DEMO_STAND.md)
- [`milestones/veha_2/runbooks/PAYMENT.md`](../milestones/veha_2/runbooks/PAYMENT.md)
- [`milestones/veha_2/runbooks/USERCARDS_SAVE_CARD_FLOW.md`](../milestones/veha_2/runbooks/USERCARDS_SAVE_CARD_FLOW.md)
- [`milestones/veha_2/runbooks/SHOP_PWA.md`](../milestones/veha_2/runbooks/SHOP_PWA.md)

*2026-08-10 · docs-only audit step; deploy по апруву владельца*
