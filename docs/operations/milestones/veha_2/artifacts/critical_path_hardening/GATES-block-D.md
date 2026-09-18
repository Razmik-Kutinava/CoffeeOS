# Gates: TASK_93-D / #93 — История заказов / ЛК список (per_page)

Scope: `GET /shop/api/orders/history` default `per_page=20` (не 1) при отсутствии/нуле/мусоре; max 50; `today=1` без изменений размера логики фильтра; ЛК/«сегодня» показывают пачку заказов. Deploy = TASK_93-L (не DoD блока D).

- [x] G1: матрица T-D1a–d + T-D3a/b (history default / blank / cap / explicit / today)
  CHECK: ruby bin/rails test test/integration/shop/api/orders_controller_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=e008122e517be9dd5bf2310fadeae9f57e9ae3a10831cd74804e437d6180d83b; exit=0; EXPECT=matched; output-sha256=f57bb9a849db7b613ca63ea560358f182a92faa4eb313435708c20dd7bdc737e; output-bytes=1633; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: узкий регресс зоны shop orders API (§8)
  CHECK: ruby bin/rails test test/integration/shop/api/orders_controller_test.rb test/integration/shop/api/mvp_flow_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=adaed0855350087f846fdec25730c319a103added965800ba059dc54281dcbf2; exit=0; EXPECT=matched; output-sha256=4b300cc433089389d149af9583c4a90debf780be38979ac77fd7b86e439c65ab; output-bytes=1635; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G3: D2 клиент — нет `per_page=1` в shop ЛК/orders; default 20 согласован
  EVIDENCE: pending REVIEW formalize — 2026-09-18 regress grep: нет `per_page=1` в frontend routes; `shopAccountOrders.js` `perPage || 20`; PersonalAccount/Orders без param (сервер 20)

- [ ] G4: hot-path Fly MCP Point A — ЛК history ≥2 заказов на стенде
  EVIDENCE: abandoned — not DoD for TASK_93-D; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · session customer · GET history без per_page → json.length ≥ 2 при ≥2 заказах

ABANDON: G4 Fly MCP Point A is TASK_93-L DoD, not block D; Local G1–G2 + REVIEW G3 close D

<!--
CoffeeOS TASK_93-D:
- 2026-09-18 /regress: G1/G2 met via --approve; Local 20 runs 0 fail
- Close D: G3 в /review; G4 abandoned until L
-->
