# Bridge: Т-Банк (эквайринг, карты, СБП)

| Роль | Путь |
|------|------|
| Адаптер | `app/services/payments/tbank_adapter.rb` |
| Webhook | `POST /callbacks/tbank` → `Callbacks::TbankController#notify` |
| Job | `Payments::TbankCallbackJob` (retry ×5, `:critical`) |
| Статус | `Callbacks::PaymentStatusUpdater` |
| Карты | `Payments::SavedCardStore` → `mobile_payment_methods` |
| СБП | `Payments::SbpAccountTokenFromWebhook`, `Payments::TbankSbpAutopay` |
| GetState | `Payments::TbankPaymentSync` (webhook опоздал / без RebillId) |
| Init витрина | `Shop::WidgetPaymentInitiator`, `SbpPaymentInitiator`, `NewCardPaymentService`, `OrderCreator` |

## Endpoints

- `POST /callbacks/tbank` — статусы, RebillId, RequestKey (СБП)
- `GET /payment/success|fail` — return URL
- Init/charge — только через сервисы выше

## Mapping

| Внешний | Наш | Где |
|---------|-----|-----|
| `OrderId` | `orders.id` | `TbankCallbackJob` → Payment |
| `PaymentId` | `payments.provider_payment_id` | upsert статуса |
| `CustomerKey` | `mobile_customers.id` | recurrent / one-click / SBP |
| `RebillId` | `mobile_payment_methods.card_token` | `SavedCardStore` (rebill или pan+exp) |
| `RequestKey` | СБП token flow | `SbpAccountTokenFromWebhook` |

## Статусы (`TBANK_STATUS_MAP`)

`CONFIRMED`→succeeded · `AUTHORIZED`→processing · `REJECTED|REVERSED|CANCELED`→failed · `REFUNDED`→refunded · `PARTIAL_REFUNDED`→partially_refunded

Terminal-статус **не даунгрейдится** устаревшим webhook (`PaymentStatusUpdater`).

## Идемпотентность & async

- Idem: `tbank:callback:{PaymentId}:{Status}` · TTL 24h · `Payments::CacheCounter`
- Подпись: `TbankAdapter.verify_notification` (SHA256 Token+Password)
- Fly: `perform_now` в контроллере, `perform_later` fallback (worker часто stopped)
- Circuit breaker: `tbank:cb:*` (5 fail → open 60s)

## ENV

`TBANK_TERMINAL_KEY` · `TBANK_PASSWORD` · `TBANK_RETURN_URL`

## Риски

| Риск | Куда |
|------|------|
| Webhook без RebillId + save_card | `TbankPaymentSync#sync_for_rebill!` |
| Duplicate webhook | `{ ok: true, duplicate: true }` |
| Race webhook vs polling | тест `race: webhook AUTHORIZED after polling-confirm` |
| save_card=false | `SavedCardStore.allowed_for?` — карту не пишем |
| Worker stopped Fly | `docs/operations/milestones/veha_2/artifacts/usercards_*` |
| ErrorCode 3001, 119… | webhook/GetState/кабинет — не всегда баг приложения |

## Проверка

```bash
bin/rails test test/controllers/callbacks/tbank_controller_test.rb
bin/rails test test/services/payments/tbank_adapter_test.rb
bin/rails test test/integration/shop/shop_usercards_phase1_persist_test.rb
```

Приёмка: Fly MCP **Point A** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`.
