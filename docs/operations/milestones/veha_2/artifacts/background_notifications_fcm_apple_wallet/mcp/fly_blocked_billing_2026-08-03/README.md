# MCP #38 — blocked pending Fly billing

**Дата:** 2026-08-03  
**Push:** `develop` `a145ee0c` → origin **OK**  
**Image build:** `registry.fly.io/coffeeos:deployment-01KZ3QRBRX8E2VES9XFJSBGDJ4` **OK** (remote builder `--depot=false`)  
**Release / machine update:** **BLOCKED** Fly org billing 403  
  - URL: https://fly.io/dashboard/razmik-kutinava/billing  
  - Live remain: **v419** `deployment-01KZ3CAC9RNSCPZRZ5VZWEWW8K`  
**MCP on new #38 code:** **SKIP** — стенд ещё без релиза  

## После пополнения billing

```text
fly deploy -a coffeeos --remote-only --depot=false
# или
fly deploy -a coffeeos --image registry.fly.io/coffeeos:deployment-01KZ3QRBRX8E2VES9XFJSBGDJ4
```

Затем MCP Point A (Aram / active orders):
1. OrderStatus CTAs max 2 (accepted: Отменить + Push/Wallet; preparing: Чат + Чаевые/Wallet)
2. `/firebase-messaging-sw.js` содержит `notificationclick`
3. Android UA / iOS CriOS accordion CTAs (регресс #37)
4. `GET /shop/api/orders/:id/wallet_pass` session → pkpass/simulate

**Verdict:** deploy+MCP **blocked_billing** · code on git ready
