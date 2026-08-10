# todo — post-deploy G1–G4 (2026-08-10)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| push + fly v445 + MCP Point A smoke | G1–G4 на Fly | апрувы заказчика · хвосты backlog |

## MCP Point A v445
- [x] Point A ул. Ленина, 10
- [x] Session: Профиль › 2bc3…4c · Aram email+phone (без OTP)
- [x] «повторить» + 1-клик на каталоге
- [x] PaymentMethodsSheet *5953/*8782 · СБП disabled
- [x] pay-stack: OrderStatusSheet **отсутствует** (G3)
- [ ] Live ready push/SMS — skip (нет live barista→ready в этом прогоне)
- [ ] E2E real MIR UserCards — backlog

## Deploy
- push `develop` → `4e52ac6e`
- fly deploy → **v445** web+worker started
