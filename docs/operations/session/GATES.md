# Gates: TASK_93-D / #93 — История заказов / ЛК список (per_page)

Scope: `GET /shop/api/orders/history` default `per_page=20` (не 1) при отсутствии/нуле/мусоре; max 50; `today=1` без изменений размера логики фильтра; ЛК/«сегодня» показывают пачку заказов. Deploy = TASK_93-L (не DoD блока D).

- [ ] G1: матрица T-D1a–d + T-D3a/b (history default / blank / cap / explicit / today)
  CHECK: ruby bin/rails test test/integration/shop/api/orders_controller_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending — unmet pre-RED; T-D* ещё не написаны; после RED/GREEN — length≥2 без per_page

- [ ] G2: узкий регресс зоны shop orders API (§8)
  CHECK: ruby bin/rails test test/integration/shop/api/orders_controller_test.rb test/integration/shop/api/mvp_flow_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending — `/regress` после GREEN

- [ ] G3: D2 клиент — нет `per_page=1` в shop ЛК/orders; default 20 согласован
  EVIDENCE: pending — manual/REVIEW: grep PersonalAccount.svelte · Orders.svelte · shopAccountOrders.js; либо без param (сервер 20), либо явный 20; T-D2a `perPage || 20`

- [ ] G4: hot-path Fly MCP Point A — ЛК history ≥2 заказов на стенде
  EVIDENCE: abandoned — not DoD for TASK_93-D; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · session customer · GET history без per_page → json.length ≥ 2 при ≥2 заказах

ABANDON: G4 Fly MCP Point A is TASK_93-L DoD, not block D; Local G1–G2 + REVIEW G3 close D

<!--
CoffeeOS TASK_93-D unlazy (pre-SPEC / pre-SBR):
- Канон: customer_tasks/TASK-93-Critical-path-hardening.md · блок D (R1–R5 default 20 / max 50)
- Зеркало: artifacts/critical_path_hardening/GATES-block-D.md
- Блок A: GATES-block-A.md · Блок B: session был B → artifacts/.../GATES.md (не трогать)
- Close D: G1–G2 met via --approve/--reverify after GREEN + /regress; G3 evidence в REVIEW; G4 abandoned until L
- Без T-D3a+b блок не закрыт
-->
