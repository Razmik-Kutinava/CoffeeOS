# CHANGELOG

## Шапка

**Текущий месяц:** `2026-09`  
**Архив:** [`archive/README.md`](archive/README.md) — `CHANGELOG-2026-06.md` … `CHANGELOG-2026-08.md`

> Агент: **не читать** весь CHANGELOG на старте. Писать новую запись сверху текущего месяца. Архив — по запросу.

---

## Текущий месяц (2026-09)

## 2026-09-18 — docs: REVIEW close #93 TASK_93-H cart overflow

- Local bugbot+security → fix `e80790c9` · CI green on develop tip
- H1–H3 PASS · G5→L · без deploy
- Next: deploy — только по апруву владельца

## 2026-09-18 — docs: CI green #93 TASK_93-K REVIEW

- CI `35335419241` green `c87377fc` · K1–K7 · G5→L
- Unblocks: Brakeman deep_dup · Rack::Attack test MemoryStore

## 2026-09-18 — docs: REVIEW done #93 TASK_93-F CI green

- Local 68/0 · F1–F5 PASS · bugbot + security PASS · Entire `01M2SSQXT1V67AK260SH1P9RAX`
- CI green `35335419241` · GREEN `1b28a128`
- Next: deploy апрув · Fly MCP = L

## 2026-09-18 — fix: #93 TASK_93-H REVIEW cart overflow holes

- `MAX_SESSION_CART_BYTES` 3072→**2048** (OTP/customer/cookie crypto headroom)
- `remove!`/`clear!`/qty−: `touch_cart_session!(enforce_budget: false)` — legacy over-cap не 500
- `CartController` `rescue_from OverflowError` на все actions + CookieOverflow gate
- Tests T-H1d · T-H2d · zone Local PASS
- Next: push/CI · deploy апрув · Fly MCP = L

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-I GATES G1-G4 met

- --reverify GATES-block-I: met **4** · abandoned **1** (G5→L)
- Next: /review (код не трогали)

## 2026-09-18 — feat: #93 TASK_93-J Push/worker async + FCM cache [GREEN]

- `PassUpdateJob` · GuestOrderBroadcaster без sync PassUpdater · cascade wait GRACE+5s
- `PaymentStatusUpdater` broadcaster после `with_lock` · FCM OAuth cache 50m + UNREGISTERED clear
- Runbook `SOLID_QUEUE_FLY.md` · Local T-J* + zone 53/0 · barista/tbank 20/0
- Next: `/regress`

## 2026-09-18 — docs: REVIEW #93 TASK_93-F Callbacks/stuck/Events

- Local notify pack **68/0** · F1–F5 PASS · bugbot no bugs · security PASS
- Entire `01M2SSQXT1V67AK260SH1P9RAX` · GREEN `1b28a128`
- Next: push/CI · deploy апрув · Fly MCP = L

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-H G1–G4 met (G5 to L)

- `GATES-block-H.md`: `--approve` + `--reverify` PASS (G1–G4); G5 abandoned→L
- automatic-evidence на overflow + cart_service + persistence/modifiers
- Next: `/review`

## 2026-09-18 — docs: regress PASS #93 TASK_93-I OTP / Rack::Attack

- Matrix: **23 runs / 0 fail / 1 skip** (T-I1b no local Redis) — store · verify · short_link · phone_otp
- Zone: **27 runs / 0 fail** — phone_otp API · order_short_links · phone_otp service
- GATES I G1–G4 met · G5→L · GREEN \c14f5202- Next: \/review\ · Fly Redis = L

## 2026-09-18 — docs: regress PASS #93 TASK_93-H cart cookie overflow

- Zone: `cart_service` + `cart_overflow` + `cart_persistence` + `b113_s4_cart_modifiers` → **53 runs, 0 fail**
- GATES-block-H G1–G4 met · G5→L
- Next: `/review`

## 2026-09-18 — docs: REVIEW #93 TASK_93-K hygiene + PaymentURL blank fix

- bugbot: prod blank PaymentURL → empty (not 422) · security: no med+ · K6 sha · K7-B note
- Table K1–K7 PASS · G5→L · push

## 2026-09-18 — feat: #93 TASK_93-H cart cookie overflow [GREEN]

- `CartService::OverflowError` · `MAX_CART_LINES=20` · `MAX_SESSION_CART_BYTES=3072` · rollback guard
- Controller add+update → 422 + clear; no bare CookieOverflow
- RED `5a635be3` · GREEN `d8e5636b` · Local 28 PASS (T-H* · T-H2c SKIP)
- Next: `/regress`

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-F G1–G4 met (G5 to L)

- `GATES-block-F.md`: reverify PASS (G1–G4); G5 abandoned→L
- Первый reverify flake: missing `redis` gem (TASK_93-I) → `bundle install` → PASS
- Next: `/review`

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-E G1–G4 met (G5 to L)

- `session/GATES.md` + `GATES-block-E.md`: G1–G3 approve+reverify PASS · G4 cite met · G5→L
- `--status`: met 4, abandoned 1 · коммит `4905294f`
- Next: `/review`

## 2026-09-18 — docs: REVIEW #93 TASK_93-B Checkout identity

- Local 50/0 · bugbot R4 fix (`find_existing!` ≡ orders) · security: EmailVerification tenant DB → ISSUES backlog
- GREEN `2213cbeb` · R4 `4217cab5` · Entire `01M2STWJAMB844CP992D067NWP`
- Next: push/CI · deploy апрув · Fly = L

## 2026-09-18 — docs: regress PASS #93 TASK_93-F Callbacks/stuck/Events

- Notify pack: **68/0** · zone callbacks/jobs/sync: **74/0**
- GATES-block-F G1–G4 met · G5→L · GREEN `1b28a128`
- Next: `/review` · Fly MCP Point A = TASK_93-L

## 2026-09-18 — docs: regress PASS #93 TASK_93-E Init idempotency

- G1 Init: **30/0** · G2 orders+§2.3+base: **55/0** · total **85/0**
- GREEN `2eb22c71` · Next: `/review` · Fly MCP Point A = TASK_93-L

## 2026-09-18 — docs: REVIEW #93 TASK_93-G Tenant GUC / RLS

- Local 30/0 · bugbot clean · security: no med/high/crit
- Entire `01M2SSXE54SV4CM341NHXR0SCE` на `7c34314a` · GATES G1–G4 met · G5→L
- Таблица G1–G6 PASS · push/CI · **без deploy**

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-K G1–G4 met (G5 to L)

- `GATES-block-K.md`: reverify PASS G1–G4; G5 abandoned → TASK_93-L
- Next: `/review`

## 2026-09-18 — feat: TASK_93-E Init idempotency [GREEN]

- GREEN `2eb22c71` · RED `0a7e72ba` · zone 53/0
- `base_controller`: session SET GUC (не long txn) · `OrderCreator`: savepoint + pid guard + `ClientOrderReused`
- Next: `/regress` §2.3

## 2026-09-18 — docs: regress PASS #93 TASK_93-K hygiene pack

- Zone: sanitize · demo · paymentUrl · merger · collector · menu sort_order · onboarding
- Local: **35 runs / 0 failures** (seed 50003) · GREEN `39b38d58` · G1–G4 met · G5→L
- Next: `/review` · Fly MCP Point A = TASK_93-L

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-G gates met

- GATES-block-G: G1–G4 **met** (--reverify); G5 Fly **abandoned** → TASK_93-L
- Local evidence automatic; Next: /review

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-B gates met

- `GATES-block-B.md`: G1–G3 **met** (--reverify); G4 UI; G5 Fly **abandoned** → TASK_93-L
- Next: `/review`

## 2026-09-18 — review: TASK_93-D history per_page PASS

- D1–D3 PASS · Local 20/0 · bugbot 0 · security 0 · Entire `01M2STB3BHJ65BAYQM492QTT7P`
- GREEN `9d2b98a8` · Deploy = TASK_93-L (не сейчас)

## 2026-09-18 — docs: regress PASS #93 TASK_93-G Tenant GUC / RLS

- Zone: staff_pg_context + rls_tenant_isolation + db_triggers + customer_tenant_history → **22/0**
- GATES-block-G: G1–G4 met · G5 abandoned→L
- Next: `/review`

## 2026-09-18 — docs: regress PASS #93 TASK_93-B Checkout identity

- Zone: order_creator + recurrent + checkout_identity + email_otp + one_click + new_card → **47/0**
- `gate-check --reverify` GATES-block-B: G1–G3 met · G4 UI · G5 abandoned→L
- Next: `/review`

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-D gates met

- `GATES-block-D.md`: G1–G3 **met** (--reverify + G3 grep); G4 Fly **abandoned** → TASK_93-L
- Next: `/review`

## 2026-09-18 — docs: REVIEW done #93 TASK_93-C SMS short link · CI green

- C1–C5 PASS · GREEN `c2ef2d68` · fix `6254ab0d` · CI https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35326857443
- bugbot clean · security no medium+ · Entire `01M2SSQXT1V67AK260SH1P9RAX` · GATES G1–G5 met · G6→L
- Next: deploy — только апрув (TASK_93-L)

## 2026-09-18 - review done: #93 TASK_93-A CI green

- A1-A6 PASS · FIX 77291dc6 trigger no-op · push develop · CI 35326857443 SUCCESS (tip 7c34314a)
- Entire 01M2SSQXT1V67AK260SH1P9RAX · GATES G1-G3 met · G4 Fly = L
- Next: deploy only with owner approval

## 2026-09-18 - review: #93 TASK_93-A money-order + trigger no-op

- bugbot/security: hard auto_deduct bypassed soft-fail -> migration no-op; Ruby sole deduct
- FIX 77291dc6 · Local A zone 80/0 · Entire 01M2SSQXT1V67AK260SH1P9RAX
- Next: push · CI · deploy=L

## 2026-09-18 — feat: GREEN #93 TASK_93-B Checkout identity phone-first

- `Shop::CheckoutIdentity` · OrderCreator / RecurrentOrderCreator
- Checkout `identityReady = phoneVerified || emailVerified`
- Tests 47/0 · RED `f6e2f3ca` · GREEN `2213cbeb` · Entire `01M2STWJAMB844CP992D067NWP`
- Next: `/regress`

## 2026-09-18 — docs: REVIEW #93 TASK_93-C SMS short link

- Local 18/0 · bugbot clean · security no medium+ · Entire `01M2SSQXT1V67AK260SH1P9RAX` на `c2ef2d68`
- GATES G1–G5 met · G6→L · push/CI · без deploy

## 2026-09-18 — docs: regress PASS #93 TASK_93-D history per_page

- Local: `orders_controller_test` + `mvp_flow_test` — **20 runs, 0 failures**
- `GATES-block-D`: G1/G2 **met** (--approve); G3 REVIEW; G4→L
- Next: `/review`

## 2026-09-18 — docs: SPEC #93 TASK_93-K Hygiene pack (K1–K7)

- `todo-block-K.md` (+ session todo): R1–R7 · K7-**B** · paymentUrl prod 422 · DEFER пусто
- Не ломать / Проверка · Next: `/sbr` RED

## 2026-09-18 — docs: SPEC #93 TASK_93-I OTP / Rack::Attack / auth abuse

- `todo-block-I.md` (+ session todo): R1 Redis · R8 fail-boot · R3/R4 verify 5/min · R5 I3=6 · R6 no dupe /o/ · R9 CI redis
- Файлы 7 + blast · Не ломать · Проверка
- Next: `/sbr` RED (код не трогали)

## 2026-09-18 — docs: pin TASK_93-G SPEC (todo-block-G canon)

- Канон: `todo-block-G.md` + `GATES-block-G.md` + `RLS_PG_INVENTORY.md`
- R1–R6 · **R3-B** · `app.shop_city_lookup` · Next: `/sbr` RED

## 2026-09-18 — docs: SPEC #93 TASK_93-G Tenant GUC / RLS / schema

- `todo-block-G.md` + `RLS_PG_INVENTORY.md`: R1 txn · R2 staff · **R3-B** · R5 city GUC · R6 raise except test
- Не ломать · Проверка · Next: `/sbr` RED

## 2026-09-18 — docs: unlazy #93 TASK_93-G Tenant GUC / RLS / schema

- `GATES-block-G.md` + session `GATES.md`: G1 staff T-G1 · G2 inventory/ensure/fresh T-G2–G4 · G3 city T-G5 · G4 regress+T-G6 · G5→L
- `--status`: unmet 4 · abandoned 1 (G5)
- Next: `/spec` (код не трогали)

## 2026-09-18 — docs: SPEC #93 TASK_93-F Callbacks/stuck/Events

- `todo.md` + `todo-block-F.md` → TASK_93-F: R1 fail-closed · R2/R3 release claim on reject · R4 stuck GetState · R5 fiscal report+1 retry · R6 422
- Файлы 7 + blast · Не ломать · Проверка G1/G4
- Next: `/sbr` RED (код не трогали)

## 2026-09-18 — docs: unlazy #93 TASK_93-F Callbacks/stuck/Events

- `GATES-block-F.md` + session `GATES.md`: G1 Events T-F1/F2/F5 · G2 stuck T-F3 · G3 fiscal T-F4 · G4 regress · G5→L
- `--status`: unmet 4 · abandoned 1 (G5)
- Next: `/spec` (код не трогали)

## 2026-09-18 — docs: SPEC #93 TASK_93-E Init idempotency

- `todo.md` + `todo-block-E.md` → TASK_93-E: R1 pid · R2 uuid/failed txn · R3 HTTP вне base_controller txn · R4 tests
- Файлы 7 + blast · Не ломать · Проверка G1/G2 · зеркало от race с A/B/D
- Next: `/sbr` RED (код не трогали)

## 2026-09-18 — docs: restore SPEC #93 TASK_93-B (todo after D race)

- `todo.md` снова TASK_93-B phone-first (после параллельного SPEC D)
- Next: `/sbr` RED

## 2026-09-18 — docs: SPEC #93 TASK_93-D history per_page

- `todo.md` → TASK_93-D: R1–R5 default 20 / max 50 · T-D1/T-D3
- Файлы 5 + blast · Не ломать · Проверка G1/G2
- Next: `/sbr` RED (код не трогали)

## 2026-09-18 — docs: SPEC #93 TASK_93-B Checkout identity

- `todo.md` → TASK_93-B: phone-first R1–R5 · файлы OrderCreator/Recurrent/Checkout · Не ломать · Проверка G1–G3
- CBR `#93` SPEC B · Next: `/sbr` RED (код не трогали)

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-E Init idempotency

- `session/GATES.md` + `artifacts/critical_path_hardening/GATES-block-E.md`
- G1 double Init / pid · G2 RecordNotUnique / concurrent uuid · G3 §2.3 regress · G4 HTTP вне txn (REVIEW) · G5 Fly **ABANDON** → TASK_93-L
- `gate-check --status`: unmet 4, abandoned 1; `--approve` после GREEN (baseline ≠ DoD без T-E*)
- Параллельно: A SPEC · C SPEC · B/D в `GATES-block-B/D.md`

## 2026-09-18 — docs: SPEC #93 TASK_93-C SMS short link

- `todo.md` → TASK_93-C: R2-A · TTL 48h · throttle 30/min · one-time SKIP
- Файлы 7 + blast · Не ломать · Проверка G1–G5
- Next: `/sbr` RED (код не трогали)

## 2026-09-18 — fix: CI ABAC-015 (revert TenantOperatingHours preload)

- Loaded-empty `weekday_schedules` → `open_now?` всегда true → 3 CI fails
- Revert preload; RUBY-1J batch aggregate остаётся (`94a7644b`)
- CI green: https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35323013520

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-B Checkout identity

- Канон ledger: `artifacts/critical_path_hardening/GATES-block-B.md` (session/GATES.md гоняют A/C/D)
- `--approve`: G3 baseline PASS; G1/G2 unmet (нет test files); G4 manual; G5→L
- Next: `/spec` B

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-D history per_page

- `session/GATES.md` + `artifacts/critical_path_hardening/GATES-block-D.md`
- G1 T-D1/T-D3 · G2 orders+mvp_flow · G3 D2 клиент (REVIEW) · G4 Fly **ABANDON** → TASK_93-L
- `gate-check --status`: unmet 3, abandoned 1; `--approve` после GREEN (baseline file PASS ≠ DoD без T-D*)
- Параллельно: A SPEC · B/C в `GATES-block-B/C.md`

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-C SMS short link (active)

- Активный `session/GATES.md` = **C** · канон `GATES-block-C.md` · зеркало `artifacts/.../GATES.md`
- G1 SMS host · G2 `/o/` bind · G3 throttle · G4 TTL · G5 zone · G6 Fly **ABANDON** → TASK_93-L
- `gate-check --status`: unmet 5, abandoned 1; `--approve` после GREEN (не сейчас)
- Параллельно: A SPEC · B/D в `GATES-block-B/D.md`

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-B Checkout identity (active)

- Активный `session/GATES.md` = **B** (восстановлен после коллизии с C)
- `--approve`: G3 baseline PASS; G1/G2 unmet (нет `recurrent_order_creator_test` / `checkout_identity_test`); G5→L
- `GATES-block-A/B/C.md` в artifacts; C сохранён в `GATES-block-C.md`
- Next: `/spec` B

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-C SMS short link

- `session/GATES.md` + `artifacts/critical_path_hardening/GATES.md` (+ `GATES-block-C.md`)
- B → `GATES-block-B.md`; A остаётся `GATES-block-A.md`; todo A → pointer на block-A
- G1 SMS host · G2 `/o/` bind · G3 throttle · G4 TTL · G5 zone · G6 Fly **ABANDON** → TASK_93-L
- `gate-check --status`: unmet 5, abandoned 1; `--approve` после GREEN (не сейчас)

## 2026-09-18 — docs: SPEC #93 TASK_93-A Critical path (деньги↔заказ)

- `todo.md` → TASK_93-A: файлы A1–A6 · Не ломать · Проверка G1/G2 · матрица T-A*
- Next: `/sbr` RED (код не трогали)

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-A Critical path (деньги↔заказ)

- `session/GATES.md` + `artifacts/critical_path_hardening/GATES.md`
- G1 матрица T-A* · G2 zone regress · G3 A4 Amount · G4 Fly **ABANDON** → TASK_93-L
- `gate-check --status`: unmet 3, abandoned 1; `--approve` после GREEN (не сейчас)

## 2026-09-18 — fix: Sentry RUBY-1J ChannelOrderStats N+1

- `Analytics::ChannelOrderStatsCollector`: один aggregate `GROUP BY tenant_id, source` + `SET LOCAL row_security = off` (вместо SET LOCAL tenant на каждый tenant)
- `TenantOperatingHours`: если `weekday_schedules` preloaded — фильтр в памяти
- Tests: collector + job + menu sort_order (RUBY-1K regression) PASS
- RUBY-1K: фикс уже в `64b99477`, ждёт deploy

## 2026-09-18 — docs: intake #93 TASK_93-B Checkout identity

- `customer_tasks/TASK-93-B-Checkout-identity.md` — ТЗ 1:1 (phone-first; UI Pay ≡ бэкенд)
- CBR `#93` → блок B · artifacts `critical_path_hardening/` · ISSUES #93
- Next: `/spec` (не код)

## 2026-09-18 — docs: intake #93 TASK_93 Critical path hardening (блок A)

- `customer_tasks/TASK-93-Critical-path-hardening.md` — ТЗ 1:1 (зонтик A–L; сейчас A: деньги↔заказ)
- CBR `#93` · `artifacts/critical_path_hardening/` · ISSUES строка #93
- Next: `/spec` (не код)

## 2026-09-18 — security: Dependabot pack (gems + npm)

- `view_component` 3.25 → **4.15.0** (GHSA preview/helper + system-test path; floor ≥4.9)
- `vite` → **8.0.16**, `devalue` → **5.9.2**, `svelte` lock 5.57 (npm audit 0)
- Rails/AS stack уже **8.1.3.1**, rack-session 2.1.2, puma 8.0.2 — bundler-audit clean
- **main** `d33f83c7`: sync lockfiles с develop → Dependabot **0 open / 93 fixed**; closed PRs #16–20
- Local: auth sessions 18 PASS; VC render smoke OK

## 2026-09-18 — fix: CodeQL ruby syntax warning on main

- `db/migrate/20250115000002_create_stage_2_payments.rb` на main: orphan `, if_not_exists: true, if_not_exists: true` → файл как на develop
- Push main `7ab6456c`; CodeQL Advanced main SUCCESS (ruby + js)

## 2026-09-18 — fix: CI Block F stock hard-fail test

- `BlockFStockFlowTest`: sale при нехватке остатка → 422 + stock unchanged (не soft-negative QA 4.2)
- Согласовано с `Inventory::OrderRecipeDeduction` hard-fail
- Local: block_f + deduction 8 PASS

## 2026-09-18 — ci: Semgrep → GitHub Code Scanning

- `.github/workflows/semgrep.yml`: p/ruby + p/javascript + p/rails → SARIF → `upload-sarif` (category semgrep)
- Алерты: Security → Code scanning (рядом с CodeQL); Actions → Semgrep

## 2026-09-18 — fix: CodeQL ReDoS + dismiss false positives

- ReDoS: `URI::MailTo::EMAIL_REGEXP` в email_otp / email_service / purchase / tbank_receipt; JS login_form без nested `+`
- Dismiss 13 alerts: CSRF callbacks/API (#2–#9, #15), test password (#14/#16), acceptance SSRF (#12), bank_card_id FP (#13)
- Open до rescan: #1 / #10 / #11 (закроются после CodeQL на push)
- Local: email_otp + receipt_builder 15 PASS

## 2026-09-18 — ci: CodeQL Advanced on develop + main (push)

- develop push `adae7af5`; main fix `fe1349a4` (убран broken manual if)
- Один workflow на обеих ветках — не удалять с main (триггеры develop+main)
- Languages: ruby + javascript-typescript; build-mode none

## 2026-09-18 — ci: CodeQL Advanced workflow (ruby + JS)

- `.github/workflows/codeql.yml`: develop+main; `javascript-typescript` + `ruby`; `build-mode: none`
- Без шага manual if (ломал GH expression на `"manual"`)

## 2026-09-18 — fix: GetState Amount + inventory hard-fail + #78 cancel/confirm

- GetState CONFIRMED: `notification_amount_matches?` до succeeded; blank Amount fail-closed
- Inventory: недостаточно остатка → `OrderRecipeDeduction::Error` (не clamp в 0)
- #78: `CancelService` + `ConfirmPaymentService` (GetState + PaymentFulfillment); Shop API не 501
- Local: Rails 46+4 PASS · JS CTA 17 PASS · Fly MCP skip (нет deploy)

## 2026-09-18 — fix: P0/P1 crits (tips, Tbank mismatch, FCM tenant, Callcheck×2, SMS HMAC)

- Tips CTA: default URL + same-tab fallback как chat (#94); FCM `action=tips` → `openTipsService`
- Tbank amount mismatch: raise + release idempotency claim + HTTP 422 (не silent OK)
- FCM payload `tenant_id`; SW cancel `?tenant_id=` + `X-Shop-Tenant`
- Callcheck ×2 (80s) затем SMS; SMS `/o/:hash` HMAC (не reversible UUID)
- #78: subscription CTA скрыт (501 stubs); Wallet CTA скрыт без certs; Events Amount kopecks; stock clamp ≥0
- Local: JS 73+45 PASS · Rails 82+25 PASS · Fly MCP skip (нет deploy)

## 2026-09-17 — docs: #82 Патч_1 CI green after REVIEW

- CI green `35234267606` · review sha `f0ccc4a5` · Entire `01M2QWCCYY5P9QNJBJFBJSS6DK`
- Fly MCP Point A после deploy апрув

## 2026-09-17 — review: #82 Патч_1 cascade Presence grace + SMS short link

- GREEN `9b087faf` · FIX `3f6ac720`: `/o/:hash` bind guest session + `reconnect_token`
- Presence: `begin_sms_grace!` suppress Cable reconnect; Presence fail → `retry_on`
- SMS: `codeblack.xyz/o/{order_hash}` ≤70 · Entire `01M2QWCCYY5P9QNJBJFBJSS6DK`
- bugbot high (session) закрыт · security medium+ нет · Local 36/0 · push/CI
- Fly MCP Point A после deploy апрув

## 2026-09-17 — docs: sync ID заказчика (TASK_89 trio · 90/91/92)

- Правило: ID заказчика = канон (`coffeeos-customer-intake.mdc`); EXT = суффикс, не новый `#`
- CBR/ISSUES: TASK_89 + TASK_89-UI-EXT + TASK_89-POSTCALL-EXT; #90=TASK_90 · #91=TASK_91 · #92=TASK_92 (сняты ошибочные #93/#94)
- Шапки ТЗ / artifacts / GATES / HANDOFF / SESSION / RULES_INDEX / index

## 2026-09-17 — docs: #71 Патч_1 CI green after REVIEW

- CI green `35230879863` · review sha `844a618a`
- Fly MCP Point A после deploy апрув

## 2026-09-17 — review: #71 Патч_1 server email + security fix

- GREEN `55c34592` · review fix `72d90862`: profile-first txn; `email_verified=false` на post-pay; linker не switch на unverified squat
- bugbot high/medium + security medium закрыты
- Entire `01M2QSJ5WY9Q3A3MC6028SZBBV` на GREEN · Local PASS · push/CI
- Fly MCP Point A после deploy апрув

## 2026-09-17 — regress: #71 Патч_1 server email PASS

- Local: `orders_email_test` 13/0 · `email_collection_test` 21/0
- GREEN `55c34592` · Entire `01M2QSJ5WY9Q3A3MC6028SZBBV` · Next: `/review`
- Fly MCP Point A после Review/deploy (hot-path витрина)

## 2026-09-17 — docs: /patch #71 Патч_1 server email prefill

- Секция **Патч_1** в TASK Email-сбор (#71): расхождение OrderEmail-only vs MobileCustomer.email
- `todo.md` Шаг 5 под итерацию: SBR/Файлы/Не ломать/Проверка/DoD
- Google: `1igng5OvrPOKMs5NkAZ8CAQYSufJBk3i3ZTI3bTgFLY8` · Next: `/sbr`

## 2026-09-17 — docs: #94 CI green after REVIEW

- CI green `35198770223` · review sha `97f4291b`
- G5 Fly MCP после deploy апрув

## 2026-09-17 — review: #94 TASK_92 background FCM + chat CTA

- GREEN `f274c11c`: FCM data-only + OrderStatus `openSupportChat`
- bugbot high → fix `5da31ad0`: cold-start hash boot + openWindow postMessage
- security: no medium+
- Entire: `01M2Q5JKXMAXYVGWY68BZT431F` · Local PASS · push/CI
- G5 Fly MCP после deploy

## 2026-09-17 — docs: unlazy reverify #94 G1–G4 met pre-review

- `GATES.md` G1 includes `fcm_client_test`; `--approve` + `--reverify` G1–G4 PASS
- G5 Fly MCP Point A still unmet (post-deploy)
- Next: `/review`

## 2026-09-17 — docs: #94 zone regress PASS

- `rails test fcm_client+notifier+payload` — 15 runs, 0 fail
- `node --test support_chat + push_subscribe` — 22 pass
- `push_pipeline_simulation` — 2 runs, 0 fail
- Next: `/review` · Fly MCP G5 после deploy

## 2026-09-17 — docs: update COMPONENT_MAP — PaymentResult / Checkout / CartSheet / OrderStatusSheet

- БЛОК 4 #93: новая строка PaymentResult; точечно Checkout · CartSheet · cartSheetStore · OrderStatusSheet · orderStatusSheet.js
- Граница: `maybeAutoReturnToCatalog` / `isCartSheetRoute` без `/payment-result` · без правки статуса internals

## 2026-09-17 — docs: #93 CI green after REVIEW

- CI green `35196766203` · review sha `45f459ea`
- G4 Fly MCP после deploy апрув

## 2026-09-17 — feat: #94 FCM data-only + chat CTA [GREEN]

- FcmClient: data-only (title/body in data) → SW owns shade tag/actions
- OrderStatus chat → `openSupportChat`; application.js `coffeeos_navigate`; SW `data.title`
- RED `20c05ba6` · GREEN `f274c11c` · Next: `/regress`

## 2026-09-17 — review: #93 TASK_91 post-pay auto return catalog

- GREEN `118e5488`: `maybeAutoReturnToCatalog` when `!askReceiptEmail`
- bugbot: no bugs · security: no medium+
- Entire: `01M2Q4KBV30SBFMRTNDVP99HKM` (attach) · Local zone PASS · push/CI
- G4 Fly MCP после deploy · COMPONENT_MAP: не трогали (не новая сущность карты)

## 2026-09-17 — docs: unlazy reverify #93 pre-review (G1–G3 met)

- Ledger: `artifacts/post_pay_auto_return_catalog_status/GATES.md` (session GATES = #94)
- `gate-check --reverify` G1–G3 PASS; G4 Fly MCP Point A still unmet (post-deploy)
- Next: `/review`

## 2026-09-17 — docs: SPEC #94 TASK_92 background FCM + chat CTA

- Gap: `FcmClient` notification+data → SW не владеет shade; OrderStatus chat → dead `orderDeepLink`
- todo: 6 файлов · Не ломать · Проверка · Next: `/sbr`

## 2026-09-17 — docs: #93 zone regress PASS

- `node --test email_collection_test.mjs` — 19 pass
- `rails test order_status_acceptance + sheet_mount` — 15 runs, 0 fail
- Next: `/review` · Fly MCP G4 после deploy

## 2026-09-17 — docs: unlazy GATES #94 TASK_92 background FCM

- `GATES.md` → #94 baseline; gate-check `--approve` G1–G4 PASS; G5 Fly MCP pending
- Зона: notifier/payload · support_chat · push_subscribe · push_pipeline
- Next: `/spec`

## 2026-09-17 — docs: intake #94 TASK_92 production background FCM

- Чат заказчика + Google Doc MCP → `customer_tasks/TASK-92-…md` (1:1)
- artifacts `production_background_fcm_status_sync/`; CBR #94 (CBR #92 = WebPush recovery)
- Gaps: п.1 фоновые FCM; чат CTA показывается, клик нет · Next: `go` → `/spec`

## 2026-09-17 — docs: SPEC #93 TASK_91 post-pay auto return catalog

- Gap: success без email-блока (`!askReceiptEmail`) — только «В каталог»; submit/Skip уже `push("/")`
- todo: 3 файла · Не ломать · Проверка · Next: `/sbr`

## 2026-09-17 — docs: unlazy GATES #93 + customer screenshots

- screenshots `01`–`03` → `artifacts/post_pay_auto_return_catalog_status/screenshots/`
- `GATES.md` → #93 baseline; `gate-check --approve` G1–G3 PASS; G4 Fly MCP pending
- todo: ссылка GATES · Next: `/spec`

## 2026-09-17 — docs: intake #93 TASK_91 post-pay auto return catalog

- Чат п.9.2 + скрины + Google Doc → `customer_tasks/TASK-91-…md` (1:1)
- artifacts `post_pay_auto_return_catalog_status/` (подписи скринов; PNG с диска не найдены)
- Google TASK_91 → CBR #93 (#91 занят UI-EXT); todo → #93 · Next: `/spec`

## 2026-09-17 — docs: update COMPONENT_MAP — ActiveOrdersAccordion / orderStatusNotifyActions / firebasePush

- БЛОК 4 #92: точечно ActiveOrdersAccordion · orderStatusNotifyActions; новая строка firebasePush
- Граница: recovery UI / openNotificationSettings · без #83/#84 · без register token

## 2026-09-17 — review: #92 TASK_90 WebPush recovery after denied

- GREEN `0b7f0b2d`: recovery UI + fallback + dismissPushRecovery
- bugbot medium → fix `72dcb5e9`: Android intent always shows fallback
- security: no medium+
- Entire: `01M2Q1AF4E2PWDD5JW1FZPRPF1` на GREEN+fix
- Local zone PASS · CI green `35191890272` · G5 Fly MCP после deploy
- COMPONENT_MAP: не трогали (не новая сущность карты)

## 2026-09-17 — docs: unlazy reverify #92 pre-review (G1–G4 met)

- `gate-check --reverify` G1–G4 PASS; G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-17 — docs: #92 zone regress PASS (WebPush denied recovery)

- node: push_subscribe + notify + accordion — 52 pass
- rails: order_status acceptance + sheet_mount — 15 runs / 139 assert / 0 fail
- unlazy `--reverify` G1–G4 PASS · G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-17 — docs: SPEC #92 TASK_90 WebPush recovery after denied

- todo: recovery UI + deep-link/fallback `denied → settings`
- Файлы: orderStatusNotifyActions + ActiveOrdersAccordion + firebasePush(?) + 2 теста
- Не ломать: оплата · #83/#84 · Wallet/OrderStatus · backend push/SW

## 2026-09-17 — docs: unlazy GATES #92 WebPush recovery after denied

- Ledger `session/GATES.md` · baseline pre-SPEC
- G1–G4 PASS (push subscribe · notify actions · accordion · order_status rails)
- G5 Fly MCP Point A unmet (после REVIEW/deploy)
- todo → #92 · Next: `/spec`

## 2026-09-17 — docs: intake #92 TASK_90 WebPush recovery after denied

- Чат п.9/9.1 + Google Doc → `customer_tasks/TASK-90-…md` (1:1)
- artifacts `webpush_recovery_after_denied/` · CBR #92 · ISSUES · todo
- Google TASK_90 → CBR #92 (#90 занят POSTCALL); EXT #81 denied→settings
- Next: `/spec`

## 2026-09-17 — docs: update COMPONENT_MAP — PhoneAuth / Checkout / PaymentMethodsSheet

- БЛОК 4 #90: новые строки PhoneAuthWizard · PhoneAuthCodeStep · phoneAuthCascade · Checkout · PaymentMethodsSheet
- Граница: resume без re-init · авто-open pay sheet из Checkout

## 2026-09-16 — fix: CI flake Rails.env pollution (payment_config_test)

- `define_method(:env)` ломал stub production в callbacks test → 200 вместо 401
- CI green `35119243465` после `db6cba85`

## 2026-09-16 — review: #90 POSTCALL-EXT return after Callcheck

- GREEN `37b808c4`: resume poll + copy «вернитесь» + pagehide/iOS + checking UI
- bugbot: no bugs · security: no medium+
- Entire: `01M2NCXMN67QF5CB228K6HCT97` на GREEN
- Local zone PASS · CI green `35116445356` · G5 Fly MCP после deploy
- COMPONENT_MAP: не трогали (не новая сущность карты)

## 2026-09-16 — docs: unlazy reverify #90 pre-review (G1–G4 met)

- `gate-check --reverify` G1–G4 PASS; G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-16 — docs: #90 zone regress PASS (shop auth / Callcheck return)

- rails: auth_funnel + silent_refresh + phone_otp + linker — 27 runs / 211 assert / 0 fail
- node: wizard + cascade + otp_ui — 27 pass
- unlazy `--reverify` G1–G4 PASS · G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-16 — docs: SPEC #90 POSTCALL-EXT restart

- todo: lifecycle return Callcheck → resume → PaymentMethodsSheet
- Файлы: phoneAuthCascade + PhoneAuthCodeStep + Wizard + 3 теста
- Не ломать: #89 linker/session · #91 UI-EXT · FlashCall · CartSheet

## 2026-09-16 — docs: unlazy GATES #90 POSTCALL-EXT restart

- Ledger `session/GATES.md` · restart после rollback
- G1–G4 PASS (cascade/wizard · structural+auth funnel · phone_otp/linker · otp_ui)
- G5 Fly MCP Point A unmet (после REVIEW/deploy)
- todo → #90 · Next: `/spec`

## 2026-09-16 — docs: RU title чатов (agent-workflow)

- Старт чата п.5: `rename_chat` → `Задача N — кратко` (≤60)
- Без нового always-файла — только строка в уже loaded workflow + index/RULES_INDEX

## 2026-09-16 — review: #91 TASK_89-UI-EXT phone input UI/UX

- GREEN `8c267e56`: slim sheet 8vh · hide CTA+cart на phone-auth
- bugbot: no bugs · security: no medium+
- Entire: `01M2N8XBEJ7JRD7T89JT4DAHS8` на GREEN
- Local zone PASS · CI green `35108357982` · G5 Fly MCP после deploy
- COMPONENT_MAP: не трогали (не новая сущность карты)

## 2026-09-16 — docs: unlazy reverify #91 pre-review (G1–G4 met)

- `gate-check --reverify` G1–G4 PASS; G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-16 — docs: #91 zone regress PASS (phone-auth UI / cart sheet)

- node: webview + wizard + otp_ui + cascade — 39 pass
- rails: cart_sheet_ux + auth_funnel + checkout_ui_cleanup — 13 runs / 247 assert / 0 fail
- unlazy `--reverify` G1–G4 PASS · G5 Fly MCP Point A still unmet (post-deploy)
- Hot-path Fly MCP Point A (G5) — ещё нужен после deploy

## 2026-09-16 — docs: SPEC #91 TASK_89-UI-EXT phone input UI/UX

- todo: phone-auth → скрыть CTA+cart · thinner sheet
- Файлы: Checkout · cartSheetStore · shopWebViewLayout · cartSheetThresholds · CartSheet (+2 теста)
- Не ломать: #89 · CTA вне auth · keyboard path · #90

## 2026-09-16 — docs: unlazy GATES #91 UI-EXT baseline

- Ledger `session/GATES.md` · G1–G4 PASS (phone auth UI / cart sheet / auth funnel / cascade)
- G5 Fly MCP Point A unmet (после REVIEW/deploy)
- RED ещё добавит CTA/cart hide asserts

## 2026-09-16 — docs: intake #91 TASK_89-UI-EXT phone input UI/UX

- Чат + Google Doc → `customer_tasks/TASK-89-UI-EXT-…md` (1:1)
- artifacts `pwa_auth_phone_input_ui_ux/` · CBR #91 · README · ISSUES · todo
- Scope: phone-auth скрыть CTA суммы + cart preview · тоньше sheet; ждёт `/spec`

## 2026-09-16 — revert: #90 POSTCALL-EXT full rollback (wrong order)

- Код снят: `PhoneAuthCodeStep` / `phoneAuthCascade` / тесты #90 → pre-RED
- Причина: POSTCALL раньше UI-EXT · сломали очерёдность · два чата на одну задачу
- ТЗ/intake #90 сохранены · статус ROLLED BACK · заново после UI-EXT
- #89 не трогали · скрин шторки в #89 artifacts остаётся

## 2026-09-16 — review: #90 POSTCALL-EXT return after Callcheck

- GREEN `4932e2b0` + fix iOS tel resume `0588ead1` (pagehide / markLeftForDial / focus)
- bugbot: high iOS skip → fixed · security: no medium+
- Entire: `01M2N01DRZ1TPY8WCNKRE80R5V` на GREEN/fix
- Local zone PASS · CI green `35094780266` · G5 Fly MCP после deploy
- COMPONENT_MAP: не трогали (не главная зона карты)

## 2026-09-16 — docs: #89 artifact — curtain sum keyboard screenshot

- `pwa_auth_registration_callcheck_sms/screenshots/01_phone_input_curtain_sum_keyboard_2026-09-16.png`
- заказчик: толщина шторки / видимость суммы (TASK_89-UI-EXT; OUT #90)

## 2026-09-16 — docs: unlazy reverify #90 pre-review (G1–G4 met)

- `gate-check --reverify` G1–G4 PASS; G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-16 — docs: #90 zone regress PASS (shop auth / Callcheck return)

- rails: auth_funnel + silent_refresh + phone_otp + linker — 26 runs / 0 fail
- node: wizard + cascade + otp_ui — 27 pass
- unlazy `--reverify` G1–G4 PASS · G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-16 — docs: SPEC #90 POSTCALL-EXT

- todo: lifecycle return Callcheck → resume → PaymentMethodsSheet
- Файлы: phoneAuthCascade + PhoneAuthCodeStep + Wizard + 3 теста
- Не ломать: #89 linker/session · UI-EXT · FlashCall · CartSheet

## 2026-09-16 — docs: unlazy GATES #90 POSTCALL-EXT

- Ledger `session/GATES.md` · approve G1–G4 PASS (baseline #89 zone)
- G5 Fly MCP Point A unmet (после REVIEW/deploy)
- RED ещё добавит lifecycle asserts (return ≠ init_callcheck)

## 2026-09-16 — docs: intake #90 TASK_89-POSTCALL-EXT

- Google Doc → `customer_tasks/TASK-89-POSTCALL-EXT-…md` (1:1)
- artifacts `pwa_callcheck_return_continue_payment/` · CBR #90 · README · ISSUES
- EXT #89: return после Callcheck → resume → PaymentMethodsSheet; ждёт `/spec`

## 2026-09-16 — review: #89 post-Callcheck → payment sheet

- GREEN `84490e04`: `onWizardVerified` → `openPaymentSheet` после Callcheck/SMS
- bugbot: no bugs · security: no medium+ (#89 Checkout scope)
- Entire: `01M2MSDK9ZMPZH7YDZ17GHM44B` на `84490e04`
- Local zone PASS · CI green `35082473762` · G5 Fly MCP после deploy
- COMPONENT_MAP: не трогали (не главная зона карты)

## 2026-09-16 — docs: unlazy reverify #89 pre-review (G1–G4 met)

- `gate-check --reverify` G1–G4 PASS; G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-16 — docs: #89 zone regress PASS (shop auth / OTP)

- rails: phone_otp + linker + silent_refresh + auth_funnel — 33 runs / 0 fail
- node: phone_auth wizard/cascade/ui — 23 pass
- Hot-path Fly MCP Point A (G5) — ещё нужен после deploy

## 2026-09-16 — docs: SPEC #89 post-Callcheck → payment sheet

- `todo.md` #89: `onWizardVerified` → `openPaymentSheet`; файлы Checkout + structural/OTP tests
- OUT: FlashCall, толщина шторки, каскад×2 #80

## 2026-09-16 — docs: unlazy GATES #89 PWA auth Callcheck → SMS

- `session/GATES.md` → #89 (G1–G4 baseline PASS, G5 Fly MCP pending)
- Scope: Callcheck/SMS → session → checkout + экран оплаты; FlashCall guard

## 2026-09-16 — docs: intake customer task #89 PWA auth Callcheck → SMS

- `TASK-89-Авторизация-регистрация-PWA-Callcheck-SMS.md` + artifacts `pwa_auth_registration_callcheck_sms/`
- CBR / customer_tasks README / ISSUES #89
- Чат: post-call → PWA + экран оплаты; overlap #80

## 2026-09-16 — fix: security backlog (Tbank Amount, promo used_count, token, callbacks throttle)

- T-Bank: `TbankAdapter.notification_amount_matches?` (копейки) + guard в `TbankCallbackJob` на CONFIRMED/succeeded
- Barista: `increment_usage!` в транзакции заказа при `discount_amount > 0`; max_uses держится
- `EventsController`: `X-Callback-Token` через `secure_compare` (+ длина)
- Rack::Attack: throttle POST `/callbacks/*` по IP (MemoryStore; shared — follow-up)
- Local: tbank job/adapter + barista promo + events + tbank controller **76/76 PASS**

## 2026-09-16 — fix: barista promo UI + DEMO_AUTO_SEED off + push

- Barista POS: убрана фейковая клиентская −10%; скидка только через `PromoCode` на сервере
- `fly.toml`: `DEMO_AUTO_SEED=false` (публичный fly.dev больше не пересидит `demo123456` на каждый deploy)
- Push `develop` — Grok/remote видят `488551aa` + этот коммит
- Deploy: апрув · до выката проверить `CALLBACK_SHARED_*` на Fly

## 2026-09-16 — fix: security P0/P1 (Grok review — callbacks, cart modifiers, staff login)

- P0: `Callbacks::EventsController` — в **production** без `CALLBACK_SHARED_TOKEN` + `CALLBACK_SHARED_SECRET` → **401** (как email bounce)
- P1: shop cart/modifiers — только **id** из БД, клиентский `price` без id отклоняется
- P1: `Auth::SessionsController#create` — `reset_session` до заполнения сессии (session fixation)
- Deploy: на Fly секреты callbacks должны быть заданы **до** выката, иначе легитимные колбэки упадут
- Local: events_controller + auth sessions + cart/modifier + callbacks_e2e **71/71 PASS**

## 2026-09-16 — fix: security catch-up OTP unlock / widget step-up / API key fallback

- HIGH: `binding_step_up` unlock only if lock existed **before** `link!` (no same-request bypass)
- MEDIUM: `widget_init` enforces `BindingStepUp` like `one_click`
- MEDIUM ops: `SHOP_API_KEY_FALLBACK` **opt-in** (`=1`); default off after per-tenant seed
- also: `BindingStepUp` lock on empty Hash session (`nil?` not `blank?`)
- Local: binding_step_up + api_key_authenticator + phone_otp + widget_init **32/32 PASS**

## 2026-09-15 — fix: Sentry RUBY-1K category sort_order NotNull

- `Platform::MenuController#update_category`: `normalized_category_attrs` — blank keep / 0 append
- test `menu_category_sort_order_update_test` · Fixes RUBY-1K

## 2026-09-15 — feat: #87 REVIEW — Quick Repeat clear cart after pay (push)

- Local PASS · manual bugbot+security (Task usage limit) · no blocker
- Entire `01M2JVMYKV47VGQ1SCRBC5V77R` на `06dca7c3`
- **CI green** run `34991136715`
- clear only on `confirmed` · DELETE `/cart` session · receipt = Order interactive:false
- Fly MCP G4 / deploy — только апрув

## 2026-09-15 — test: #87 regress PASS (Quick Repeat status zone)

- node: 33 pass (`create_repeat` + `order_status_sheet` + `clear_cart_after_pay`)
- rails: 18 runs / 0 fail (one-click + cart/status stack + active_orders + receipt)
- next: `/review` · Fly MCP Point A ещё нужен для заказчика

## 2026-09-15 — feat: #87 clear cart after Quick Repeat pay [GREEN]

- `clearCartAfterSuccessfulPay` + wire в `widgetRepeatPayFlow` на `confirmed`
- 7.1: leftover cart не висит под status; receipt = Order (`interactive: false`)
- G1–G3 met · Entire `01M2JVMYKV47VGQ1SCRBC5V77R` на `06dca7c3` · next `/regress`

## 2026-09-15 — docs: #87 SPEC — Quick Repeat status composition

- `todo.md`: SBR · 6 путей · blast-radius · Не ломать · Проверка (node + rails zone)
- Фокус 7.1: post card autopay — status без интерактивной корзины; состав из Order
- stop до `/sbr` RED

## 2026-09-15 — docs: #87 unlazy GATES ledger (baseline)

- `session/GATES.md`: G1 node unit · G2 active_orders/receipt · G3 quick_repeat+cart stack — **met**; G4 Fly MCP — pending
- Baseline до `/spec` / RED; после GREEN — `--reverify`; G4 на Review

## 2026-09-15 — docs: intake #87 Quick Repeat status composition

- `TASK-87-Quick-Repeat-status-model-composition.md` — Google Doc Spec 1:1 + правка 7.1 (cart block after card autopay)
- artifacts `quick_repeat_status_model_composition/` · скрин `01_status_after_card_autopay_cart_block.png`
- CBR #87 · ISSUES · stop до `/spec`

## 2026-09-15 — feat: #86 REVIEW — SBP PWA recovery (push)

- GREEN `recoverPendingPayment` + pageshow; regress PASS; Entire `01M2JSNRNQCYGRZ6BCSXFTSG4A`
- Task bugbot/security: usage limit → manual review #86 (no blocker)
- **CI green** run `34987062132` · device Android/iOS + Fly MCP Point A — после deploy апрува

## 2026-09-15 — test: #86 regress PASS (SBP PWA recovery zone)

- node: 37 pass (`codeblack_pending_order` + `shop_sbp_pay`)
- rails: 10 runs / 0 fail (`sbp_payment_return_ui` + `sbp_payment_ui`)
- next: `/review` · Fly MCP Point A ещё нужен для заказчика

## 2026-09-15 — docs: #86 unlazy GATES ledger (baseline)

- `session/GATES.md`: G1 node unit · G2 rails SBP UI — **met**; G3 Fly MCP · G4/G5 device — pending
- Baseline до RED; после GREEN — `--reverify`; G3–G5 на Review/device

## 2026-09-15 — docs: #86 SPEC — SBP PWA recovery after bank

- `todo.md`: SBR фазы · 7 путей · Не ломать · Проверка (node + rails SBP return UI)
- OUT: #79 надписи/11·8 · SMS → каскад
- stop до `/sbr` RED

## 2026-09-15 — docs: intake #86 SBP PWA recovery after bank (EXT)

- `TASK-86-Восстановление PWA после оплаты СБП-EXT.md` — правки заказчика 1:1 + Spec из Google Doc
- artifacts `sbp_pwa_recovery_after_bank_ext/` · CBR/README/ISSUES · #79 split (recovery → #86; SMS → каскад OUT)
- todo stub · stop до `/spec`

## 2026-09-15 — docs: #26 Патч 1 — Subtask 5 HTTP 422 + error_code

- Секция **Патч 1** в ТЗ invalid-token BottomSheet: бизнес-ошибка T-Bank = `422` + `error_code` (не `400`)
- `todo.md` под итерацию патча; код/FSM/UI не трогали
- Тексты по `error_code` → отдельно TASK_85

## 2026-09-14 — docs: COMPONENT_MAP — Связи orderStatusSheet.js

- «Связи»: OrderStatusSheet, CartSheet (не метаданные задачи)
- владение #84 остаётся в «Не трогать без пометки»

## 2026-09-14 — chore: /patch thin layer (task patch / EXT)

- Канон `docs/operations/dev/TASK_PATCH.md`
- On-demand `coffeeos-task-patch.mdc` · команда `/patch`
- Индексы: coffeeos-index · RULES_INDEX · commands/README · agent-workflow
- COMPONENT_MAP БЛОК 4 → ссылка на TASK_PATCH § шаг 6

## 2026-09-14 — docs: COMPONENT_MAP — Назначение orderStatusSheet.js

- «Назначение»: описание файла (peek/hidden/dismiss/poll/cable), не имя задачи #83

## 2026-09-14 — docs: fix COMPONENT_MAP БЛОК 4 (фидбек)

- ActiveOrdersAccordion: вернули Файл/Назначение; «Не трогать» = #83 + #84
- activeOrdersAccordion.js / orderStatusNotifyActions.js: закрыли «дыры» фактом #84
- orderStatusSheet.js: без изменений (#83 уже в PR)
- «Известные дыры»: убраны чек и крестик; оставлен факт ActiveOrdersPresenter

## 2026-09-14 — chore: install unlazy Solo overlay (CoffeeOS)

- Vendor: `npx skills add Leonxlnx/unlazy` → `.agents/skills/unlazy/` · pin `skills-lock.json`
- Thin `/unlazy` skill+command · on-demand `coffeeos-unlazy.mdc` · template + smoke
- Smoke G1 **ALL MET** (`gate-check --approve` / `--reverify`)
- Без Stop-hook / Depth Tree по умолчанию (токены)

## 2026-09-13 — docs: update COMPONENT_MAP — ActiveOrdersAccordion

- БЛОК 4 #84: владение чек/CTA; общий файл с dismiss; `aoa__dismiss` не трогать

## 2026-09-13 — feat: TASK_84 status sheet receipt restore [REVIEW]

- Restore `receiptView` + CTA «Состав заказа» (`openOrderReceipt`) в `ActiveOrdersAccordion`
- Reverse QA no-receipt; dismiss / `orderStatusSheet` не трогали
- TDD RED→GREEN · regress **58/58 PASS**
- Entire `01M2D8PZAPT8XDC2KY95GFCFVN` на GREEN `a695ff08`
- bugbot/security: **usage blocked** · push · **CI green** `34755030736`

## 2026-09-13 — test: TASK_84 status sheet receipt restore [regress]

- Зона: PWA status sheet / ActiveOrdersAccordion
- `node --test` accordion **21/21** + notify/sheet **37/37** · **58/58 PASS**
- Ждёт `/review` · Fly MCP Point A после deploy

## 2026-09-13 — docs: SPEC TASK_84 status sheet receipt restore

- `todo.md` → #84 · 3 пути + use-only `activeOrdersAccordion.js`
- Не ломать: dismiss #83 · `orderStatusSheet` · pay-path · `receiptView` impl
- Проверка: `node --test` accordion + notify/sheet regress
- Ждёт `/sbr`

## 2026-09-13 — docs: intake TASK_84 status sheet receipt restore

- ТЗ 1:1: `customer_tasks/TASK-84-status-sheet-receipt-restore.md` (Google Doc)
- CBR #84 + `customer_tasks/README` · artifacts `status_sheet_receipt_restore/`
- Scope: вернуть чек + CTA «Состав заказа»; OUT dismiss / `orderStatusSheet`
- Ждёт `/spec`

## 2026-09-13 — feat: TASK_83 status sheet dismiss contract [REVIEW]

- `DISMISS_CONTRACT` в `orderStatusSheet.js` (local ×; Cable keep; no reload persist)
- TDD: `#83` suite + `aoa__dismiss` assert · regress **37/37 PASS**
- Entire `01M2D37YG7XPHV6CV978P0MXBN` на GREEN `a2f323b0`
- bugbot/security: **usage blocked** · push · **CI green** `34751138556`
- lint follow-up: rubocop Layout в `bin/acceptance/v3_sec_post_deploy_mcp.rb` (`366730dc`)
- COMPONENT_MAP БЛОК 4 — после принятия владельцем

## 2026-09-13 — docs: SPEC TASK_83 status sheet dismiss

- `session/todo.md` → TASK_83 (SBR, файлы, Не ломать, Проверка)
- Gate до RED: продуктовые решения Cable-update + reload (ТЗ §6)
- Scope: `ActiveOrdersAccordion` dismiss + `orderStatusSheet.dismissOrder` only

## 2026-09-13 — docs: intake TASK_83 status sheet dismiss

- Google Doc → `customer_tasks/TASK-83-status-sheet-dismiss.md` (1:1)
- Artifacts: `artifacts/status_sheet_dismiss_behavior/`
- CBR #83 + `customer_tasks/README.md`
- Scope: local dismiss × в статусной шторке; Cable/reload — ждут продуктовые решения до RED

## 2026-09-12 — docs: COMPONENT_MAP shop active orders + token guards

- Добавлен `docs/operations/session/COMPONENT_MAP.md` (bootstrap из аудита зоны)
- On-demand: не читать на `/start`; `/review` — БЛОК 4 только если задача главная для зоны
- Intake: новые ТЗ → `customer_tasks/TASK-*.md`; прогресс → один `todo.md`
- Правки: `agent-workflow`, `coffeeos-index`, `RULES_INDEX`, `start`/`review`, `repo-layout`, `customer-intake`, `ENTIRE`, `session/README`

## 2026-09-09 — feat: UK onboarding auto shop API key (FALLBACK still ON)

- `Provision` выдаёт tenant key для sales_point (1×); flash RAW на show; kitchen — skip
- Local: provision + tenants controller **14/88 PASS**
- Fly **v495**: create `mcp-key-b7845686` → prefix `sk_27213` → API 200/401 → delete · Point A OK
- Артефакт: `artifacts/v3_sec_shop_api_keys_onboarding/mcp/fly_v495_2026-09-09/`

## 2026-09-09 — seed: V3-SEC-SHOP-API-KEYS per-tenant (FALLBACK still ON)

- Issued **17** `sales_point` keys (`seed-2026-09-09`) on Fly v494
- Smoke **8/8 PASS** (A↔B isolation, query dead, ENV fallback still works)
- **`SHOP_API_KEY_FALLBACK` не выключали** — по решению владельца
- RAW gitignored: `config/secrets/shop_api_keys_fly_seed_2026-09-09.json`
- Артефакт: `artifacts/v3_sec_shop_api_keys_seed/mcp/fly_v494_2026-09-09/`

## 2026-09-09 — deploy+MCP: V3-SEC OTP-MERGE / SHOP-API-KEYS / JOB-TENANT

- CI green pre-deploy · Fly **v494** `deployment-01M22FTYBTSHA8HESDV06GPMR2`
- MCP Point A **PASS**: SHOP-API-KEYS 7/7 · OTP-MERGE 6/6 · JOB-TENANT worker+evidence 3/3
- Live charge / pay→ready A–D **не** гоняли (нет апрува) · disposable Point A API key issued+revoked
- Артефакт: `milestones/veha_2/artifacts/v3_sec_triple_mcp/mcp/fly_v494_2026-09-09/` · runner `bin/acceptance/v3_sec_post_deploy_mcp.rb`

## 2026-09-09 — ops: refund Point A MIR *5953 (витрина)

- T-Bank `/v2/Cancel` via `Payments::TbankOrderRefund`: `#202609-0031` + `#0032` (10₽×2) → bank `REFUNDED`
- Уже refunded ранее: `#0022`–`#0023`, `#0025`, `#0027`–`#0030`; failed/pending не трогали
- Артефакт: `milestones/veha_2/artifacts/ops_refunds_2026-09-09/`

## 2026-09-09 — REVIEW CI green: V3-SEC-OTP-MERGE

- CI [34321450447](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34321450447) tip `084be2ba` · code tip `a98e978a` already green
- Entire `01M22D5GHQKN7FEQE7Y87CCN3T` · bugbot/security usage blocked
- Next: deploy / Fly MCP Point A — апрув
## 2026-09-09 — REVIEW: V3-SEC-OTP-MERGE

- Local zone+IDOR **22/102 PASS** · CI green [34320783026](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34320783026) tip `a98e978a`
- Entire `01M22D5GHQKN7FEQE7Y87CCN3T` на GREEN `a7839074` · bugbot/security **usage blocked**
- Next: deploy / Fly MCP Point A — апрув
## 2026-09-09 — regress: V3-SEC-OTP-MERGE PASS

- linker/merger/BindingStepUp: **11/47** · ownership_idor: **11/55**
- Next: `/review` · Fly MCP Point A после deploy (апрув)
## 2026-09-09 — REVIEW CI green: V3-SEC-JOB-TENANT-GUC

- CI [34319445414](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34319445414) · tip after removing stray OTP `[RED]` from develop
- Entire `01M22D5GHQKN7FEQE7Y87CCN3T` · bugbot/security usage blocked
- Next: Fly queue network / deploy — апрув
## 2026-09-09 — REVIEW: V3-SEC-JOB-TENANT-GUC

- Local regress **28/86 PASS** · GREEN `8f9f5aa2`
- Entire `01M22D5GHQKN7FEQE7Y87CCN3T` · bugbot/security **blocked by usage** (как shop API)
- Push develop → CI · Fly queue network / deploy — апрув
## 2026-09-09 — regress: V3-SEC-JOB-TENANT-GUC PASS

- helper + broadcast/ready/cascade/receipt jobs: **28/86** · 0 fail
- GREEN `8f9f5aa2` · Next: `/review`
## 2026-09-09 — REVIEW CI green: V3-SEC-SHOP-API-KEYS

- CI [34318508943](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34318508943) · tip `442e7920` (Zeitwerk ApiKeys + Brakeman GUC)
- Entire `01M22C4CV16HA4XDFZ4T4ZGQ23` · bugbot/security usage blocked
- Next: deploy/secrets — апрув · Fly MCP Point A
## 2026-09-09 — GREEN: V3-SEC-JOB-TENANT-GUC (Solid Queue job tenant GUC)

- `Rls::JobTenantContext` + wrap order-scoped jobs · audit FIXED + ops абзац
- Local helper+jobs **28/28** · commit `8f9f5aa2` · Next: `/regress`
## 2026-09-09 — REVIEW: V3-SEC-SHOP-API-KEYS

- Local regress **30/76 PASS** · GREEN `8f9cd956`
- Entire `01M22C4CV16HA4XDFZ4T4ZGQ23` · bugbot/security **blocked by usage** (как UserCards)
- Push develop → CI · deploy/secrets — апрув · затем Fly MCP Point A
## 2026-09-09 — regress: V3-SEC-SHOP-API-KEYS PASS

- rails auth+resolver+ownership_idor: **30/76** · 0 fail
- GREEN `8f9cd956` · Next: `/review` · Fly MCP после deploy (апрув)
## 2026-09-09 — SPEC: V3-SEC-JOB-TENANT-GUC (Solid Queue jobs → tenant GUC)

- todo: срез A — `Rls::JobTenantContext` · wrap order-scoped jobs · audit FIXED + ops абзац
- Parked: OTP-MERGE · SHOP-API-KEYS WIP · Next: `/sbr` RED
## 2026-09-09 — SPEC: V3-SEC-OTP-MERGE (OTP switch + card step-up)

- todo: MVP срез A — linker switch (не absorb карт) · BindingStepUp gate · audit log
- Parked: `V3-SEC-SHOP-API-KEYS` GREEN WIP · Next: `/sbr` RED
## 2026-09-09 — SPEC: V3-SEC-SHOP-API-KEYS (tenant-scoped shop API keys)

- todo: header-only `X-Shop-Api-Key` · digest per-tenant · rotation · ENV fallback bootstrap
- Next: `/sbr` RED · deploy/secrets — апрув
## 2026-09-08 — Ops: отмена/возврат заказов Point A (жалоба Aram)

- Card: `#202609-0022` / `#202609-0023` уже `refunded` (pid 9205922796 / 9205941727)
- Pending без charge → cancelled/failed; SBP pending `9205846937` void в Т-Банке
- Live pay дальше — только по явному апруву
## 2026-09-08 — regress: UserCards/#26 zone PASS

- rails payments/user_cards/one_click: **20/84** · node repeat_invalid_token: **23/0**
- Fly MCP v493 already PASS · код не меняли (verify-only)
- Next: `/review`
## 2026-09-08 — UserCards / RebillId + #26 M2 MCP PASS (v493)

- Verify-first: P/U/O/M **PASS** · Slice C **n/a** (код не меняли)
- Guest Aram · MIR `*5953`/`*8782` RebillId · one_click → чек · M2 invalid token → inline «Сбой банка: позже»
- Артефакт: `repeat_order_invalid_token_payment_sheet/mcp/fly_v493_2026-09-08/`
- ISSUES UserCards/#26 → 🟢

## 2026-09-08 — SBP Slice O PASS (v493): init ≠ 3001

- Live Point A: `POST sbp/init` + `save_sbp_account` → **200** → `qr.nspk.ru`
- order `b87b63ea-1599-4455-8067-c24428d011f6` · 179₽ · код не меняли
- Артефакт: `tbank_sbp_autopayments_account_token/mcp/fly_v493_2026-09-08/`
- Next: Slice B (bind в банке) · Z SKIP · C n/a
## 2026-09-08 — #80 Slice V sync «звоню»: confirmed не пришёл

- Callcheck UI + poll 200 OK · `confirmed:false` до timeout → SMS.ru 204
- Leave wizard не проверяли; код не трогали
- Артефакт MCP_RESULT обновлён (`fly_v492_2026-09-08`)

## 2026-09-08 — #80 Slice V live Callcheck: V1 PASS · V2/V3 not verified

- Phone live ×2: `init_callcheck` + «Ждем звонок» + `tel:8-800…` PASS
- Нет `confirmed` до auto SMS (~40с); leave wizard не проверяли
- SMS fallback → SMS.ru **204** (оператор/отправитель) — ops, не leave-wizard F
- Артефакт: `registration_callcheck_cascade_ui_ux/mcp/fly_v492_2026-09-08/`

## 2026-09-08 — Follow-up Fly v493: B6 + Wallet simulate + plan seed

- `WALLET_SIMULATE=1` · wallet stub `PKPASS_STUB` **PASS**
- Seed `SubscriptionPlan` `pilot_weekly` · Charge **SKIP** (T-Bank ErrorCode **223** на старых Rebill)
- Fix B6: menu `style`/`script` → внутрь `content_for` (layout barista без yield)
- MCP: B2.2 **PASS** · #38 simulate **PASS** · #78 PARTIAL

## 2026-09-08 — SPEC: UserCards / RebillId + #26 M2 (verify-first)

- `todo.md`: slices **P→U→O→M**, **C** только при FAIL нашего слоя
- Hot-path: Не ломать (webhook / save_card=false / card hash / session cards) · Проверка rails+node зоны
- Канон: UserCards ТЗ · #26 · MCP_PLAN_STEP5 · Point A
- Next: `/sbr` Slice P
## 2026-09-08 — #80 Slice V Callcheck leave wizard: BLOCKED (нет телефона)

- Fly **v492** · `SHOP_OTP_LOG_FALLBACK=false` (ssh)
- V0 PASS: checkout → «Вход по телефону»
- V1–V3 BLOCKED: нет `+79…` владельца — код не трогали
- Артефакт: `registration_callcheck_cascade_ui_ux/mcp/fly_v492_2026-09-08/`

## 2026-09-08 — SPEC: СБП 3001 + Zero-Click AccountToken

- Ops/bank-first SBR: primary **O→B→Z**, код (**C**) только после PASS кабинета
- `todo.md` · канон `tbank.md` / #34 / ISSUES SBP 3001 🟡
- Запрет фиктивного GREEN и «чинить 3001» аппом
- Next: `/sbr` Slice O
## 2026-09-08 — SPEC: #80 Callcheck → leave wizard (verify-first)

- CBR #80 · Slice V live first · код не трогать до FAIL
- `todo.md`: V→F→R · 6 файлов + 2 соседа · Не ломать / Проверка
- Канон Callcheck (не FlashCall); Point A; артефакт `registration_callcheck_cascade_ui_ux/mcp/`

## 2026-09-08 — Deploy Fly v490 + MCP pack (#38/#71/B2.2/#78)

- CI tip green [34224737257](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34224737257) → **fly deploy** v490
- MCP: #71 CRM **PASS** · #38 Wallet **PARTIAL** (нет SIMULATE/certs) · B2.2 **PARTIAL** (B6 Turbo) · #78 **PARTIAL** (нет plan/RebillId)
- Fix: barista menu search `turbo:load` bind — ждёт redeploy
- Артефакты: `…/mcp/fly_v490_2026-09-08/` · `b22_stage1_mcp_2026-09-08/`
- Sentry 24h unresolved **0**

## 2026-09-08 — REVIEW: #78 slice-5 Shop API

- bugbot high: reject POST if already `active`/`past_due`
- security medium: `resolve_payment_method!` requires `is_active: true`
- Local: subscriptions zone **13/0** · Entire `01M1ZYPHF0EZYHM7C12W5PSPA7` на `1f433a75`
- CI [34224418988](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34224418988) **green** · deploy — апрув

## 2026-09-08 — REVIEW: B2.2 stage-1 CI green

## 2026-09-08 — REVIEW: B2.2 этап 1 CI green

- tip `f03a46e1` · CI [34208612629](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34208612629) **green**
- bugbot search-fix `28cca017` · security no medium+ · Entire на `7c76a125`
- **deploy:** стоп до апрува · этап 2 — отдельным намерением

## 2026-09-08 — REVIEW: B2.2 этап 1 barista menu dual-pane

- bugbot low: search empty category headers → `28cca017`
- security: no medium+ (auth/RLS/XSS/session cart display-only)
- Entire `01M1ZZXV23N5BFK4SGDQV0H4KG` на `7c76a125` · push CI
- **deploy:** стоп до апрува

## 2026-09-08 — regress: B2.2 этап 1 barista menu PASS

- Zone: tablet_regression + orders_controller + order_creation_service → **62/0**
- Next: `/review`; Fly MCP — не обязателен (этап 1 UI layout, не shop pay)

## 2026-09-08 — GREEN: B2.2 этап 1 barista menu dual-pane

- `/barista/menu`: сетка карточек + панель корзины (`session[:barista_cart]`); «Оплатить» disabled
- create-order / sidebar / POS / sold_out PATCH — не трогали (этапы 2–5)
- Local: tablet+orders+OrderCreationService **62/0** · Entire `01M1ZZXV23N5BFK4SGDQV0H4KG` на `7c76a125`
- Next: `/regress` → `/review`

## 2026-09-08 — REVIEW: #71 CRM Brevo Contacts

- bugbot high: `retry_on` CrmContactSync::Error + StandardError (5 attempts) — `fecee7e3`
- security: no medium+ (ENV keys, consent/bounce, no PAN)
- CI tip fix: rubocop listIds spaces + B2.2 menu `@categories` grouping — `e247f9b1`
- Local 20/0 · Entire `01M1ZZXV23N5BFK4SGDQV0H4KG` на `cb1e336d` · CI [34207477722](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34207477722) **green**
- Next: deploy — апрув; Fly MCP Point A после deploy

## 2026-09-08 — regress: #71 CRM Brevo Contacts PASS

- Zone: CRM job+sync + receipt + orders_email → **20/0** (12+8)
- Next: `/review`; Fly MCP Point A — после deploy (live Brevo smoke опц.)

## 2026-09-08 — regress: #78 slice-5 Shop API PASS

- Zone: `test/services/subscriptions/` + `subscriptions_api_test` → **11/0**
- Regress #77: `profile_subscription_offer_test` → **7/0**
- Next: `/review` (bugbot + security + push CI); Fly MCP Point A — после deploy

## 2026-09-08 — REVIEW: Wallet PKCS7 bugbot/security fixes

- bugbot high: `paula.r@example.org` → `icon@2x.png`
- security medium: OpenSSL details в лог; клиенту стабильный `PassKit signing failed`
- Local zone 21/0 · Entire `01M1ZYPHF0EZYHM7C12W5PSPA7` · push CI

## 2026-09-08 — GREEN: Apple Wallet PassKit PKCS7

- `PassSigner`: ZIP + SHA1 manifest + PKCS7 detached; `WALLET_WWDR_CERT_PEM` в `certs_configured?`
- `PassBuilder` prod path → signed `.pkpass` (`storeCard`); simulate stub без регрессии
- Tests: apple_wallet 9 · ready_push + wallet_pass 12 PASS · Entire `01M1ZYPHF0EZYHM7C12W5PSPA7` на `f8cd57a8`
- OUT: APNs device register (след. SBR)

## 2026-09-08 — SPEC: #71 Slice A CRM Brevo Contacts sync

- SBR #71 ST-9: убрать stub `SyncContactToCrmJob` → `Shop::CrmContactSync` (Brevo Contacts upsert)
- Решения: тот же `BREVO_API_KEY` · без DDL · raise→retry · kill-switch `CRM_SYNC_ENABLED` · удалить мёртвый RSpec
- todo: job + sync + Minitest + shop-api/INTEGRATIONS · Не ломать consent/receipt/bounce/pay · Проверка

## 2026-09-08 — SPEC: B2.2 этап 1 barista menu dual-pane

- SBR B2.2 этап 1: единый layout `/barista/menu` (сетка карточек + панель корзины)
- OUT: sold_out PATCH / POS / удаление create-order / cash (этапы 2–5)
- todo: menu views + MenuController cart session · Не ломать B2.1/W1.4/create-order · Проверка tablet regress

## 2026-09-08 — SPEC: #78 slice-5 Shop API subscriptions

- SBR #78 после slice-1: публичный Shop API (GET current + POST create)
- Решения: cancel/confirm → **501** до Slice 3/4; PATCH auto_renew real; PurchaseService вызов only
- todo: routes + SubscriptionsController + integration test + shop-api.md · Не ломать / Проверка

## 2026-09-08 — SPEC: Apple Wallet PassKit PKCS7

- SBR #38 / #35 B3 slice: prod `.pkpass` signing (APNs device register OUT)
- Решения: `storeCard` · `WALLET_WWDR_CERT_PEM` · OpenSSL + Zip (rubyzip в lock) · без новых gem’ов
- todo: файлы PassBuilder/Config/PassSigner + Не ломать / Проверка

## 2026-09-07 — deploy Fly v489 (RUBY-1G)

- GH Deploy [34130234929](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34130234929) green · tip `3a579022`
- Image `deployment-01M1Y2J4PV5Z5SP7JWM317N8CC` · `/up` 200 · shop+categories Point A 200
- Fly: `deactivate_each!` + unique `revoked-{id}-{hex}` confirmed via runner
- Sentry unresolved 24h: **0** · logs: boot OK (proxy refuse during release — transient)

## 2026-09-07 — Sentry RUBY-1G close

- Root: `rails runner` `update_all(refresh_token: "revoked-"+hex)` — один токен на N строк
- App: `MobileSession.deactivate_each!` + unique `deactivate!` (`revoked-{id}-{hex}`)
- Sentry: resolvedInNextRelease · **deploy:** стоп до апрува

## 2026-09-07 — CI: deactivate assertions + vite prebuild

- Root: `833cb113` rewrite `refresh_token` on deactivate — integration still `find_by(old)`
- Fix: `pwa_lk_api_test` / `session_refresh_test` expect nil old token + `revoked-…` row
- CI: `bundle exec vite build --mode=test` before rails test (PwaManifest flake)
- Local PASS: unit 3 + failing 2 · **deploy:** стоп

## 2026-09-07 — Sentry RUBY-1H / RUBY-1G

- [RUBY-1H](https://llc-manageengine.sentry.io/issues/RUBY-1H): Price ≥10 на `fly:release`/`demo:seed` — clamp в ProductTenantSync (уже v488)
- [RUBY-1G](https://llc-manageengine.sentry.io/issues/RUBY-1G): UniqueViolation `refresh_token` — `MobileSession#deactivate!` пишет уникальный `revoked-{id}-{hex}`
- **deploy:** стоп до апрува

## 2026-09-07 — min charge 10₽ (T-Bank + catalog)

- `Payments::AmountLimits::MIN_CHARGE_RUB = 10`
- `ProductTenantSetting` / `ProductPriceHistory` ≥10 · `TbankAdapter` + `SbpPaymentInitiator` reject below
- `ProductTenantSync` / demo markup clamp ≥10 (release `demo:seed` OK)
- rake `shop:catalog:bump_min_prices` · Fly PTS below=0 after v488
- tip `0314c3be` · Fly **v488** `deployment-01M1XWZAJMGWHW89JR7T43K07C` · `/up` 200
- tests: amount_limits + PTS + sbp + tbank + growth + sync clamp

## 2026-09-07 — v486 · #79 MCP PASS · GH Deploy token fixed

- tip `d81990b4`: resume SBP GetQr if `provider_payment_id` set (T-Bank error 8)
- prior `fa1762c8`: cart ≤ promo → no negative discount
- CI [34109574092](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34109574092) green
- `FLY_API_TOKEN` → **org** token (deploy token + CRLF ломали Authorization) · GH Deploy [34117804689](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34117804689) **green** → **v486**
- MCP #79 Point A: sbp_init 200 · growth 11₽ · NSPK QR · waiting UI PASS · artifacts `…/fly_v486_2026-09-07/`
- #80: `SHOP_OTP_LOG_FALLBACK=false` · live call всё ещё SKIP
- Backlog: demo cart ≤10₽ + bind → T-Bank 3016 (min 1000 коп.)

## 2026-09-07 — deploy v482 + MCP Point A (#79/#80/#81/#82)

- tip `4f980e96` · CI [34103028345](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34103028345) green
- GH Actions Deploy **fail** (`FLY_API_TOKEN` unauthorized) → local `fly auth login` + `fly deploy --remote-only --depot=false` → **v482**
- `/up` 200 · SMS secrets OK · Solid Queue OK · Sentry 24h: 0 new
- Fly MCP: **#82 PASS** · **#81 PASS** · **#80 PARTIAL** (desktop KB + OTP log fallback) · **#79 PARTIAL** (sbp_init 422 discount; R3 labels OK)
- Артефакты: `…/mcp/fly_v482_2026-09-07/` под каждым CBR

## 2026-09-07 — REVIEW: #81 denied→settings + chat Telegram

- bugbot: settings CTA только при `openSettings` (denied) · fix `ffd48c6b`
- security: no medium+
- Entire: `01M1XF20DA5E0PXJ99E9DH2HM6` · Local JS 21/0 · CI [34102734432](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34102734432) green
- Next: deploy апрув · Fly MCP Point A

## 2026-09-07 — REVIEW: #82 hide-on-ready + cascade SMS

- bugbot: HIDE_REPEAT без `ready` (repeats после hide) · medium presence OK с unsubscribe
- security: no medium+
- GREEN `8cae376d` · fix `959f2fa` · Entire `01M1XDGFW23WY77ZRW73D5KGT4`
- CI [34101618655](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34101618655) **green**
- deploy стоп · Fly MCP Point A после deploy

## 2026-09-07 — REVIEW: #80 registration Callcheck UI/UX CI green

- bugbot: clear poll error after success · security: no medium+
- CI [34100150077](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34100150077) green (tip includes receipt test fix)
- Entire `01M1XDGFW23WY77ZRW73D5KGT4` · deploy стоп до апрува · Fly MCP после deploy

## 2026-09-07 — ops: /regress #81 PASS (denied→settings + chat)

- JS: push_subscribe + support_chat + notify_actions → **21/0**
- Next: `/review` · Fly MCP Point A после REVIEW/deploy (hot-path витрина)

## 2026-09-07 — ops: /regress #82 PASS (hide-on-ready + cascade)

- JS: order_status_sheet + active_poll → **29/0**
- rails: cascade job + notifier + broadcaster + channel + active_orders → **35/0**
- Next: `/review` · Fly MCP Point A после deploy

## 2026-09-07 — REVIEW: #80 registration Callcheck UI/UX

- bugbot: clear poll `localError` / checkout `err` after successful check_status
- security-review: no medium+
- Local regress PASS · push → CI · Fly MCP после deploy

## 2026-09-07 — ops: #79 REVIEW CI green 34098247173

- tip `e0c4d1a6` · CI [34098247173](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34098247173) green
- Entire `01M1XCSZMTMDNJCCACY2GZPW71` · deploy стоп до апрува · Fly MCP после deploy

## 2026-09-07 — ops: /regress #80 PASS (phone auth / CartSheet)

- JS: cascade + wizard + webview → **33/0**
- rails: phone_otp API + auth_funnel + phone_otp service → **23/138/0**
- GREEN `61593bb2` · next `/review` · Fly MCP Point A после deploy

## 2026-09-07 — feat: #80 registration UI/UX Callcheck [GREEN]

- Hide checkout `+N₽` when keyboard open on `#/checkout`
- Callcheck hint + номер в кнопке `phone-auth-tel-btn`
- Poll: `interpretCallcheckPoll` → onVerified; ошибки не soft-swallow
- RED `cbd1d8a4` · GREEN `61593bb2` · ждёт `/regress`

## 2026-09-07 — feat: #79 REVIEW — bugbot fixes (sync hash + SBP labels + waiting poll)

- Sync `location.hash` before nspk (`beginSbpBankRedirect`)
- SBP init fail: no rethrow into card `payFsmLabel`
- App recover polls on `status=waiting`
- security-review: no medium+ · Local JS 54 · rails 15/75

## 2026-09-07 — ops: /regress #79 PASS (SBP return + autopay)

- JS: `codeblack` + `shop_sbp_*` → **54/0**
- rails: `sbp_payment_return_ui` + `sbp_autopay_charge` + `payment_status` → **15/70/0**
- GREEN `5b3bc76e` · next `/review` · Fly MCP Point A после deploy (hot-path)

## 2026-09-07 — docs: SPEC #82 cascade SMS + status sheet

- `todo.md`: hide-on-ready (`orderStatusSheet` + `#active` без ready) · cascade presence→SMS
- Файлы: orderStatusSheet · orders#active · OrderReadyCascadeJob · GuestOrderChannel · PaidNotifier · Broadcaster
- Не ломать: One-Click/SBP · repeats после ready · табло · peek accepted/preparing
- Проверка: JS order_status_sheet+poll · rails cascade+notifier+broadcaster+channel+active_orders
- Вне slice: SMS URL-шаблон · RSpec из Google Doc

## 2026-09-07 — docs: SPEC #81 notifications gaps (denied→settings + chat)

- `todo.md`: кликабельный denied-баннер → настройки; chat → `SUPPORT_TELEGRAM_URL`; #38 вне slice
- Скрин: `artifacts/…/01_push_denied_browser_settings_2026-09-07.png`
- Файлы: orderStatusNotifyActions · ActiveOrdersAccordion · supportChatAdapter · supportConfig + JS tests
- Не ломать: Wallet · push granted · cancel · #35 peek

## 2026-09-07 — docs: intake #82 cascade SMS + status sheet

- PHASE 0: правки п.10 — SMS после «заказ готов» не работает; шторка статуса остаётся на гл. экране
- ТЗ: `customer_tasks/Каскад SMS после Заказ готов и шторка статуса на главном.md`
- Артефакты: `artifacts/order_ready_cascade_sms_status_sheet_fix/`
- CBR #82 + reopen #39/#35 · DEMO_FEEDBACK · код не трогали · ждёт `/spec`

## 2026-09-07 — docs: SPEC #80 registration UI/UX + Callcheck

- `todo.md`: Callcheck канон (не flash_call); P0 keyboard/CTA · copy · post-call; ×2 backlog
- Файлы: CartSheet / shopWebViewLayout / Checkout / phoneAuthCascade / PhoneAuth{Wizard,CodeStep} / phone_otp
- Не ломать: One-Click/SBP · peek · Callcheck→SMS@40s · #35 status
- Проверка: JS cascade+wizard+webview · rails phone_otp + auth_funnel_wizard

## 2026-09-07 — docs: intake #81 notifications / Wallet / WebPush gaps

- PHASE 0: reopen #37/#38/#41 — denied→настройки браузера; фоновые FCM/Wallet «не реализовано»; чат поддержки не кликается
- ТЗ: `customer_tasks/Косяки уведомлений Wallet WebPush фоновые и кнопка чат.md`
- Артефакты: `artifacts/notifications_wallet_webpush_gaps_reopen/`
- CBR #81 (#80 = Registration) · код не трогали · ждёт `/spec`

## 2026-09-07 — docs: intake #80 registration UI/UX + Callcheck cascade

- PHASE 0: правки п.8 (клавиатура/сумма, копирайт Callcheck, нет перехода после звонка) + Google Doc каскада Callcheck×2→SMS
- ТЗ: `customer_tasks/Регистрация PWA UI UX и каскад Callcheck x2 SMS.md`
- Артефакты: `artifacts/registration_callcheck_cascade_ui_ux/` (2 скрина)
- CBR #80 + ISSUES · код не трогали · ждёт `/spec`

## 2026-09-07 — docs: SPEC #79 SBP return + autopay labels

- `todo.md`: waiting до `redirectToSbp` · wire `createSbpAutopayFsm` · SMS вне slice
- Файлы: Checkout / App / PaymentResult / shopSbp{Pay,Autopay} / codeblackPendingOrder
- Не ломать: card One-Click · Repeat SBP · #35 шторка · webhook
- Проверка: JS codeblack+sbp_* · rails sbp_payment_return_ui + sbp_autopay_charge + payment_status

## 2026-09-07 — docs: intake #79 SBP return + autopay labels

- PHASE 0: правки п.7 заказчика (статусы автоплатежа, экран после банка, 11/8 СБП) + повтор CODE:BLACK ТЗ
- ТЗ: `customer_tasks/Надписи автоплатежа и экран после возврата из банка СБП.md`
- Артефакты: `artifacts/sbp_return_status_screen_autopay_labels/`
- CBR + README индекс · код не трогали · ждёт `/spec`

## 2026-09-07 — deploy v481 + MCP Point A (#35/#71/#26/Итого)

- Push `a9148d9b` · CI [34088874139](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34088874139) green
- `fly deploy --remote-only --depot=false` → **v481** · `/up` 200
- MCP: #35 MUST PASS · #71 PASS · CartSheet Итого PASS · #26 PARTIAL (нет saved card для M2)
- Артефакты: `…/mcp/fly_v481_2026-09-07/`

## 2026-09-07 — docs: #71 MCP plan remember receipt email (post-deploy agent)

- План Point A R0–R6 · hide только после LS `shop_receipt_email` (не profile)
- Файл: `artifacts/email_collection_after_payment/MCP_DEPLOY_CHECKLIST.md`
- Deploy этим агентом нет — общий deploy + MCP другим

## 2026-09-07 — docs: #26 MCP plan step5 (post-deploy agent)

- План Point A M1–M6 · P0 = M2 inline на отказе банка
- Файл: `artifacts/repeat_order_invalid_token_payment_sheet/MCP_PLAN_STEP5_2026-09-07.md`
- Deploy этим агентом нет — общий deploy + MCP другим

## 2026-09-06 — REVIEW: #26 step5 pay sheet inline

- GREEN `32c79960` · regress `f5f73d3e` · bugbot OK · security OK
- Entire `01M1V1SBJ6NVZ0K0X3RQ0CSE4Z` · CI GREEN `34025628548` / `34025794993`
- Next: deploy по апруву · Fly MCP Point A для заказчика

## 2026-09-06 — REVIEW: #71 email remember / don’t re-ask

- bugbot: hide только после LS save (не profile) → fix `0c17ee9f`
- security: no issues
- Local: JS 16 · rails 10 PASS · Entire `01M1V2FH9A8C7J6X35YF5RQSFE`
- Push develop · CI (см. HANDOFF)
- Deploy / Fly MCP Point A — только по апруву

## 2026-09-06 — regress: #71 email remember / don’t re-ask PASS

- JS: `email_collection_test` **16/0**
- rails: `checkout_acceptance_cbr` **10/0**
- Next: `/review` · Fly MCP Point A ещё для заказчика

## 2026-09-06 — REVIEW: #35 QA reopen compact status sheet

- bugbot: no bugs · security: no issues
- Local: JS 60 · rails 15 PASS · Entire `01M1V0RTYSBYRP8NWWEAWR24W0` на `fa7d6d75`
- Push develop · CI **green** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34026092095
- Deploy / Fly MCP Point A — только по апруву

## 2026-09-06 — regress: #26 step5 pay inline PASS

- JS: payment_error + repeat_invalid_token **29/0**
- rails: repeat_invalid_token_payment **12/0**
- Next: `/review` · Fly MCP Point A ещё для заказчика

## 2026-09-06 — regress: #35 QA status sheet PASS

- JS: cancel/accordion/sheet/notify **60/0**
- rails: acceptance+mount **15/0** · peek/expanded stack **9/0**
- Next: `/review` · Fly MCP Point A ещё для заказчика

## 2026-09-06 — REVIEW: CartSheet «Итого» (правка 5)

- GREEN `7d7cfbec` · fix thousands `91daaf19` · Entire `01M1V145Z4ABQQM5APY2EXEG6N`
- bugbot: hidden total → `formatThousands` · security: no issues
- Local: cart zone 36/0 · Next: deploy по апруву

## 2026-09-06 — GREEN: #35 QA reopen compact status sheet

- RED `785fa2e3` · GREEN `7ab3f3e6` · Entire `01M1V0RTYSBYRP8NWWEAWR24W0`
- Post-pay → `/` + compact sheet; status без receipt; cancel hint «1–3 дня»; X = Скрыть
- Local: JS zone 60 PASS · rails acceptance/mount 15 PASS

## 2026-09-06 — SPEC: #71 QA reopen email remember / don’t re-ask

- Канон: после первого email для чека — блок не показывать на следующих заказах
- `todo.md` → #71 · SPEC `[x]` · RED `[ ]`
- Решение: tenant LS receipt-email + hide `OrderSuccessEmailBlock` в `PaymentResult`

## 2026-09-06 — feat: CartSheet видимое «Итого» (правка 5) [GREEN]

- `checkoutBar`: слева **Итого N₽** (`shop-cart-order-total`), справа кнопка `+N₽`
- Hidden: `shop-cart-hidden-total` без `sr-only`
- Тесты: `cart_checkout_button_total_dynamic` + регрессия b113/quick_repeat PASS
- Next: `/review`

## 2026-09-06 — docs: #71 QA reopen (email remember, don’t re-ask)

- Фидбек заказчика: почту после оплаты для чека — **запомнить**, на следующих заказах **не спрашивать**
- ТЗ #71 без перезаписи; артефакт `…/email_collection_after_payment/`
- CBR #71 → QA reopen · Next `/spec`
- Мета: правки заказчика — **как сказано** (очередь 1–5 + эта)

## 2026-09-06 — SPEC: #26 QA reopen step5 inline pay error

- Root: `resolveCheckoutSheetInlineError` → null; G7 `$effect` сбрасывает FSM/selection
- Решение: friendly label в слот sheet; selection сохранить; CTA click → new card
- `todo.md` → #26 · SPEC `[x]` · RED `[ ]`

## 2026-09-06 — docs: #26 QA reopen (pay error inline copy)

- Фидбек заказчика: отказ карты есть, **нет** пояснения («попробуйте другую карту» / что делать)
- ТЗ #26 без перезаписи; артефакт `…/repeat_order_invalid_token_payment_sheet/screenshots/qa_2026-09-06/`
- CBR #26 → QA reopen · #35 на паузе · Next `/spec`

## 2026-09-06 — SPEC: #35 reopen QA статусной шторки

- Заказчик: 3 правки (home post-pay full-screen; X/состав/cancel 1–3д; UX референс)
- `todo.md` → #35 reopen · SPEC `[x]` · RED `[ ]`
- QA скрины → `artifacts/order_status_compact_sheet_push/screenshots/qa_2026-09-06/`
- Решения: PaymentResult → `/`; status row без receipt; CTA hint 1–3 дня; X = dismiss

## 2026-09-05 — deploy v480 + Fly MCP ×3 Point A PASS

- `git push` develop up-to-date · CI green `33951901384`
- `fly deploy --remote-only --depot=false` → **v480** `deployment-01M1R6VMAJFWR0VDA4V5TCGRJ7`
- MCP-1 offer rollback: УК OFF + config `enabled=false` + ready CTA tips · PASS
- MCP-2 promo `amount_rub` 11→15→11 via `point_campaign_settings` · PASS (live charge SKIP)
- MCP-3 #78: `subscription_*` tables on Fly · shop smoke PASS · purchase E2E SKIP (no API/UI)
- Sentry 24h new: none · Fly logs: OK
- Artifacts: `…/mcp/fly_v480_2026-09-05/` (offer / promo / subscription_billing)

## 2026-09-05 — review: #78 subscription slice-1

- bugbot: no bugs · security HIGH → fix webhook `subscription_intent` → closed + PaymentFulfillment
- Local: purchase + PaymentStatusUpdater + qa_2_3/order_creator PASS
- Push `develop` → CI **green** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/33951753636
- Entire: `01M1R4VQH6TPMM6SQ2RZ5JTM46` на `cb02d8b4`
- Deploy / Fly MCP: **только по апруву**

## 2026-09-05 — REVIEW: promo amount from point_campaign_settings

- bugbot: no bugs · security: no medium+ · Local 43 runs PASS
- Push `develop` → CI **green** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/33951212810
- Entire: `01M1R4VQH6TPMM6SQ2RZ5JTM46` · impl GREEN `34a899d4`
- Deploy / Fly MCP Point A: **только по апруву** (live Subtask 12)

## 2026-09-05 — ops: /regress #78 subscription PurchaseService PASS

- `purchase_service_test` 1/19 PASS
- `qa_section_2_3_payment_cart` + `order_creator` 23/44 PASS
- Next: `/review`; Fly MCP Point A — после deploy

## 2026-09-05 — regress: promo amount from config PASS

- growth_promo 13 + point_campaign 4 + user_cards 3 + qa_2_3 2 + order_creator 21 — 0 failures
- Next: `/review`; Fly MCP Point A — после deploy

## 2026-09-05 — REVIEW: emergency disable subscription offer Point A

- bugbot: no bugs · security: no medium+ · Local regress PASS
- Push `develop` → CI **green** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/33950595431
- Entire: `01M1P2BSG7MY3C0VM0FXCSZXRK` · Point A offer remains OFF (config, no deploy needed)
- Deploy: не требуется для этого отката (уже на Fly v479)

## 2026-09-05 — feat: promo amount from point_campaign_settings [GREEN]

- `GrowthPromo.promo_amount_rub(tenant)` ← `config["promo_amount_rub"]`; fallback `DEFAULT_PROMO_AMOUNT_RUB`
- `AMOUNT_RUB` alias на DEFAULT; UserCards API `amount_rub` с того же helper
- Entire: `01M1R4VQH6TPMM6SQ2RZ5JTM46` (impl `34a899d4`); next `/regress`

## 2026-09-05 — docs: SPEC #78 subscription billing slice-1

- todo: plans/subscriptions + PurchaseService; backlog usage/renewal/API/UI
- Не ломать: checkout, binding, webhook idempotency, #77 offer OFF
- Next: `/sbr` RED

## 2026-09-05 — docs: intake #78 Архитектура подписки

- customer_tasks + CBR + artifacts `subscription_billing_architecture/`
- Scope: plans/subscriptions/usage, Purchase/Renewal/Cancel, Shop API, PWA, jobs; без правок `TbankAdapter`
- Next: `/spec`; Задача-2 promo parked

## 2026-09-05 — regress: subscription offer zone PASS (post-rollback)

- Local: rails 20/79 PASS + CTA JS 16 PASS
- UK Point A recheck: `enabled=false`, `second_cta_mode=tips`
- CTA matrix: offerOff → tips on ready (no subscription stub)

## 2026-09-05 — ops: emergency disable subscription offer (Point A) [GREEN]

- УК PATCH Point A: `enabled=false` + `second_cta_mode=tips` (было subscription)
- Audit: в УК visible только Point A (SINGLE_POINT_A); других risky нет
- Verify: `GET /shop/api/config` → `subscription_offer.enabled=false`
- Artifact: `subscription_offer_eligibility/ops/rollback_point_a_2026-09-05.json`
- Код CTA/eligibility / `INTEGRATIONS.md` не менялись; ready CTA E2E → `/regress`

## 2026-09-05 — SPEC: promo amount from point_campaign_settings

- Задача-2: `price!` / `charge_amount` / API `amount_rub` ← `promo_amount_rub`; дефолт один (`DEFAULT_PROMO_AMOUNT_RUB`)
- Scope: GrowthPromo + UserCardsController + тесты; Tbank/antifraud/subscriptions вне
- Next: `/sbr` RED; subscription-offer rollback → **done** (см. запись выше)

## 2026-09-05 — SPEC: emergency disable subscription offer (Point A)

- Config-only rollback plan: УК `subscription_offer_setting` → `enabled=false`
- Point A `2fdee1ac-4674-41ee-b89e-87b45643f789`; код CTA/eligibility не трогаем
- todo: Audit SELECT → GREEN УК → CTA verify → DEMO_FEEDBACK

## 2026-09-04 — ops: clear stuck T-Bank pending (StuckPayments spam)

- Fly runner: mark `tbank` pending/processing `< 2026-09-01` → `failed` (186); related `pending_payment` orders → `cancelled` (182)
- Also cleared 2 Point A MCP leftovers from 2026-09-04 (live charge SKIP)
- `STUCK_ALERT_CANDIDATES_NOW=0` (Telegram StuckPaymentsCheckJob quiet)
- One-shot scripts under `tmp/` (not productized)

## 2026-09-04 — fix: Sentry RUBY-1F / RUBY-16 runner Current noise

- `SentryNoiseFilter`: `LocalJumpError` + `tags.source=runner` (пустой transaction)
- `Current.assign!` — assign без блока (вместо ошибочного `set!` / `set` без `do`)
- Tests: noise filter + Current
- Fixes RUBY-1F · Fixes RUBY-16

## 2026-09-04 — deploy: Fly v479 + MCP #75/#76/#77 Point A

- `fly deploy` → **v479**; release: ConcurrentMigrationError → soft-skip when schema current (`fly_release.rake`)
- MCP Point A: #76 PASS · #75 UI PASS (live charge SKIP) · #77 A–F PASS
- Artifacts: `…/mcp/fly_v479_2026-09-04/`
- Next: апрув заказчика

## 2026-09-04 — review: #77 subscription offer eligibility · CI

- bugbot: no bugs · security: no medium+
- follow-up: wire config/profile into OrderActionButtons + OrderStatus; subscription → ЛК
- docs: shop-api + pwa-realtime (#77)
- Entire: `01M1P2BSG7MY3C0VM0FXCSZXRK` на `4087ad4e`
- Next: deploy апрув · Fly MCP Point A

## 2026-09-04 — ops: /regress #77 PASS subscription offer zone

- eligibility + settings + profile/UK API: 20 runs / 79 assert PASS
- push_register + orders_email: 10 runs / 38 assert PASS
- Next: `/review` · Fly MCP Point A после deploy

## 2026-09-04 — fix+review: #76 kitchen disables promo · REVIEW

- bugbot medium: смена типа на `production_kitchen` гасит `card_binding_promo` (counter сохранён)
- security-review: no medium+
- Entire GREEN: `01M1P2BSG7MY3C0VM0FXCSZXRK` на `6c1966d2`
- Next: CI green · deploy апрув · Fly MCP Point A

## 2026-09-04 — ops: /regress #76 PASS

- Platform/promo: 31 runs / 96 assert PASS
- order_creator + user_cards_sbp: 23 runs / 50 assert PASS
- Next: `/review` · Fly MCP Point A после deploy

## 2026-09-04 — docs: SPEC #77 subscription offer eligibility

- todo.md: signals на mobile_customers · settings per-point · Eligibility service · profile/config · CTA + appinstalled
- Решения §4: fallback=tips · enum tips|subscription · completed_orders query · без денормализации
- Не ломать: orders_count · CTA при enabled=false · FCM/email · PWA banner · Tbank/фискал/11₽/billing
- Проверка: eligibility + settings + profile API; регресс push_register + orders_email

## 2026-09-04 — docs: intake #77 subscription offer eligibility

- ТЗ 1:1: `customer_tasks/Умный показ оффера подписки — сигналы толерантности и УК-переключатель.md`
- Artifacts: `subscription_offer_eligibility/`
- CBR #77; #76 parked (SPEC done → `/sbr`); фокус сессии → `/spec` #77

## 2026-09-04 — docs: SPEC #76 point_campaign_settings

- todo.md: Tenant=точка · УК form/show · GrowthPromo.point_allows_promo? · sync upsert
- Не ломать: checkout full price · attempts semantics · изоляция точек
- Проверка: tenants_controller + growth_promo + order_creator / user_cards

## 2026-09-04 — docs: intake #76 УК point campaign promo 11₽

- ТЗ 1:1: `customer_tasks/УК — включение промо 11₽ при создании точки.md`
- Artifacts: `uk_point_campaign_promo_11rub/`
- CBR #76 + README customer_tasks; #75 статус → REVIEW+follow-up

## 2026-09-04 — fix(ci): soft-skip importmap audit on npm transport flake

- `scan_js`: retry ×3; после 3× `Net::ReadTimeout` → warning + exit 0
- Реальные vuln findings по-прежнему валят job
- `config/ci.rb` — тот же контракт

## 2026-09-04 — fix(ci): retry importmap audit on npm ReadTimeout

- `scan_js`: 3 попытки с backoff вокруг `bin/importmap audit` (флейк `Net::ReadTimeout`)
- `config/ci.rb`: тот же retry для локального `bin/ci`
- Реальные уязвимости по-прежнему валят job (без continue-on-error)

## 2026-09-04 — feat: #75 follow-up velocity phone_status Checkout PII

- `BindingVelocity` 15м (hash/phone/device/IP/BIN; BIN не для СБП)
- `phone_status` enum + `BindingStepUp` (OTP только телефон аккаунта)
- Checkout `promoEligible`/`cartTotalRub` + `growth_promo` в `/user/cards`
- `phone_digest` + `purge_expired!`; SBP `dedupe_active_sbp_method_hashes!`

## 2026-09-04 — fix: #75 REVIEW growth promo amounts + mark_used

- `GrowthPromo.price!` — discount под `chk_order_amounts`
- `consume_from_payment!` после успешной card/SBP bind
- SBP init применяет 11₽ при `save_sbp_account`
- Receipt: одна позиция 11₽ при `growth_promo_intent`

## 2026-09-04 — feat: stuck payments cron + channel order stats log

- `config/recurring.yml`: `Payments::StuckPaymentsCheckJob` every 15m (TelegramAlertJob без дедупа)
- `Analytics::ChannelOrderStatsJob` + Collector — счётчики `orders.source` / 15m / `open_now`, только лог `[ChannelOrderStats]`
- Без правок `Health::TenantChecker`; без Telegram на stats
- Local: analytics collector+job PASS

## 2026-09-04 — ops: /regress #75 binding+promo PASS

- payments+growth 28 runs PASS · order_creator+qa§2.3 23 PASS · i18n 4 PASS
- Зона: shop/оплата · Fly MCP Point A ещё нужен для заказчика
- Next: `/review`

## 2026-09-04 — docs: SPEC #75 binding + promo 11₽

- `todo.md` — SBR фазы, 7 файлов (SavedCardStore / SbpAccountTokenStore / MPM / OrderCreator / PaymentMethodsSheet + net-new attempts + growth_promo)
- Не ломать: полная оплата · UserCards/one-click · СБП bind · callback
- Проверка: saved_card_store + sbp_account_token_store; order_creator + qa §2.3 cart
- Ждёт `/sbr` RED

## 2026-09-04 — docs: intake #75 Привязка способа оплаты и промо 11₽

- ТЗ 1:1: `customer_tasks/Привязка способа оплаты и промо 11₽.md`
- Артефакты: `artifacts/payment_method_binding_promo_11rub/` (скрин шторки + P2 placeholder)
- CBR / README: строка #75 · статус intake · ждёт `/spec`
- Задача 1 из 3 (две следующие ещё не присланы)

## 2026-09-02 — feat: УК single-point lists (UkCatalogScope)

- `Platform::UkCatalogScope` — в `DEMO_SINGLE_POINT` только Point A + org в `/admin`
- Без single-point: только `active` sales_point (inactive/prog10 скрыты)
- Скрыты «Новая точка/орг» в single-point; show/edit по id не трогаем
- Тесты: uk_catalog_scope + uk_single_point_dashboard (9 runs PASS в зоне)

## 2026-09-02 — feat: single Point A prod (Fly cleanup + DEMO_SINGLE_POINT)

- `Platform::ProdSinglePointCleanup` — inactive лишних sales_point, без DELETE
- `DEMO_SINGLE_POINT=true` + `SHOP_DEFAULT_TENANT_ID` в `fly.toml`
- `fly:release` → `platform:prod_single_point` после `demo:seed`
- Deploy **v474** · release `[platform:prod_single_point] OK`
- Активны: **demo-point-a** + demo-prep-kitchen (backend)
- Артефакт: `artifacts/single_point_a/cleanup_2026-09-02.json`
- Тесты: platform cleanup + environment_setup + RLS (19 runs PASS)

## 2026-09-02 — ops: ctx-trim токенов (rules + todo + ISSUES)

- Удалены 7 дублей `.cursor/rules/coffeeos-*.mdc` в корне (канон — `project/`)
- Сжат always-бандл: `.cursorrules`, `coffeeos-index.mdc`, `coffeeos-agent-workflow.mdc`
- `todo.md` → stub deploy pending; полный SPEC → `session/archive/todo-shift-close-2026-09.md`
- ISSUES 🔴 — короткая таблица (ID / статус / блокер)
- `coffeeos-performance` globs: убран `test/**`
- **~600 tok/ход** always rules · **~650 tok/старт** todo+ISSUES · **~200 tok/edit** без дублей globs

## 2026-09-01 — chore: uploads gitignore (меньше шума в git status)

- `.gitignore`: убран `!/public/uploads/products/` — картинки локально/Fly эфемерны, в git только README
- Удалены 15 тестовых файлов из `public/uploads/products/` (MCP/локальные загрузки)

## 2026-09-01 — ops: ctx-trim + архив августа

- Коммит `e929d3bd` · ops ref `5b1519a5`
- Команда `/ctx-trim` + правило `coffeeos-context-hygiene.mdc` (ручной + weekly пт–вс)
- Архив: `handoff-2026-08.md`, `session_state-2026-08.md`, `CHANGELOG-2026-08.md`, `ISSUES-resolved-through-2026-08.md`
- Живые HANDOFF/SESSION/CHANGELOG/ISSUES — шапка + сентябрь; **~4k tok** экономии на старте vs проглатывание августа
