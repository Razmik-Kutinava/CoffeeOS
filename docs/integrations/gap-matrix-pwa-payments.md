# Gap matrix — PWA / payments batch (2026-08-10)

Аудит scope: customer_tasks README + 17 эпиков из batch-deploy. Сверка с `config/routes.rb`, controllers, `ISSUES.md` ## 🔴 Открыто.

**Легенда «В bridge»:** до этого шага (2026-08-10) — частично; после — см. `shop-api.md`, `pwa-realtime.md`, обновлённые секции.

---

## Матрица по задачам

| Задача | Shop API | T-Bank | WS / Push / Barista | БД keys | Было в bridge | Риск / зависимость |
|--------|----------|--------|---------------------|---------|---------------|-------------------|
| UserCards save_card | `payments/new_card`, `user/cards`, `payments/card_config`, `payments/status`, `orders/finalize` | Init, FinishAuthorize, webhook RebillId, GetState sync | — | `mobile_payment_methods`, `CustomerKey` | частично tbank | 🔴 ISSUES: E2E real PAN; Fly worker → delayed RebillId |
| Долговечные сессии | `session/refresh`, email/phone verify | — | — | `mobile_sessions.refresh_token` | **нет** | Слабая session → `user/cards` пустой |
| Email↔Phone merge | `profile/link_*`, `email_otp/*`, `phone_otp/*` | — | — | merge → `mobile_payment_methods` FK | sms-auth § Identity | Карты «пропали» после merge без reassign |
| Quick Repeat | `frequent_products`, `cart/add` | — | — | `has_active_order` | **нет** | Stale active → скрывает повторы (#42, #47) |
| СБП Deep Link v2 | `payments/sbp/init`, `payments/status` | Init, GetQr, webhook | CODE:BLACK poll | `payments`, orders | частично | ErrorCode 3001 — кабинет Т-Кассы |
| Auth Flash×2→SMS | `phone_otp/send\|verify\|status` | — | — | `mobile_otp_codes` | sms-auth | messenger **снят** — не восстанавливать |
| Repeat invalid token | `user/cards`, `payments/one_click`, `payments/new_card`, widget/sbp fallback | Charge, Init | — | `card_token` expiry | частично | Зависит от UserCards + session |
| SpeedPay widget | `payments/widget_init` | Init `connection_type:Widget` | SDK redirect | order amount из БД | **нет** | ≠ inline FSM; fallback при ErrorCode 119 |
| Inline payment FSM | `payments/one_click`, `payments/status` | Charge / Init+Confirm via GetState | poll 1.5s | — | частично | Confirm на AUTHORIZED в status action |
| SBP Autopay | `payments/sbp/init` (bind), `payments/sbp/charge` | Init Recurrent+QR, ChargeQr, RequestKey webhook | — | AccountToken | частично | Zero-Click ждёт bind в банке |
| Compact status + Push | `orders/active`, `session/reconnect` | — | Cable, barista `update_status` | `ready_notified_at` | notify draft | Upstream только barista, не shop |
| Multi-status + receipt | `orders/active`, `orders/history` | — | Cable payload receipt | order_items | **нет** | Расширение JSON active, не новый route |
| OS-detect Wallet/Push | `orders/:id/wallet_pass`, `push/register` | — | FCM | push_token | **нет** | VAPID/FCM env |
| FCM progress + Wallet | `push/register`, `wallet_pass` | — | FCM tag/actions, APNs pass update | `order_wallet_passes` | **нет** | SW action → `orders/cancel` |
| Cascade ready | — | — | WS→Push→Wallet→SMS | `order_notification_logs` | частично | Presence skip SMS |
| Auto refund cancel | `orders/:id/cancel` | `/v2/Cancel` | Broadcaster on cancel | payment refunded | частично | Только accepted + succeeded |
| Action Buttons | `orders/cancel`, push/wallet | — | UI matrix по status | — | **нет** | Согласовано с #40 |

---

## Hot-path endpoints вне задач (слепые зоны до аудита)

| Endpoint | Зачем | Связанные задачи |
|----------|-------|------------------|
| `POST session/reconnect` | WS fallback, guest order binding | B1.1, #35, #47 |
| `POST orders/:id/abandon` | Сброс pending_payment, stuck sheet | #35, #42 |
| `POST orders/:id/finalize` | Post-pay sync + clear cart | UserCards, SBP return |
| `GET config` | `operating_hours.is_open` | B1.11 guard на payments |
| `OperatingHoursGuard` на payments | Блок оплаты при закрытой точке | все payment flows |
| `POST callbacks/tbank` | RebillId, RequestKey | все оплаты |
| `GET payment/success\|fail` | Return после банка/SBP | SBP, widget |

---

## Payment UX — decision tree (конфликт задач)

```
Есть сохранённая карта (RebillId)?
├─ Да, repeat/one-click → POST payments/one_click (+ poll status)     [inline FSM]
├─ Да, widget flow      → POST payments/widget_init + T-Kassa SDK     [SpeedPay]
├─ Новая карта          → GET card_config + POST payments/new_card    [UserCards]
├─ СБП разовый          → POST payments/sbp/init → qr.nspk.ru         [CODE:BLACK]
└─ СБП autopay          → sbp/init bind → sbp/charge ChargeQr         [Autopay]

Fallback при отказе карты (119/1051): widget task → inline SBP + «карта +» без потери orderId.
```

---

*Артефакт Фазы A. Bridge: `INTEGRATIONS.md` · runbook: `docs/operations/runbooks/DEPLOY_PWA_PAYMENTS_BATCH.md`*
