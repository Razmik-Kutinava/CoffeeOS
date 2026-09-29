# Gates: TASK_99 — iOS: восстановление системного диалога разрешения WebPush

Scope: `registerShopPush()` вызывает `Notification.requestPermission()` первым async-шагом (после синхронной проверки `"Notification" in window`), `isSupported()` / `firebaseClientConfigured()` / `getToken()` — только после `granted`; аккордеон импортирует `firebasePush.js` статически; backend / FCM / PassKit / SMS / контракт `/push/register` без изменений.

- [x] G1: push-подписка — порядок вызовов + granted/denied/default/unsupported + путь аккордеона (Subtask 1–7)
  CHECK: node --test test/javascript/order_status_push_subscribe_test.mjs
  EXPECT: # fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=e158c6c412e51ac2daef3b9084ffd8fa0b9aa63c494982a1241aa03851c713cd; exit=0; EXPECT=matched; output-sha256=2a57b364f7fa6abf0355fa623188194aaa86cbe6cf980250f9e604a7422e986f; output-bytes=4318; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G2: статический оракул — нет `import("./firebasePush.js")`, есть статический импорт, `requestPermission` < `isSupported` < `getToken` в `registerShopPush` (DoD 1–4)
  CHECK: node -e "const fs=require('fs');const a=fs.readFileSync('app/frontend/lib/orderStatusNotifyActions.js','utf8');const f=fs.readFileSync('app/frontend/lib/firebasePush.js','utf8');const b=f.slice(f.indexOf('export async function registerShopPush'));const noDyn=!/import\(.\.\/firebasePush\.js/.test(a);const st=/^import .*from .\.\/firebasePush\.js./m.test(a);const ord=b.indexOf('requestPermission(')<b.indexOf('isSupported(')&&b.indexOf('isSupported(')<b.indexOf('getToken(');const ok=noDyn&&st&&ord;console.log('noDyn='+noDyn+' static='+st+' order='+ord);console.log(ok?'ORDER_OK':'ORDER_BAD');process.exit(ok?0:1)"
  EXPECT: ORDER_OK
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending

- [x] G3: регрессия зоны — notify actions / init / аккордеон / SW actions / order status sheet
  CHECK: node --test test/javascript/order_status_notify_actions_test.mjs test/javascript/order_status_notify_init_test.mjs test/javascript/active_orders_accordion_test.mjs test/javascript/sw_notification_actions_test.mjs test/javascript/order_status_sheet_test.mjs
  EXPECT: # fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=cc6a6b020080e5a467285676fdebb20ca45cf0dd92e74ec8171365eeb4dda8c1; exit=0; EXPECT=matched; output-sha256=d5b05e95cb715e839e9ebc6bf4fcc85c63bbf228b4acb82af1846922a75e97c2; output-bytes=19438; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G4: физический iPhone — системный диалог сразу после клика, приложение в «Настройки → Уведомления», токен сохранён (Subtask 8)
  EVIDENCE: pending — manual, после deploy по апруву (скрин/запись + строка `push_token` у гостя)

- [ ] G5: hot-path Fly MCP Point A — витрина / статус заказа / `/push/register` отвечают, без 5xx после deploy
  EVIDENCE: pending — после deploy по апруву; tenant `2fdee1ac-4674-41ee-b89e-87b45643f789`

<!--
CoffeeOS TASK_99 unlazy (2026-09-29, ledger до /sbr):
- Baseline до правок: G1 18/18 pass (новых тестов порядка ещё нет → на /sbr RED они должны упасть), G3 88/88 pass, G2 ORDER_BAD (noDyn=false static=false order=false) — ожидаемо.
- ТЗ: `npm test -- …` и `npm run typecheck` в репо не существуют (package.json: только vite:dev/vite:build, TS нет) → канон `node --test`; typecheck не применим.
- Проверено: `import('./app/frontend/lib/firebasePush.js')` в Node 20 грузится (IMPORT_OK) → статический импорт не ломает node-тесты orderStatusNotifyActions.
- TEMP DIAG `diag()` → onToast синхронный, до requestPermission не создаёт await; не трогаем (вне scope).
- G4/G5 manual; deploy — только апрув.
-->
