# CHANGELOG

## РЁР°РїРєР°

**РўРµРєСѓС‰РёР№ РјРµСЃСЏС†:** `2026-09`  
**РђСЂС…РёРІ:** [`archive/README.md`](archive/README.md) вЂ” `CHANGELOG-2026-06.md` вЂ¦ `CHANGELOG-2026-08.md`

> РђРіРµРЅС‚: **РЅРµ С‡РёС‚Р°С‚СЊ** РІРµСЃСЊ CHANGELOG РЅР° СЃС‚Р°СЂС‚Рµ. РџРёСЃР°С‚СЊ РЅРѕРІСѓСЋ Р·Р°РїРёСЃСЊ СЃРІРµСЂС…Сѓ С‚РµРєСѓС‰РµРіРѕ РјРµСЃСЏС†Р°. РђСЂС…РёРІ вЂ” РїРѕ Р·Р°РїСЂРѕСЃСѓ.

---

## РўРµРєСѓС‰РёР№ РјРµСЃСЏС† (2026-09)

## 2026-09-18 вЂ” feat: TASK_93-D history per_page default 20 [GREEN]

- `OrdersController#history`: blank/0/missing в†’ 20; max 50; T-D1aвЂ“d В· T-D3a/b PASS
- RED `faca7e3c` В· GREEN `9d2b98a8` В· Р·РµСЂРєР°Р»Рѕ `todo-block-D.md`
- Next: `/regress` (orders + mvp_flow)

## 2026-09-18 вЂ” docs: pin TASK_93-G SPEC (todo-block-G vs races)

- РљР°РЅРѕРЅ Р±Р»РѕРєР°: 	odo-block-G.md + GATES-block-G.md + RLS_PG_INVENTORY.md (session todo/GATES РіРѕРЅСЏСЋС‚ РїР°СЂР°Р»Р»РµР»СЊРЅС‹Рµ Р±Р»РѕРєРё)
- R1вЂ“R6 В· **R3-B** В· pp.shop_city_lookup В· Next: /sbr RED

## 2026-09-18 вЂ” docs: unlazy #93 TASK_93-K Hygiene pack (K1вЂ“K7)

- `GATES-block-K.md` + session `GATES.md`: G1 T-K1 blog В· G2 T-K2+T-K4 demo/merger В· G3 T-K3 paymentUrl В· G4 regress+K5/K7c В· G5в†’L
- `--status`: unmet 4 В· abandoned 1 (G5); `--approve` РїРѕСЃР»Рµ GREEN; K6 HANDOFF + K7 A|B = `/review` (SPEC locks A vs B)
- Next: `/spec` (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” docs: regress PASS #93 TASK_93-C SMS short link

- Zone: `order_ready_sms_link` + notifier + `order_short_links` + `rack_attack_order_short_link`
- Local: **18 runs / 0 failures** (seed 61367) В· GREEN `c2ef2d68`
- Next: `/review` В· Fly MCP Point A = TASK_93-L

## 2026-09-18 вЂ” docs: unlazy #93 TASK_93-J Push / worker / SMS_GRACE

- `GATES-block-J.md` + session `GATES.md`: G1 T-J1 async APNs В· G2 T-J2 FCM cache В· G3 T-J3 grace+5s В· G4 runbook+regress В· G5в†’L
- `--status`: unmet 4 В· abandoned 1 (G5); `--approve` РїРѕСЃР»Рµ GREEN (baseline: sync PassUpdater В· wait==grace В· no OAuth cache В· no SOLID_QUEUE_FLY.md)
- Next: `/spec` (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” docs: SPEC #93 TASK_93-H Cart cookie / overflow

- `todo.md` + `todo-block-H.md` в†’ TASK_93-H: R1 OverflowError rescue В· R3 cookie+cap (T-H2c SKIP) В· R4 lines=20 / bytes=3072 В· R5 update С‚РѕР¶Рµ
- Р¤Р°Р№Р»С‹ 5 + blast modifiers В· РќРµ Р»РѕРјР°С‚СЊ В· РџСЂРѕРІРµСЂРєР° G1/G4
- Next: `/sbr` RED (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” docs: SPEC #93 TASK_93-G Tenant GUC / RLS / schema

- `todo.md` + `todo-block-G.md` в†’ TASK_93-G: R1 txn SET LOCAL В· R2 staff concern В· **R3-B** ensure_all В· R5 `app.shop_city_lookup` В· R6 raise except test
- `RLS_PG_INVENTORY.md` must-have policies/triggers В· РќРµ Р»РѕРјР°С‚СЊ В· РџСЂРѕРІРµСЂРєР° G1/G2
- Next: `/sbr` RED (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” docs: unlazy #93 TASK_93-I OTP / Rack::Attack / auth abuse

- `GATES-block-I.md` + session `GATES.md`: G1 store T-I1 В· G2 verify T-I2 В· G3 OTP6/DEFER T-I3 В· G4 short-link+regress T-I4 В· G5в†’L
- `--status`: unmet 4 В· abandoned 1 (G5)
- Next: `/spec` (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” docs: regress #93 TASK_93-A payments/callbacks PASS

- G1 matrix: **40 runs, 0 fail** (updater В· deduction В· callback job В· tbank ctrl В· block_f)
- G2 zone: **139 runs, 0 fail** (`payments/` В· `callbacks/` В· `jobs/payments/`)
- Next: `/review` В· Fly MCP = Р±Р»РѕРє L

## 2026-09-18 вЂ” docs: unlazy #93 TASK_93-H Cart cookie / overflow

- `GATES-block-H.md` + session `GATES.md`: G1 T-H1 rescue В· G2 T-H2 line/byte В· G3 T-H3 422-not-500 В· G4 cart regress В· G5в†’L
- `--status`: unmet 4 В· abandoned 1 (G5); `--approve`: G1/G3 no `cart_overflow_test` В· G2/G4 baseline в‰  DoD
- Next: `/spec` (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” feat: #93 TASK_93-A moneyв†”order stock soft-fail [GREEN]

- `OrderRecipeDeduction`: missing/insufficient в†’ skip + `inventory_deduction_skipped` (РЅРµС‚ qty=0 trap)
- `PaymentStatusUpdater`: deduct РїРѕСЃР»Рµ payment txn; cancelled/closed+succeeded в†’ `payment_on_non_pending_order` / needs_manual_refund
- barista / OrderCreator: soft-fail СЃРєР»Р°РґР°; `TbankPaymentSync` в†’ `tbank_amount_mismatch` audit
- RED `fc97a432` В· GREEN `bba068f9` В· Local 83 PASS В· Entire `01M2SSQXT1V67AK260SH1P9RAX`
- Next: `/regress` В· todo: `artifacts/critical_path_hardening/TODO-block-A.md`

## 2026-09-18 вЂ” docs: unlazy #93 TASK_93-G Tenant GUC / RLS / schema

- `GATES-block-G.md` + session `GATES.md`: G1 staff T-G1 В· G2 inventory/ensure/fresh T-G2вЂ“G4 В· G3 city T-G5 В· G4 regress+T-G6 В· G5в†’L
- `--status`: unmet 4 В· abandoned 1 (G5)
- Next: `/spec` (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” docs: SPEC #93 TASK_93-F Callbacks/stuck/Events

- `todo.md` + `todo-block-F.md` в†’ TASK_93-F: R1 fail-closed В· R2/R3 release claim on reject В· R4 stuck GetState В· R5 fiscal report+1 retry В· R6 422
- Р¤Р°Р№Р»С‹ 7 + blast В· РќРµ Р»РѕРјР°С‚СЊ В· РџСЂРѕРІРµСЂРєР° G1/G4
- Next: `/sbr` RED (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” docs: unlazy #93 TASK_93-F Callbacks/stuck/Events

- `GATES-block-F.md` + session `GATES.md`: G1 Events T-F1/F2/F5 В· G2 stuck T-F3 В· G3 fiscal T-F4 В· G4 regress В· G5в†’L
- `--status`: unmet 4 В· abandoned 1 (G5)
- Next: `/spec` (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” docs: SPEC #93 TASK_93-E Init idempotency

- `todo.md` + `todo-block-E.md` в†’ TASK_93-E: R1 pid В· R2 uuid/failed txn В· R3 HTTP РІРЅРµ base_controller txn В· R4 tests
- Р¤Р°Р№Р»С‹ 7 + blast В· РќРµ Р»РѕРјР°С‚СЊ В· РџСЂРѕРІРµСЂРєР° G1/G2 В· Р·РµСЂРєР°Р»Рѕ РѕС‚ race СЃ A/B/D
- Next: `/sbr` RED (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” docs: restore SPEC #93 TASK_93-B (todo after D race)

- `todo.md` СЃРЅРѕРІР° TASK_93-B phone-first (РїРѕСЃР»Рµ РїР°СЂР°Р»Р»РµР»СЊРЅРѕРіРѕ SPEC D)
- Next: `/sbr` RED

## 2026-09-18 вЂ” docs: SPEC #93 TASK_93-D history per_page

- `todo.md` в†’ TASK_93-D: R1вЂ“R5 default 20 / max 50 В· T-D1/T-D3
- Р¤Р°Р№Р»С‹ 5 + blast В· РќРµ Р»РѕРјР°С‚СЊ В· РџСЂРѕРІРµСЂРєР° G1/G2
- Next: `/sbr` RED (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” docs: SPEC #93 TASK_93-B Checkout identity

- `todo.md` в†’ TASK_93-B: phone-first R1вЂ“R5 В· С„Р°Р№Р»С‹ OrderCreator/Recurrent/Checkout В· РќРµ Р»РѕРјР°С‚СЊ В· РџСЂРѕРІРµСЂРєР° G1вЂ“G3
- CBR `#93` SPEC B В· Next: `/sbr` RED (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” docs: unlazy GATES #93 TASK_93-E Init idempotency

- `session/GATES.md` + `artifacts/critical_path_hardening/GATES-block-E.md`
- G1 double Init / pid В· G2 RecordNotUnique / concurrent uuid В· G3 В§2.3 regress В· G4 HTTP РІРЅРµ txn (REVIEW) В· G5 Fly **ABANDON** в†’ TASK_93-L
- `gate-check --status`: unmet 4, abandoned 1; `--approve` РїРѕСЃР»Рµ GREEN (baseline в‰  DoD Р±РµР· T-E*)
- РџР°СЂР°Р»Р»РµР»СЊРЅРѕ: A SPEC В· C SPEC В· B/D РІ `GATES-block-B/D.md`

## 2026-09-18 вЂ” docs: SPEC #93 TASK_93-C SMS short link

- `todo.md` в†’ TASK_93-C: R2-A В· TTL 48h В· throttle 30/min В· one-time SKIP
- Р¤Р°Р№Р»С‹ 7 + blast В· РќРµ Р»РѕРјР°С‚СЊ В· РџСЂРѕРІРµСЂРєР° G1вЂ“G5
- Next: `/sbr` RED (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” fix: CI ABAC-015 (revert TenantOperatingHours preload)

- Loaded-empty `weekday_schedules` в†’ `open_now?` РІСЃРµРіРґР° true в†’ 3 CI fails
- Revert preload; RUBY-1J batch aggregate РѕСЃС‚Р°С‘С‚СЃСЏ (`94a7644b`)
- CI green: https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35323013520

## 2026-09-18 вЂ” docs: unlazy GATES #93 TASK_93-B Checkout identity

- РљР°РЅРѕРЅ ledger: `artifacts/critical_path_hardening/GATES-block-B.md` (session/GATES.md РіРѕРЅСЏСЋС‚ A/C/D)
- `--approve`: G3 baseline PASS; G1/G2 unmet (РЅРµС‚ test files); G4 manual; G5в†’L
- Next: `/spec` B

## 2026-09-18 вЂ” docs: unlazy GATES #93 TASK_93-D history per_page

- `session/GATES.md` + `artifacts/critical_path_hardening/GATES-block-D.md`
- G1 T-D1/T-D3 В· G2 orders+mvp_flow В· G3 D2 РєР»РёРµРЅС‚ (REVIEW) В· G4 Fly **ABANDON** в†’ TASK_93-L
- `gate-check --status`: unmet 3, abandoned 1; `--approve` РїРѕСЃР»Рµ GREEN (baseline file PASS в‰  DoD Р±РµР· T-D*)
- РџР°СЂР°Р»Р»РµР»СЊРЅРѕ: A SPEC В· B/C РІ `GATES-block-B/C.md`

## 2026-09-18 вЂ” docs: unlazy GATES #93 TASK_93-C SMS short link (active)

- РђРєС‚РёРІРЅС‹Р№ `session/GATES.md` = **C** В· РєР°РЅРѕРЅ `GATES-block-C.md` В· Р·РµСЂРєР°Р»Рѕ `artifacts/.../GATES.md`
- G1 SMS host В· G2 `/o/` bind В· G3 throttle В· G4 TTL В· G5 zone В· G6 Fly **ABANDON** в†’ TASK_93-L
- `gate-check --status`: unmet 5, abandoned 1; `--approve` РїРѕСЃР»Рµ GREEN (РЅРµ СЃРµР№С‡Р°СЃ)
- РџР°СЂР°Р»Р»РµР»СЊРЅРѕ: A SPEC В· B/D РІ `GATES-block-B/D.md`

## 2026-09-18 вЂ” docs: unlazy GATES #93 TASK_93-B Checkout identity (active)

- РђРєС‚РёРІРЅС‹Р№ `session/GATES.md` = **B** (РІРѕСЃСЃС‚Р°РЅРѕРІР»РµРЅ РїРѕСЃР»Рµ РєРѕР»Р»РёР·РёРё СЃ C)
- `--approve`: G3 baseline PASS; G1/G2 unmet (РЅРµС‚ `recurrent_order_creator_test` / `checkout_identity_test`); G5в†’L
- `GATES-block-A/B/C.md` РІ artifacts; C СЃРѕС…СЂР°РЅС‘РЅ РІ `GATES-block-C.md`
- Next: `/spec` B

## 2026-09-18 вЂ” docs: unlazy GATES #93 TASK_93-C SMS short link

- `session/GATES.md` + `artifacts/critical_path_hardening/GATES.md` (+ `GATES-block-C.md`)
- B в†’ `GATES-block-B.md`; A РѕСЃС‚Р°С‘С‚СЃСЏ `GATES-block-A.md`; todo A в†’ pointer РЅР° block-A
- G1 SMS host В· G2 `/o/` bind В· G3 throttle В· G4 TTL В· G5 zone В· G6 Fly **ABANDON** в†’ TASK_93-L
- `gate-check --status`: unmet 5, abandoned 1; `--approve` РїРѕСЃР»Рµ GREEN (РЅРµ СЃРµР№С‡Р°СЃ)

## 2026-09-18 вЂ” docs: SPEC #93 TASK_93-A Critical path (РґРµРЅСЊРіРёв†”Р·Р°РєР°Р·)

- `todo.md` в†’ TASK_93-A: С„Р°Р№Р»С‹ A1вЂ“A6 В· РќРµ Р»РѕРјР°С‚СЊ В· РџСЂРѕРІРµСЂРєР° G1/G2 В· РјР°С‚СЂРёС†Р° T-A*
- Next: `/sbr` RED (РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё)

## 2026-09-18 вЂ” docs: unlazy GATES #93 TASK_93-A Critical path (РґРµРЅСЊРіРёв†”Р·Р°РєР°Р·)

- `session/GATES.md` + `artifacts/critical_path_hardening/GATES.md`
- G1 РјР°С‚СЂРёС†Р° T-A* В· G2 zone regress В· G3 A4 Amount В· G4 Fly **ABANDON** в†’ TASK_93-L
- `gate-check --status`: unmet 3, abandoned 1; `--approve` РїРѕСЃР»Рµ GREEN (РЅРµ СЃРµР№С‡Р°СЃ)

## 2026-09-18 вЂ” fix: Sentry RUBY-1J ChannelOrderStats N+1

- `Analytics::ChannelOrderStatsCollector`: РѕРґРёРЅ aggregate `GROUP BY tenant_id, source` + `SET LOCAL row_security = off` (РІРјРµСЃС‚Рѕ SET LOCAL tenant РЅР° РєР°Р¶РґС‹Р№ tenant)
- `TenantOperatingHours`: РµСЃР»Рё `weekday_schedules` preloaded вЂ” С„РёР»СЊС‚СЂ РІ РїР°РјСЏС‚Рё
- Tests: collector + job + menu sort_order (RUBY-1K regression) PASS
- RUBY-1K: С„РёРєСЃ СѓР¶Рµ РІ `64b99477`, Р¶РґС‘С‚ deploy

## 2026-09-18 вЂ” docs: intake #93 TASK_93-B Checkout identity

- `customer_tasks/TASK-93-B-Checkout-identity.md` вЂ” РўР— 1:1 (phone-first; UI Pay в‰Ў Р±СЌРєРµРЅРґ)
- CBR `#93` в†’ Р±Р»РѕРє B В· artifacts `critical_path_hardening/` В· ISSUES #93
- Next: `/spec` (РЅРµ РєРѕРґ)

## 2026-09-18 вЂ” docs: intake #93 TASK_93 Critical path hardening (Р±Р»РѕРє A)

- `customer_tasks/TASK-93-Critical-path-hardening.md` вЂ” РўР— 1:1 (Р·РѕРЅС‚РёРє AвЂ“L; СЃРµР№С‡Р°СЃ A: РґРµРЅСЊРіРёв†”Р·Р°РєР°Р·)
- CBR `#93` В· `artifacts/critical_path_hardening/` В· ISSUES СЃС‚СЂРѕРєР° #93
- Next: `/spec` (РЅРµ РєРѕРґ)

## 2026-09-18 вЂ” security: Dependabot pack (gems + npm)

- `view_component` 3.25 в†’ **4.15.0** (GHSA preview/helper + system-test path; floor в‰Ґ4.9)
- `vite` в†’ **8.0.16**, `devalue` в†’ **5.9.2**, `svelte` lock 5.57 (npm audit 0)
- Rails/AS stack СѓР¶Рµ **8.1.3.1**, rack-session 2.1.2, puma 8.0.2 вЂ” bundler-audit clean
- **main** `d33f83c7`: sync lockfiles СЃ develop в†’ Dependabot **0 open / 93 fixed**; closed PRs #16вЂ“20
- Local: auth sessions 18 PASS; VC render smoke OK

## 2026-09-18 вЂ” fix: CodeQL ruby syntax warning on main

- `db/migrate/20250115000002_create_stage_2_payments.rb` РЅР° main: orphan `, if_not_exists: true, if_not_exists: true` в†’ С„Р°Р№Р» РєР°Рє РЅР° develop
- Push main `7ab6456c`; CodeQL Advanced main SUCCESS (ruby + js)

## 2026-09-18 вЂ” fix: CI Block F stock hard-fail test

- `BlockFStockFlowTest`: sale РїСЂРё РЅРµС…РІР°С‚РєРµ РѕСЃС‚Р°С‚РєР° в†’ 422 + stock unchanged (РЅРµ soft-negative QA 4.2)
- РЎРѕРіР»Р°СЃРѕРІР°РЅРѕ СЃ `Inventory::OrderRecipeDeduction` hard-fail
- Local: block_f + deduction 8 PASS

## 2026-09-18 вЂ” ci: Semgrep в†’ GitHub Code Scanning

- `.github/workflows/semgrep.yml`: p/ruby + p/javascript + p/rails в†’ SARIF в†’ `upload-sarif` (category semgrep)
- РђР»РµСЂС‚С‹: Security в†’ Code scanning (СЂСЏРґРѕРј СЃ CodeQL); Actions в†’ Semgrep

## 2026-09-18 вЂ” fix: CodeQL ReDoS + dismiss false positives

- ReDoS: `URI::MailTo::EMAIL_REGEXP` РІ email_otp / email_service / purchase / tbank_receipt; JS login_form Р±РµР· nested `+`
- Dismiss 13 alerts: CSRF callbacks/API (#2вЂ“#9, #15), test password (#14/#16), acceptance SSRF (#12), bank_card_id FP (#13)
- Open РґРѕ rescan: #1 / #10 / #11 (Р·Р°РєСЂРѕСЋС‚СЃСЏ РїРѕСЃР»Рµ CodeQL РЅР° push)
- Local: email_otp + receipt_builder 15 PASS

## 2026-09-18 вЂ” ci: CodeQL Advanced on develop + main (push)

- develop push `adae7af5`; main fix `fe1349a4` (СѓР±СЂР°РЅ broken manual if)
- РћРґРёРЅ workflow РЅР° РѕР±РµРёС… РІРµС‚РєР°С… вЂ” РЅРµ СѓРґР°Р»СЏС‚СЊ СЃ main (С‚СЂРёРіРіРµСЂС‹ develop+main)
- Languages: ruby + javascript-typescript; build-mode none

## 2026-09-18 вЂ” ci: CodeQL Advanced workflow (ruby + JS)

- `.github/workflows/codeql.yml`: develop+main; `javascript-typescript` + `ruby`; `build-mode: none`
- Р‘РµР· С€Р°РіР° manual if (Р»РѕРјР°Р» GH expression РЅР° `"manual"`)

## 2026-09-18 вЂ” fix: GetState Amount + inventory hard-fail + #78 cancel/confirm

- GetState CONFIRMED: `notification_amount_matches?` РґРѕ succeeded; blank Amount fail-closed
- Inventory: РЅРµРґРѕСЃС‚Р°С‚РѕС‡РЅРѕ РѕСЃС‚Р°С‚РєР° в†’ `OrderRecipeDeduction::Error` (РЅРµ clamp РІ 0)
- #78: `CancelService` + `ConfirmPaymentService` (GetState + PaymentFulfillment); Shop API РЅРµ 501
- Local: Rails 46+4 PASS В· JS CTA 17 PASS В· Fly MCP skip (РЅРµС‚ deploy)

## 2026-09-18 вЂ” fix: P0/P1 crits (tips, Tbank mismatch, FCM tenant, CallcheckГ—2, SMS HMAC)

- Tips CTA: default URL + same-tab fallback РєР°Рє chat (#94); FCM `action=tips` в†’ `openTipsService`
- Tbank amount mismatch: raise + release idempotency claim + HTTP 422 (РЅРµ silent OK)
- FCM payload `tenant_id`; SW cancel `?tenant_id=` + `X-Shop-Tenant`
- Callcheck Г—2 (80s) Р·Р°С‚РµРј SMS; SMS `/o/:hash` HMAC (РЅРµ reversible UUID)
- #78: subscription CTA СЃРєСЂС‹С‚ (501 stubs); Wallet CTA СЃРєСЂС‹С‚ Р±РµР· certs; Events Amount kopecks; stock clamp в‰Ґ0
- Local: JS 73+45 PASS В· Rails 82+25 PASS В· Fly MCP skip (РЅРµС‚ deploy)

## 2026-09-17 вЂ” docs: #82 РџР°С‚С‡_1 CI green after REVIEW

- CI green `35234267606` В· review sha `f0ccc4a5` В· Entire `01M2QWCCYY5P9QNJBJFBJSS6DK`
- Fly MCP Point A РїРѕСЃР»Рµ deploy Р°РїСЂСѓРІ

## 2026-09-17 вЂ” review: #82 РџР°С‚С‡_1 cascade Presence grace + SMS short link

- GREEN `9b087faf` В· FIX `3f6ac720`: `/o/:hash` bind guest session + `reconnect_token`
- Presence: `begin_sms_grace!` suppress Cable reconnect; Presence fail в†’ `retry_on`
- SMS: `codeblack.xyz/o/{order_hash}` в‰¤70 В· Entire `01M2QWCCYY5P9QNJBJFBJSS6DK`
- bugbot high (session) Р·Р°РєСЂС‹С‚ В· security medium+ РЅРµС‚ В· Local 36/0 В· push/CI
- Fly MCP Point A РїРѕСЃР»Рµ deploy Р°РїСЂСѓРІ

## 2026-09-17 вЂ” docs: sync ID Р·Р°РєР°Р·С‡РёРєР° (TASK_89 trio В· 90/91/92)

- РџСЂР°РІРёР»Рѕ: ID Р·Р°РєР°Р·С‡РёРєР° = РєР°РЅРѕРЅ (`coffeeos-customer-intake.mdc`); EXT = СЃСѓС„С„РёРєСЃ, РЅРµ РЅРѕРІС‹Р№ `#`
- CBR/ISSUES: TASK_89 + TASK_89-UI-EXT + TASK_89-POSTCALL-EXT; #90=TASK_90 В· #91=TASK_91 В· #92=TASK_92 (СЃРЅСЏС‚С‹ РѕС€РёР±РѕС‡РЅС‹Рµ #93/#94)
- РЁР°РїРєРё РўР— / artifacts / GATES / HANDOFF / SESSION / RULES_INDEX / index

## 2026-09-17 вЂ” docs: #71 РџР°С‚С‡_1 CI green after REVIEW

- CI green `35230879863` В· review sha `844a618a`
- Fly MCP Point A РїРѕСЃР»Рµ deploy Р°РїСЂСѓРІ

## 2026-09-17 вЂ” review: #71 РџР°С‚С‡_1 server email + security fix

- GREEN `55c34592` В· review fix `72d90862`: profile-first txn; `email_verified=false` РЅР° post-pay; linker РЅРµ switch РЅР° unverified squat
- bugbot high/medium + security medium Р·Р°РєСЂС‹С‚С‹
- Entire `01M2QSJ5WY9Q3A3MC6028SZBBV` РЅР° GREEN В· Local PASS В· push/CI
- Fly MCP Point A РїРѕСЃР»Рµ deploy Р°РїСЂСѓРІ

## 2026-09-17 вЂ” regress: #71 РџР°С‚С‡_1 server email PASS

- Local: `orders_email_test` 13/0 В· `email_collection_test` 21/0
- GREEN `55c34592` В· Entire `01M2QSJ5WY9Q3A3MC6028SZBBV` В· Next: `/review`
- Fly MCP Point A РїРѕСЃР»Рµ Review/deploy (hot-path РІРёС‚СЂРёРЅР°)

## 2026-09-17 вЂ” docs: /patch #71 РџР°С‚С‡_1 server email prefill

- РЎРµРєС†РёСЏ **РџР°С‚С‡_1** РІ TASK Email-СЃР±РѕСЂ (#71): СЂР°СЃС…РѕР¶РґРµРЅРёРµ OrderEmail-only vs MobileCustomer.email
- `todo.md` РЁР°Рі 5 РїРѕРґ РёС‚РµСЂР°С†РёСЋ: SBR/Р¤Р°Р№Р»С‹/РќРµ Р»РѕРјР°С‚СЊ/РџСЂРѕРІРµСЂРєР°/DoD
- Google: `1igng5OvrPOKMs5NkAZ8CAQYSufJBk3i3ZTI3bTgFLY8` В· Next: `/sbr`

## 2026-09-17 вЂ” docs: #94 CI green after REVIEW

- CI green `35198770223` В· review sha `97f4291b`
- G5 Fly MCP РїРѕСЃР»Рµ deploy Р°РїСЂСѓРІ

## 2026-09-17 вЂ” review: #94 TASK_92 background FCM + chat CTA

- GREEN `f274c11c`: FCM data-only + OrderStatus `openSupportChat`
- bugbot high в†’ fix `5da31ad0`: cold-start hash boot + openWindow postMessage
- security: no medium+
- Entire: `01M2Q5JKXMAXYVGWY68BZT431F` В· Local PASS В· push/CI
- G5 Fly MCP РїРѕСЃР»Рµ deploy

## 2026-09-17 вЂ” docs: unlazy reverify #94 G1вЂ“G4 met pre-review

- `GATES.md` G1 includes `fcm_client_test`; `--approve` + `--reverify` G1вЂ“G4 PASS
- G5 Fly MCP Point A still unmet (post-deploy)
- Next: `/review`

## 2026-09-17 вЂ” docs: #94 zone regress PASS

- `rails test fcm_client+notifier+payload` вЂ” 15 runs, 0 fail
- `node --test support_chat + push_subscribe` вЂ” 22 pass
- `push_pipeline_simulation` вЂ” 2 runs, 0 fail
- Next: `/review` В· Fly MCP G5 РїРѕСЃР»Рµ deploy

## 2026-09-17 вЂ” docs: update COMPONENT_MAP вЂ” PaymentResult / Checkout / CartSheet / OrderStatusSheet

- Р‘Р›РћРљ 4 #93: РЅРѕРІР°СЏ СЃС‚СЂРѕРєР° PaymentResult; С‚РѕС‡РµС‡РЅРѕ Checkout В· CartSheet В· cartSheetStore В· OrderStatusSheet В· orderStatusSheet.js
- Р“СЂР°РЅРёС†Р°: `maybeAutoReturnToCatalog` / `isCartSheetRoute` Р±РµР· `/payment-result` В· Р±РµР· РїСЂР°РІРєРё СЃС‚Р°С‚СѓСЃР° internals

## 2026-09-17 вЂ” docs: #93 CI green after REVIEW

- CI green `35196766203` В· review sha `45f459ea`
- G4 Fly MCP РїРѕСЃР»Рµ deploy Р°РїСЂСѓРІ

## 2026-09-17 вЂ” feat: #94 FCM data-only + chat CTA [GREEN]

- FcmClient: data-only (title/body in data) в†’ SW owns shade tag/actions
- OrderStatus chat в†’ `openSupportChat`; application.js `coffeeos_navigate`; SW `data.title`
- RED `20c05ba6` В· GREEN `f274c11c` В· Next: `/regress`

## 2026-09-17 вЂ” review: #93 TASK_91 post-pay auto return catalog

- GREEN `118e5488`: `maybeAutoReturnToCatalog` when `!askReceiptEmail`
- bugbot: no bugs В· security: no medium+
- Entire: `01M2Q4KBV30SBFMRTNDVP99HKM` (attach) В· Local zone PASS В· push/CI
- G4 Fly MCP РїРѕСЃР»Рµ deploy В· COMPONENT_MAP: РЅРµ С‚СЂРѕРіР°Р»Рё (РЅРµ РЅРѕРІР°СЏ СЃСѓС‰РЅРѕСЃС‚СЊ РєР°СЂС‚С‹)

## 2026-09-17 вЂ” docs: unlazy reverify #93 pre-review (G1вЂ“G3 met)

- Ledger: `artifacts/post_pay_auto_return_catalog_status/GATES.md` (session GATES = #94)
- `gate-check --reverify` G1вЂ“G3 PASS; G4 Fly MCP Point A still unmet (post-deploy)
- Next: `/review`

## 2026-09-17 вЂ” docs: SPEC #94 TASK_92 background FCM + chat CTA

- Gap: `FcmClient` notification+data в†’ SW РЅРµ РІР»Р°РґРµРµС‚ shade; OrderStatus chat в†’ dead `orderDeepLink`
- todo: 6 С„Р°Р№Р»РѕРІ В· РќРµ Р»РѕРјР°С‚СЊ В· РџСЂРѕРІРµСЂРєР° В· Next: `/sbr`

## 2026-09-17 вЂ” docs: #93 zone regress PASS

- `node --test email_collection_test.mjs` вЂ” 19 pass
- `rails test order_status_acceptance + sheet_mount` вЂ” 15 runs, 0 fail
- Next: `/review` В· Fly MCP G4 РїРѕСЃР»Рµ deploy

## 2026-09-17 вЂ” docs: unlazy GATES #94 TASK_92 background FCM

- `GATES.md` в†’ #94 baseline; gate-check `--approve` G1вЂ“G4 PASS; G5 Fly MCP pending
- Р—РѕРЅР°: notifier/payload В· support_chat В· push_subscribe В· push_pipeline
- Next: `/spec`

## 2026-09-17 вЂ” docs: intake #94 TASK_92 production background FCM

- Р§Р°С‚ Р·Р°РєР°Р·С‡РёРєР° + Google Doc MCP в†’ `customer_tasks/TASK-92-вЂ¦md` (1:1)
- artifacts `production_background_fcm_status_sync/`; CBR #94 (CBR #92 = WebPush recovery)
- Gaps: Рї.1 С„РѕРЅРѕРІС‹Рµ FCM; С‡Р°С‚ CTA РїРѕРєР°Р·С‹РІР°РµС‚СЃСЏ, РєР»РёРє РЅРµС‚ В· Next: `go` в†’ `/spec`

## 2026-09-17 вЂ” docs: SPEC #93 TASK_91 post-pay auto return catalog

- Gap: success Р±РµР· email-Р±Р»РѕРєР° (`!askReceiptEmail`) вЂ” С‚РѕР»СЊРєРѕ В«Р’ РєР°С‚Р°Р»РѕРіВ»; submit/Skip СѓР¶Рµ `push("/")`
- todo: 3 С„Р°Р№Р»Р° В· РќРµ Р»РѕРјР°С‚СЊ В· РџСЂРѕРІРµСЂРєР° В· Next: `/sbr`

## 2026-09-17 вЂ” docs: unlazy GATES #93 + customer screenshots

- screenshots `01`вЂ“`03` в†’ `artifacts/post_pay_auto_return_catalog_status/screenshots/`
- `GATES.md` в†’ #93 baseline; `gate-check --approve` G1вЂ“G3 PASS; G4 Fly MCP pending
- todo: СЃСЃС‹Р»РєР° GATES В· Next: `/spec`

## 2026-09-17 вЂ” docs: intake #93 TASK_91 post-pay auto return catalog

- Р§Р°С‚ Рї.9.2 + СЃРєСЂРёРЅС‹ + Google Doc в†’ `customer_tasks/TASK-91-вЂ¦md` (1:1)
- artifacts `post_pay_auto_return_catalog_status/` (РїРѕРґРїРёСЃРё СЃРєСЂРёРЅРѕРІ; PNG СЃ РґРёСЃРєР° РЅРµ РЅР°Р№РґРµРЅС‹)
- Google TASK_91 в†’ CBR #93 (#91 Р·Р°РЅСЏС‚ UI-EXT); todo в†’ #93 В· Next: `/spec`

## 2026-09-17 вЂ” docs: update COMPONENT_MAP вЂ” ActiveOrdersAccordion / orderStatusNotifyActions / firebasePush

- Р‘Р›РћРљ 4 #92: С‚РѕС‡РµС‡РЅРѕ ActiveOrdersAccordion В· orderStatusNotifyActions; РЅРѕРІР°СЏ СЃС‚СЂРѕРєР° firebasePush
- Р“СЂР°РЅРёС†Р°: recovery UI / openNotificationSettings В· Р±РµР· #83/#84 В· Р±РµР· register token

## 2026-09-17 вЂ” review: #92 TASK_90 WebPush recovery after denied

- GREEN `0b7f0b2d`: recovery UI + fallback + dismissPushRecovery
- bugbot medium в†’ fix `72dcb5e9`: Android intent always shows fallback
- security: no medium+
- Entire: `01M2Q1AF4E2PWDD5JW1FZPRPF1` РЅР° GREEN+fix
- Local zone PASS В· CI green `35191890272` В· G5 Fly MCP РїРѕСЃР»Рµ deploy
- COMPONENT_MAP: РЅРµ С‚СЂРѕРіР°Р»Рё (РЅРµ РЅРѕРІР°СЏ СЃСѓС‰РЅРѕСЃС‚СЊ РєР°СЂС‚С‹)

## 2026-09-17 вЂ” docs: unlazy reverify #92 pre-review (G1вЂ“G4 met)

- `gate-check --reverify` G1вЂ“G4 PASS; G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-17 вЂ” docs: #92 zone regress PASS (WebPush denied recovery)

- node: push_subscribe + notify + accordion вЂ” 52 pass
- rails: order_status acceptance + sheet_mount вЂ” 15 runs / 139 assert / 0 fail
- unlazy `--reverify` G1вЂ“G4 PASS В· G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-17 вЂ” docs: SPEC #92 TASK_90 WebPush recovery after denied

- todo: recovery UI + deep-link/fallback `denied в†’ settings`
- Р¤Р°Р№Р»С‹: orderStatusNotifyActions + ActiveOrdersAccordion + firebasePush(?) + 2 С‚РµСЃС‚Р°
- РќРµ Р»РѕРјР°С‚СЊ: РѕРїР»Р°С‚Р° В· #83/#84 В· Wallet/OrderStatus В· backend push/SW

## 2026-09-17 вЂ” docs: unlazy GATES #92 WebPush recovery after denied

- Ledger `session/GATES.md` В· baseline pre-SPEC
- G1вЂ“G4 PASS (push subscribe В· notify actions В· accordion В· order_status rails)
- G5 Fly MCP Point A unmet (РїРѕСЃР»Рµ REVIEW/deploy)
- todo в†’ #92 В· Next: `/spec`

## 2026-09-17 вЂ” docs: intake #92 TASK_90 WebPush recovery after denied

- Р§Р°С‚ Рї.9/9.1 + Google Doc в†’ `customer_tasks/TASK-90-вЂ¦md` (1:1)
- artifacts `webpush_recovery_after_denied/` В· CBR #92 В· ISSUES В· todo
- Google TASK_90 в†’ CBR #92 (#90 Р·Р°РЅСЏС‚ POSTCALL); EXT #81 deniedв†’settings
- Next: `/spec`

## 2026-09-17 вЂ” docs: update COMPONENT_MAP вЂ” PhoneAuth / Checkout / PaymentMethodsSheet

- Р‘Р›РћРљ 4 #90: РЅРѕРІС‹Рµ СЃС‚СЂРѕРєРё PhoneAuthWizard В· PhoneAuthCodeStep В· phoneAuthCascade В· Checkout В· PaymentMethodsSheet
- Р“СЂР°РЅРёС†Р°: resume Р±РµР· re-init В· Р°РІС‚Рѕ-open pay sheet РёР· Checkout

## 2026-09-16 вЂ” fix: CI flake Rails.env pollution (payment_config_test)

- `define_method(:env)` Р»РѕРјР°Р» stub production РІ callbacks test в†’ 200 РІРјРµСЃС‚Рѕ 401
- CI green `35119243465` РїРѕСЃР»Рµ `db6cba85`

## 2026-09-16 вЂ” review: #90 POSTCALL-EXT return after Callcheck

- GREEN `37b808c4`: resume poll + copy В«РІРµСЂРЅРёС‚РµСЃСЊВ» + pagehide/iOS + checking UI
- bugbot: no bugs В· security: no medium+
- Entire: `01M2NCXMN67QF5CB228K6HCT97` РЅР° GREEN
- Local zone PASS В· CI green `35116445356` В· G5 Fly MCP РїРѕСЃР»Рµ deploy
- COMPONENT_MAP: РЅРµ С‚СЂРѕРіР°Р»Рё (РЅРµ РЅРѕРІР°СЏ СЃСѓС‰РЅРѕСЃС‚СЊ РєР°СЂС‚С‹)

## 2026-09-16 вЂ” docs: unlazy reverify #90 pre-review (G1вЂ“G4 met)

- `gate-check --reverify` G1вЂ“G4 PASS; G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-16 вЂ” docs: #90 zone regress PASS (shop auth / Callcheck return)

- rails: auth_funnel + silent_refresh + phone_otp + linker вЂ” 27 runs / 211 assert / 0 fail
- node: wizard + cascade + otp_ui вЂ” 27 pass
- unlazy `--reverify` G1вЂ“G4 PASS В· G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-16 вЂ” docs: SPEC #90 POSTCALL-EXT restart

- todo: lifecycle return Callcheck в†’ resume в†’ PaymentMethodsSheet
- Р¤Р°Р№Р»С‹: phoneAuthCascade + PhoneAuthCodeStep + Wizard + 3 С‚РµСЃС‚Р°
- РќРµ Р»РѕРјР°С‚СЊ: #89 linker/session В· #91 UI-EXT В· FlashCall В· CartSheet

## 2026-09-16 вЂ” docs: unlazy GATES #90 POSTCALL-EXT restart

- Ledger `session/GATES.md` В· restart РїРѕСЃР»Рµ rollback
- G1вЂ“G4 PASS (cascade/wizard В· structural+auth funnel В· phone_otp/linker В· otp_ui)
- G5 Fly MCP Point A unmet (РїРѕСЃР»Рµ REVIEW/deploy)
- todo в†’ #90 В· Next: `/spec`

## 2026-09-16 вЂ” docs: RU title С‡Р°С‚РѕРІ (agent-workflow)

- РЎС‚Р°СЂС‚ С‡Р°С‚Р° Рї.5: `rename_chat` в†’ `Р—Р°РґР°С‡Р° N вЂ” РєСЂР°С‚РєРѕ` (в‰¤60)
- Р‘РµР· РЅРѕРІРѕРіРѕ always-С„Р°Р№Р»Р° вЂ” С‚РѕР»СЊРєРѕ СЃС‚СЂРѕРєР° РІ СѓР¶Рµ loaded workflow + index/RULES_INDEX

## 2026-09-16 вЂ” review: #91 TASK_89-UI-EXT phone input UI/UX

- GREEN `8c267e56`: slim sheet 8vh В· hide CTA+cart РЅР° phone-auth
- bugbot: no bugs В· security: no medium+
- Entire: `01M2N8XBEJ7JRD7T89JT4DAHS8` РЅР° GREEN
- Local zone PASS В· CI green `35108357982` В· G5 Fly MCP РїРѕСЃР»Рµ deploy
- COMPONENT_MAP: РЅРµ С‚СЂРѕРіР°Р»Рё (РЅРµ РЅРѕРІР°СЏ СЃСѓС‰РЅРѕСЃС‚СЊ РєР°СЂС‚С‹)

## 2026-09-16 вЂ” docs: unlazy reverify #91 pre-review (G1вЂ“G4 met)

- `gate-check --reverify` G1вЂ“G4 PASS; G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-16 вЂ” docs: #91 zone regress PASS (phone-auth UI / cart sheet)

- node: webview + wizard + otp_ui + cascade вЂ” 39 pass
- rails: cart_sheet_ux + auth_funnel + checkout_ui_cleanup вЂ” 13 runs / 247 assert / 0 fail
- unlazy `--reverify` G1вЂ“G4 PASS В· G5 Fly MCP Point A still unmet (post-deploy)
- Hot-path Fly MCP Point A (G5) вЂ” РµС‰С‘ РЅСѓР¶РµРЅ РїРѕСЃР»Рµ deploy

## 2026-09-16 вЂ” docs: SPEC #91 TASK_89-UI-EXT phone input UI/UX

- todo: phone-auth в†’ СЃРєСЂС‹С‚СЊ CTA+cart В· thinner sheet
- Р¤Р°Р№Р»С‹: Checkout В· cartSheetStore В· shopWebViewLayout В· cartSheetThresholds В· CartSheet (+2 С‚РµСЃС‚Р°)
- РќРµ Р»РѕРјР°С‚СЊ: #89 В· CTA РІРЅРµ auth В· keyboard path В· #90

## 2026-09-16 вЂ” docs: unlazy GATES #91 UI-EXT baseline

- Ledger `session/GATES.md` В· G1вЂ“G4 PASS (phone auth UI / cart sheet / auth funnel / cascade)
- G5 Fly MCP Point A unmet (РїРѕСЃР»Рµ REVIEW/deploy)
- RED РµС‰С‘ РґРѕР±Р°РІРёС‚ CTA/cart hide asserts

## 2026-09-16 вЂ” docs: intake #91 TASK_89-UI-EXT phone input UI/UX

- Р§Р°С‚ + Google Doc в†’ `customer_tasks/TASK-89-UI-EXT-вЂ¦md` (1:1)
- artifacts `pwa_auth_phone_input_ui_ux/` В· CBR #91 В· README В· ISSUES В· todo
- Scope: phone-auth СЃРєСЂС‹С‚СЊ CTA СЃСѓРјРјС‹ + cart preview В· С‚РѕРЅСЊС€Рµ sheet; Р¶РґС‘С‚ `/spec`

## 2026-09-16 вЂ” revert: #90 POSTCALL-EXT full rollback (wrong order)

- РљРѕРґ СЃРЅСЏС‚: `PhoneAuthCodeStep` / `phoneAuthCascade` / С‚РµСЃС‚С‹ #90 в†’ pre-RED
- РџСЂРёС‡РёРЅР°: POSTCALL СЂР°РЅСЊС€Рµ UI-EXT В· СЃР»РѕРјР°Р»Рё РѕС‡РµСЂС‘РґРЅРѕСЃС‚СЊ В· РґРІР° С‡Р°С‚Р° РЅР° РѕРґРЅСѓ Р·Р°РґР°С‡Сѓ
- РўР—/intake #90 СЃРѕС…СЂР°РЅРµРЅС‹ В· СЃС‚Р°С‚СѓСЃ ROLLED BACK В· Р·Р°РЅРѕРІРѕ РїРѕСЃР»Рµ UI-EXT
- #89 РЅРµ С‚СЂРѕРіР°Р»Рё В· СЃРєСЂРёРЅ С€С‚РѕСЂРєРё РІ #89 artifacts РѕСЃС‚Р°С‘С‚СЃСЏ

## 2026-09-16 вЂ” review: #90 POSTCALL-EXT return after Callcheck

- GREEN `4932e2b0` + fix iOS tel resume `0588ead1` (pagehide / markLeftForDial / focus)
- bugbot: high iOS skip в†’ fixed В· security: no medium+
- Entire: `01M2N01DRZ1TPY8WCNKRE80R5V` РЅР° GREEN/fix
- Local zone PASS В· CI green `35094780266` В· G5 Fly MCP РїРѕСЃР»Рµ deploy
- COMPONENT_MAP: РЅРµ С‚СЂРѕРіР°Р»Рё (РЅРµ РіР»Р°РІРЅР°СЏ Р·РѕРЅР° РєР°СЂС‚С‹)

## 2026-09-16 вЂ” docs: #89 artifact вЂ” curtain sum keyboard screenshot

- `pwa_auth_registration_callcheck_sms/screenshots/01_phone_input_curtain_sum_keyboard_2026-09-16.png`
- Р·Р°РєР°Р·С‡РёРє: С‚РѕР»С‰РёРЅР° С€С‚РѕСЂРєРё / РІРёРґРёРјРѕСЃС‚СЊ СЃСѓРјРјС‹ (TASK_89-UI-EXT; OUT #90)

## 2026-09-16 вЂ” docs: unlazy reverify #90 pre-review (G1вЂ“G4 met)

- `gate-check --reverify` G1вЂ“G4 PASS; G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-16 вЂ” docs: #90 zone regress PASS (shop auth / Callcheck return)

- rails: auth_funnel + silent_refresh + phone_otp + linker вЂ” 26 runs / 0 fail
- node: wizard + cascade + otp_ui вЂ” 27 pass
- unlazy `--reverify` G1вЂ“G4 PASS В· G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-16 вЂ” docs: SPEC #90 POSTCALL-EXT

- todo: lifecycle return Callcheck в†’ resume в†’ PaymentMethodsSheet
- Р¤Р°Р№Р»С‹: phoneAuthCascade + PhoneAuthCodeStep + Wizard + 3 С‚РµСЃС‚Р°
- РќРµ Р»РѕРјР°С‚СЊ: #89 linker/session В· UI-EXT В· FlashCall В· CartSheet

## 2026-09-16 вЂ” docs: unlazy GATES #90 POSTCALL-EXT

- Ledger `session/GATES.md` В· approve G1вЂ“G4 PASS (baseline #89 zone)
- G5 Fly MCP Point A unmet (РїРѕСЃР»Рµ REVIEW/deploy)
- RED РµС‰С‘ РґРѕР±Р°РІРёС‚ lifecycle asserts (return в‰  init_callcheck)

## 2026-09-16 вЂ” docs: intake #90 TASK_89-POSTCALL-EXT

- Google Doc в†’ `customer_tasks/TASK-89-POSTCALL-EXT-вЂ¦md` (1:1)
- artifacts `pwa_callcheck_return_continue_payment/` В· CBR #90 В· README В· ISSUES
- EXT #89: return РїРѕСЃР»Рµ Callcheck в†’ resume в†’ PaymentMethodsSheet; Р¶РґС‘С‚ `/spec`

## 2026-09-16 вЂ” review: #89 post-Callcheck в†’ payment sheet

- GREEN `84490e04`: `onWizardVerified` в†’ `openPaymentSheet` РїРѕСЃР»Рµ Callcheck/SMS
- bugbot: no bugs В· security: no medium+ (#89 Checkout scope)
- Entire: `01M2MSDK9ZMPZH7YDZ17GHM44B` РЅР° `84490e04`
- Local zone PASS В· CI green `35082473762` В· G5 Fly MCP РїРѕСЃР»Рµ deploy
- COMPONENT_MAP: РЅРµ С‚СЂРѕРіР°Р»Рё (РЅРµ РіР»Р°РІРЅР°СЏ Р·РѕРЅР° РєР°СЂС‚С‹)

## 2026-09-16 вЂ” docs: unlazy reverify #89 pre-review (G1вЂ“G4 met)

- `gate-check --reverify` G1вЂ“G4 PASS; G5 Fly MCP Point A still unmet (post-deploy)

## 2026-09-16 вЂ” docs: #89 zone regress PASS (shop auth / OTP)

- rails: phone_otp + linker + silent_refresh + auth_funnel вЂ” 33 runs / 0 fail
- node: phone_auth wizard/cascade/ui вЂ” 23 pass
- Hot-path Fly MCP Point A (G5) вЂ” РµС‰С‘ РЅСѓР¶РµРЅ РїРѕСЃР»Рµ deploy

## 2026-09-16 вЂ” docs: SPEC #89 post-Callcheck в†’ payment sheet

- `todo.md` #89: `onWizardVerified` в†’ `openPaymentSheet`; С„Р°Р№Р»С‹ Checkout + structural/OTP tests
- OUT: FlashCall, С‚РѕР»С‰РёРЅР° С€С‚РѕСЂРєРё, РєР°СЃРєР°РґГ—2 #80

## 2026-09-16 вЂ” docs: unlazy GATES #89 PWA auth Callcheck в†’ SMS

- `session/GATES.md` в†’ #89 (G1вЂ“G4 baseline PASS, G5 Fly MCP pending)
- Scope: Callcheck/SMS в†’ session в†’ checkout + СЌРєСЂР°РЅ РѕРїР»Р°С‚С‹; FlashCall guard

## 2026-09-16 вЂ” docs: intake customer task #89 PWA auth Callcheck в†’ SMS

- `TASK-89-РђРІС‚РѕСЂРёР·Р°С†РёСЏ-СЂРµРіРёСЃС‚СЂР°С†РёСЏ-PWA-Callcheck-SMS.md` + artifacts `pwa_auth_registration_callcheck_sms/`
- CBR / customer_tasks README / ISSUES #89
- Р§Р°С‚: post-call в†’ PWA + СЌРєСЂР°РЅ РѕРїР»Р°С‚С‹; overlap #80

## 2026-09-16 вЂ” fix: security backlog (Tbank Amount, promo used_count, token, callbacks throttle)

- T-Bank: `TbankAdapter.notification_amount_matches?` (РєРѕРїРµР№РєРё) + guard РІ `TbankCallbackJob` РЅР° CONFIRMED/succeeded
- Barista: `increment_usage!` РІ С‚СЂР°РЅР·Р°РєС†РёРё Р·Р°РєР°Р·Р° РїСЂРё `discount_amount > 0`; max_uses РґРµСЂР¶РёС‚СЃСЏ
- `EventsController`: `X-Callback-Token` С‡РµСЂРµР· `secure_compare` (+ РґР»РёРЅР°)
- Rack::Attack: throttle POST `/callbacks/*` РїРѕ IP (MemoryStore; shared вЂ” follow-up)
- Local: tbank job/adapter + barista promo + events + tbank controller **76/76 PASS**

## 2026-09-16 вЂ” fix: barista promo UI + DEMO_AUTO_SEED off + push

- Barista POS: СѓР±СЂР°РЅР° С„РµР№РєРѕРІР°СЏ РєР»РёРµРЅС‚СЃРєР°СЏ в€’10%; СЃРєРёРґРєР° С‚РѕР»СЊРєРѕ С‡РµСЂРµР· `PromoCode` РЅР° СЃРµСЂРІРµСЂРµ
- `fly.toml`: `DEMO_AUTO_SEED=false` (РїСѓР±Р»РёС‡РЅС‹Р№ fly.dev Р±РѕР»СЊС€Рµ РЅРµ РїРµСЂРµСЃРёРґРёС‚ `demo123456` РЅР° РєР°Р¶РґС‹Р№ deploy)
- Push `develop` вЂ” Grok/remote РІРёРґСЏС‚ `488551aa` + СЌС‚РѕС‚ РєРѕРјРјРёС‚
- Deploy: Р°РїСЂСѓРІ В· РґРѕ РІС‹РєР°С‚Р° РїСЂРѕРІРµСЂРёС‚СЊ `CALLBACK_SHARED_*` РЅР° Fly

## 2026-09-16 вЂ” fix: security P0/P1 (Grok review вЂ” callbacks, cart modifiers, staff login)

- P0: `Callbacks::EventsController` вЂ” РІ **production** Р±РµР· `CALLBACK_SHARED_TOKEN` + `CALLBACK_SHARED_SECRET` в†’ **401** (РєР°Рє email bounce)
- P1: shop cart/modifiers вЂ” С‚РѕР»СЊРєРѕ **id** РёР· Р‘Р”, РєР»РёРµРЅС‚СЃРєРёР№ `price` Р±РµР· id РѕС‚РєР»РѕРЅСЏРµС‚СЃСЏ
- P1: `Auth::SessionsController#create` вЂ” `reset_session` РґРѕ Р·Р°РїРѕР»РЅРµРЅРёСЏ СЃРµСЃСЃРёРё (session fixation)
- Deploy: РЅР° Fly СЃРµРєСЂРµС‚С‹ callbacks РґРѕР»Р¶РЅС‹ Р±С‹С‚СЊ Р·Р°РґР°РЅС‹ **РґРѕ** РІС‹РєР°С‚Р°, РёРЅР°С‡Рµ Р»РµРіРёС‚РёРјРЅС‹Рµ РєРѕР»Р±СЌРєРё СѓРїР°РґСѓС‚
- Local: events_controller + auth sessions + cart/modifier + callbacks_e2e **71/71 PASS**

## 2026-09-16 вЂ” fix: security catch-up OTP unlock / widget step-up / API key fallback

- HIGH: `binding_step_up` unlock only if lock existed **before** `link!` (no same-request bypass)
- MEDIUM: `widget_init` enforces `BindingStepUp` like `one_click`
- MEDIUM ops: `SHOP_API_KEY_FALLBACK` **opt-in** (`=1`); default off after per-tenant seed
- also: `BindingStepUp` lock on empty Hash session (`nil?` not `blank?`)
- Local: binding_step_up + api_key_authenticator + phone_otp + widget_init **32/32 PASS**

## 2026-09-15 вЂ” fix: Sentry RUBY-1K category sort_order NotNull

- `Platform::MenuController#update_category`: `normalized_category_attrs` вЂ” blank keep / 0 append
- test `menu_category_sort_order_update_test` В· Fixes RUBY-1K

## 2026-09-15 вЂ” feat: #87 REVIEW вЂ” Quick Repeat clear cart after pay (push)

- Local PASS В· manual bugbot+security (Task usage limit) В· no blocker
- Entire `01M2JVMYKV47VGQ1SCRBC5V77R` РЅР° `06dca7c3`
- **CI green** run `34991136715`
- clear only on `confirmed` В· DELETE `/cart` session В· receipt = Order interactive:false
- Fly MCP G4 / deploy вЂ” С‚РѕР»СЊРєРѕ Р°РїСЂСѓРІ

## 2026-09-15 вЂ” test: #87 regress PASS (Quick Repeat status zone)

- node: 33 pass (`create_repeat` + `order_status_sheet` + `clear_cart_after_pay`)
- rails: 18 runs / 0 fail (one-click + cart/status stack + active_orders + receipt)
- next: `/review` В· Fly MCP Point A РµС‰С‘ РЅСѓР¶РµРЅ РґР»СЏ Р·Р°РєР°Р·С‡РёРєР°

## 2026-09-15 вЂ” feat: #87 clear cart after Quick Repeat pay [GREEN]

- `clearCartAfterSuccessfulPay` + wire РІ `widgetRepeatPayFlow` РЅР° `confirmed`
- 7.1: leftover cart РЅРµ РІРёСЃРёС‚ РїРѕРґ status; receipt = Order (`interactive: false`)
- G1вЂ“G3 met В· Entire `01M2JVMYKV47VGQ1SCRBC5V77R` РЅР° `06dca7c3` В· next `/regress`

## 2026-09-15 вЂ” docs: #87 SPEC вЂ” Quick Repeat status composition

- `todo.md`: SBR В· 6 РїСѓС‚РµР№ В· blast-radius В· РќРµ Р»РѕРјР°С‚СЊ В· РџСЂРѕРІРµСЂРєР° (node + rails zone)
- Р¤РѕРєСѓСЃ 7.1: post card autopay вЂ” status Р±РµР· РёРЅС‚РµСЂР°РєС‚РёРІРЅРѕР№ РєРѕСЂР·РёРЅС‹; СЃРѕСЃС‚Р°РІ РёР· Order
- stop РґРѕ `/sbr` RED

## 2026-09-15 вЂ” docs: #87 unlazy GATES ledger (baseline)

- `session/GATES.md`: G1 node unit В· G2 active_orders/receipt В· G3 quick_repeat+cart stack вЂ” **met**; G4 Fly MCP вЂ” pending
- Baseline РґРѕ `/spec` / RED; РїРѕСЃР»Рµ GREEN вЂ” `--reverify`; G4 РЅР° Review

## 2026-09-15 вЂ” docs: intake #87 Quick Repeat status composition

- `TASK-87-Quick-Repeat-status-model-composition.md` вЂ” Google Doc Spec 1:1 + РїСЂР°РІРєР° 7.1 (cart block after card autopay)
- artifacts `quick_repeat_status_model_composition/` В· СЃРєСЂРёРЅ `01_status_after_card_autopay_cart_block.png`
- CBR #87 В· ISSUES В· stop РґРѕ `/spec`

## 2026-09-15 вЂ” feat: #86 REVIEW вЂ” SBP PWA recovery (push)

- GREEN `recoverPendingPayment` + pageshow; regress PASS; Entire `01M2JSNRNQCYGRZ6BCSXFTSG4A`
- Task bugbot/security: usage limit в†’ manual review #86 (no blocker)
- **CI green** run `34987062132` В· device Android/iOS + Fly MCP Point A вЂ” РїРѕСЃР»Рµ deploy Р°РїСЂСѓРІР°

## 2026-09-15 вЂ” test: #86 regress PASS (SBP PWA recovery zone)

- node: 37 pass (`codeblack_pending_order` + `shop_sbp_pay`)
- rails: 10 runs / 0 fail (`sbp_payment_return_ui` + `sbp_payment_ui`)
- next: `/review` В· Fly MCP Point A РµС‰С‘ РЅСѓР¶РµРЅ РґР»СЏ Р·Р°РєР°Р·С‡РёРєР°

## 2026-09-15 вЂ” docs: #86 unlazy GATES ledger (baseline)

- `session/GATES.md`: G1 node unit В· G2 rails SBP UI вЂ” **met**; G3 Fly MCP В· G4/G5 device вЂ” pending
- Baseline РґРѕ RED; РїРѕСЃР»Рµ GREEN вЂ” `--reverify`; G3вЂ“G5 РЅР° Review/device

## 2026-09-15 вЂ” docs: #86 SPEC вЂ” SBP PWA recovery after bank

- `todo.md`: SBR С„Р°Р·С‹ В· 7 РїСѓС‚РµР№ В· РќРµ Р»РѕРјР°С‚СЊ В· РџСЂРѕРІРµСЂРєР° (node + rails SBP return UI)
- OUT: #79 РЅР°РґРїРёСЃРё/11В·8 В· SMS в†’ РєР°СЃРєР°Рґ
- stop РґРѕ `/sbr` RED

## 2026-09-15 вЂ” docs: intake #86 SBP PWA recovery after bank (EXT)

- `TASK-86-Р’РѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРёРµ PWA РїРѕСЃР»Рµ РѕРїР»Р°С‚С‹ РЎР‘Рџ-EXT.md` вЂ” РїСЂР°РІРєРё Р·Р°РєР°Р·С‡РёРєР° 1:1 + Spec РёР· Google Doc
- artifacts `sbp_pwa_recovery_after_bank_ext/` В· CBR/README/ISSUES В· #79 split (recovery в†’ #86; SMS в†’ РєР°СЃРєР°Рґ OUT)
- todo stub В· stop РґРѕ `/spec`

## 2026-09-15 вЂ” docs: #26 РџР°С‚С‡ 1 вЂ” Subtask 5 HTTP 422 + error_code

- РЎРµРєС†РёСЏ **РџР°С‚С‡ 1** РІ РўР— invalid-token BottomSheet: Р±РёР·РЅРµСЃ-РѕС€РёР±РєР° T-Bank = `422` + `error_code` (РЅРµ `400`)
- `todo.md` РїРѕРґ РёС‚РµСЂР°С†РёСЋ РїР°С‚С‡Р°; РєРѕРґ/FSM/UI РЅРµ С‚СЂРѕРіР°Р»Рё
- РўРµРєСЃС‚С‹ РїРѕ `error_code` в†’ РѕС‚РґРµР»СЊРЅРѕ TASK_85

## 2026-09-14 вЂ” docs: COMPONENT_MAP вЂ” РЎРІСЏР·Рё orderStatusSheet.js

- В«РЎРІСЏР·РёВ»: OrderStatusSheet, CartSheet (РЅРµ РјРµС‚Р°РґР°РЅРЅС‹Рµ Р·Р°РґР°С‡Рё)
- РІР»Р°РґРµРЅРёРµ #84 РѕСЃС‚Р°С‘С‚СЃСЏ РІ В«РќРµ С‚СЂРѕРіР°С‚СЊ Р±РµР· РїРѕРјРµС‚РєРёВ»

## 2026-09-14 вЂ” chore: /patch thin layer (task patch / EXT)

- РљР°РЅРѕРЅ `docs/operations/dev/TASK_PATCH.md`
- On-demand `coffeeos-task-patch.mdc` В· РєРѕРјР°РЅРґР° `/patch`
- РРЅРґРµРєСЃС‹: coffeeos-index В· RULES_INDEX В· commands/README В· agent-workflow
- COMPONENT_MAP Р‘Р›РћРљ 4 в†’ СЃСЃС‹Р»РєР° РЅР° TASK_PATCH В§ С€Р°Рі 6

## 2026-09-14 вЂ” docs: COMPONENT_MAP вЂ” РќР°Р·РЅР°С‡РµРЅРёРµ orderStatusSheet.js

- В«РќР°Р·РЅР°С‡РµРЅРёРµВ»: РѕРїРёСЃР°РЅРёРµ С„Р°Р№Р»Р° (peek/hidden/dismiss/poll/cable), РЅРµ РёРјСЏ Р·Р°РґР°С‡Рё #83

## 2026-09-14 вЂ” docs: fix COMPONENT_MAP Р‘Р›РћРљ 4 (С„РёРґР±РµРє)

- ActiveOrdersAccordion: РІРµСЂРЅСѓР»Рё Р¤Р°Р№Р»/РќР°Р·РЅР°С‡РµРЅРёРµ; В«РќРµ С‚СЂРѕРіР°С‚СЊВ» = #83 + #84
- activeOrdersAccordion.js / orderStatusNotifyActions.js: Р·Р°РєСЂС‹Р»Рё В«РґС‹СЂС‹В» С„Р°РєС‚РѕРј #84
- orderStatusSheet.js: Р±РµР· РёР·РјРµРЅРµРЅРёР№ (#83 СѓР¶Рµ РІ PR)
- В«РР·РІРµСЃС‚РЅС‹Рµ РґС‹СЂС‹В»: СѓР±СЂР°РЅС‹ С‡РµРє Рё РєСЂРµСЃС‚РёРє; РѕСЃС‚Р°РІР»РµРЅ С„Р°РєС‚ ActiveOrdersPresenter

## 2026-09-14 вЂ” chore: install unlazy Solo overlay (CoffeeOS)

- Vendor: `npx skills add Leonxlnx/unlazy` в†’ `.agents/skills/unlazy/` В· pin `skills-lock.json`
- Thin `/unlazy` skill+command В· on-demand `coffeeos-unlazy.mdc` В· template + smoke
- Smoke G1 **ALL MET** (`gate-check --approve` / `--reverify`)
- Р‘РµР· Stop-hook / Depth Tree РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ (С‚РѕРєРµРЅС‹)

## 2026-09-13 вЂ” docs: update COMPONENT_MAP вЂ” ActiveOrdersAccordion

- Р‘Р›РћРљ 4 #84: РІР»Р°РґРµРЅРёРµ С‡РµРє/CTA; РѕР±С‰РёР№ С„Р°Р№Р» СЃ dismiss; `aoa__dismiss` РЅРµ С‚СЂРѕРіР°С‚СЊ

## 2026-09-13 вЂ” feat: TASK_84 status sheet receipt restore [REVIEW]

- Restore `receiptView` + CTA В«РЎРѕСЃС‚Р°РІ Р·Р°РєР°Р·Р°В» (`openOrderReceipt`) РІ `ActiveOrdersAccordion`
- Reverse QA no-receipt; dismiss / `orderStatusSheet` РЅРµ С‚СЂРѕРіР°Р»Рё
- TDD REDв†’GREEN В· regress **58/58 PASS**
- Entire `01M2D8PZAPT8XDC2KY95GFCFVN` РЅР° GREEN `a695ff08`
- bugbot/security: **usage blocked** В· push В· **CI green** `34755030736`

## 2026-09-13 вЂ” test: TASK_84 status sheet receipt restore [regress]

- Р—РѕРЅР°: PWA status sheet / ActiveOrdersAccordion
- `node --test` accordion **21/21** + notify/sheet **37/37** В· **58/58 PASS**
- Р–РґС‘С‚ `/review` В· Fly MCP Point A РїРѕСЃР»Рµ deploy

## 2026-09-13 вЂ” docs: SPEC TASK_84 status sheet receipt restore

- `todo.md` в†’ #84 В· 3 РїСѓС‚Рё + use-only `activeOrdersAccordion.js`
- РќРµ Р»РѕРјР°С‚СЊ: dismiss #83 В· `orderStatusSheet` В· pay-path В· `receiptView` impl
- РџСЂРѕРІРµСЂРєР°: `node --test` accordion + notify/sheet regress
- Р–РґС‘С‚ `/sbr`

## 2026-09-13 вЂ” docs: intake TASK_84 status sheet receipt restore

- РўР— 1:1: `customer_tasks/TASK-84-status-sheet-receipt-restore.md` (Google Doc)
- CBR #84 + `customer_tasks/README` В· artifacts `status_sheet_receipt_restore/`
- Scope: РІРµСЂРЅСѓС‚СЊ С‡РµРє + CTA В«РЎРѕСЃС‚Р°РІ Р·Р°РєР°Р·Р°В»; OUT dismiss / `orderStatusSheet`
- Р–РґС‘С‚ `/spec`

## 2026-09-13 вЂ” feat: TASK_83 status sheet dismiss contract [REVIEW]

- `DISMISS_CONTRACT` РІ `orderStatusSheet.js` (local Г—; Cable keep; no reload persist)
- TDD: `#83` suite + `aoa__dismiss` assert В· regress **37/37 PASS**
- Entire `01M2D37YG7XPHV6CV978P0MXBN` РЅР° GREEN `a2f323b0`
- bugbot/security: **usage blocked** В· push В· **CI green** `34751138556`
- lint follow-up: rubocop Layout РІ `bin/acceptance/v3_sec_post_deploy_mcp.rb` (`366730dc`)
- COMPONENT_MAP Р‘Р›РћРљ 4 вЂ” РїРѕСЃР»Рµ РїСЂРёРЅСЏС‚РёСЏ РІР»Р°РґРµР»СЊС†РµРј

## 2026-09-13 вЂ” docs: SPEC TASK_83 status sheet dismiss

- `session/todo.md` в†’ TASK_83 (SBR, С„Р°Р№Р»С‹, РќРµ Р»РѕРјР°С‚СЊ, РџСЂРѕРІРµСЂРєР°)
- Gate РґРѕ RED: РїСЂРѕРґСѓРєС‚РѕРІС‹Рµ СЂРµС€РµРЅРёСЏ Cable-update + reload (РўР— В§6)
- Scope: `ActiveOrdersAccordion` dismiss + `orderStatusSheet.dismissOrder` only

## 2026-09-13 вЂ” docs: intake TASK_83 status sheet dismiss

- Google Doc в†’ `customer_tasks/TASK-83-status-sheet-dismiss.md` (1:1)
- Artifacts: `artifacts/status_sheet_dismiss_behavior/`
- CBR #83 + `customer_tasks/README.md`
- Scope: local dismiss Г— РІ СЃС‚Р°С‚СѓСЃРЅРѕР№ С€С‚РѕСЂРєРµ; Cable/reload вЂ” Р¶РґСѓС‚ РїСЂРѕРґСѓРєС‚РѕРІС‹Рµ СЂРµС€РµРЅРёСЏ РґРѕ RED

## 2026-09-12 вЂ” docs: COMPONENT_MAP shop active orders + token guards

- Р”РѕР±Р°РІР»РµРЅ `docs/operations/session/COMPONENT_MAP.md` (bootstrap РёР· Р°СѓРґРёС‚Р° Р·РѕРЅС‹)
- On-demand: РЅРµ С‡РёС‚Р°С‚СЊ РЅР° `/start`; `/review` вЂ” Р‘Р›РћРљ 4 С‚РѕР»СЊРєРѕ РµСЃР»Рё Р·Р°РґР°С‡Р° РіР»Р°РІРЅР°СЏ РґР»СЏ Р·РѕРЅС‹
- Intake: РЅРѕРІС‹Рµ РўР— в†’ `customer_tasks/TASK-*.md`; РїСЂРѕРіСЂРµСЃСЃ в†’ РѕРґРёРЅ `todo.md`
- РџСЂР°РІРєРё: `agent-workflow`, `coffeeos-index`, `RULES_INDEX`, `start`/`review`, `repo-layout`, `customer-intake`, `ENTIRE`, `session/README`

## 2026-09-09 вЂ” feat: UK onboarding auto shop API key (FALLBACK still ON)

- `Provision` РІС‹РґР°С‘С‚ tenant key РґР»СЏ sales_point (1Г—); flash RAW РЅР° show; kitchen вЂ” skip
- Local: provision + tenants controller **14/88 PASS**
- Fly **v495**: create `mcp-key-b7845686` в†’ prefix `sk_27213` в†’ API 200/401 в†’ delete В· Point A OK
- РђСЂС‚РµС„Р°РєС‚: `artifacts/v3_sec_shop_api_keys_onboarding/mcp/fly_v495_2026-09-09/`

## 2026-09-09 вЂ” seed: V3-SEC-SHOP-API-KEYS per-tenant (FALLBACK still ON)

- Issued **17** `sales_point` keys (`seed-2026-09-09`) on Fly v494
- Smoke **8/8 PASS** (Aв†”B isolation, query dead, ENV fallback still works)
- **`SHOP_API_KEY_FALLBACK` РЅРµ РІС‹РєР»СЋС‡Р°Р»Рё** вЂ” РїРѕ СЂРµС€РµРЅРёСЋ РІР»Р°РґРµР»СЊС†Р°
- RAW gitignored: `config/secrets/shop_api_keys_fly_seed_2026-09-09.json`
- РђСЂС‚РµС„Р°РєС‚: `artifacts/v3_sec_shop_api_keys_seed/mcp/fly_v494_2026-09-09/`

## 2026-09-09 вЂ” deploy+MCP: V3-SEC OTP-MERGE / SHOP-API-KEYS / JOB-TENANT

- CI green pre-deploy В· Fly **v494** `deployment-01M22FTYBTSHA8HESDV06GPMR2`
- MCP Point A **PASS**: SHOP-API-KEYS 7/7 В· OTP-MERGE 6/6 В· JOB-TENANT worker+evidence 3/3
- Live charge / payв†’ready AвЂ“D **РЅРµ** РіРѕРЅСЏР»Рё (РЅРµС‚ Р°РїСЂСѓРІР°) В· disposable Point A API key issued+revoked
- РђСЂС‚РµС„Р°РєС‚: `milestones/veha_2/artifacts/v3_sec_triple_mcp/mcp/fly_v494_2026-09-09/` В· runner `bin/acceptance/v3_sec_post_deploy_mcp.rb`

## 2026-09-09 вЂ” ops: refund Point A MIR *5953 (РІРёС‚СЂРёРЅР°)

- T-Bank `/v2/Cancel` via `Payments::TbankOrderRefund`: `#202609-0031` + `#0032` (10в‚ЅГ—2) в†’ bank `REFUNDED`
- РЈР¶Рµ refunded СЂР°РЅРµРµ: `#0022`вЂ“`#0023`, `#0025`, `#0027`вЂ“`#0030`; failed/pending РЅРµ С‚СЂРѕРіР°Р»Рё
- РђСЂС‚РµС„Р°РєС‚: `milestones/veha_2/artifacts/ops_refunds_2026-09-09/`

## 2026-09-09 вЂ” REVIEW CI green: V3-SEC-OTP-MERGE

- CI [34321450447](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34321450447) tip `084be2ba` В· code tip `a98e978a` already green
- Entire `01M22D5GHQKN7FEQE7Y87CCN3T` В· bugbot/security usage blocked
- Next: deploy / Fly MCP Point A вЂ” Р°РїСЂСѓРІ
## 2026-09-09 вЂ” REVIEW: V3-SEC-OTP-MERGE

- Local zone+IDOR **22/102 PASS** В· CI green [34320783026](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34320783026) tip `a98e978a`
- Entire `01M22D5GHQKN7FEQE7Y87CCN3T` РЅР° GREEN `a7839074` В· bugbot/security **usage blocked**
- Next: deploy / Fly MCP Point A вЂ” Р°РїСЂСѓРІ
## 2026-09-09 вЂ” regress: V3-SEC-OTP-MERGE PASS

- linker/merger/BindingStepUp: **11/47** В· ownership_idor: **11/55**
- Next: `/review` В· Fly MCP Point A РїРѕСЃР»Рµ deploy (Р°РїСЂСѓРІ)
## 2026-09-09 вЂ” REVIEW CI green: V3-SEC-JOB-TENANT-GUC

- CI [34319445414](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34319445414) В· tip after removing stray OTP `[RED]` from develop
- Entire `01M22D5GHQKN7FEQE7Y87CCN3T` В· bugbot/security usage blocked
- Next: Fly queue network / deploy вЂ” Р°РїСЂСѓРІ
## 2026-09-09 вЂ” REVIEW: V3-SEC-JOB-TENANT-GUC

- Local regress **28/86 PASS** В· GREEN `8f9f5aa2`
- Entire `01M22D5GHQKN7FEQE7Y87CCN3T` В· bugbot/security **blocked by usage** (РєР°Рє shop API)
- Push develop в†’ CI В· Fly queue network / deploy вЂ” Р°РїСЂСѓРІ
## 2026-09-09 вЂ” regress: V3-SEC-JOB-TENANT-GUC PASS

- helper + broadcast/ready/cascade/receipt jobs: **28/86** В· 0 fail
- GREEN `8f9f5aa2` В· Next: `/review`
## 2026-09-09 вЂ” REVIEW CI green: V3-SEC-SHOP-API-KEYS

- CI [34318508943](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34318508943) В· tip `442e7920` (Zeitwerk ApiKeys + Brakeman GUC)
- Entire `01M22C4CV16HA4XDFZ4T4ZGQ23` В· bugbot/security usage blocked
- Next: deploy/secrets вЂ” Р°РїСЂСѓРІ В· Fly MCP Point A
## 2026-09-09 вЂ” GREEN: V3-SEC-JOB-TENANT-GUC (Solid Queue job tenant GUC)

- `Rls::JobTenantContext` + wrap order-scoped jobs В· audit FIXED + ops Р°Р±Р·Р°С†
- Local helper+jobs **28/28** В· commit `8f9f5aa2` В· Next: `/regress`
## 2026-09-09 вЂ” REVIEW: V3-SEC-SHOP-API-KEYS

- Local regress **30/76 PASS** В· GREEN `8f9cd956`
- Entire `01M22C4CV16HA4XDFZ4T4ZGQ23` В· bugbot/security **blocked by usage** (РєР°Рє UserCards)
- Push develop в†’ CI В· deploy/secrets вЂ” Р°РїСЂСѓРІ В· Р·Р°С‚РµРј Fly MCP Point A
## 2026-09-09 вЂ” regress: V3-SEC-SHOP-API-KEYS PASS

- rails auth+resolver+ownership_idor: **30/76** В· 0 fail
- GREEN `8f9cd956` В· Next: `/review` В· Fly MCP РїРѕСЃР»Рµ deploy (Р°РїСЂСѓРІ)
## 2026-09-09 вЂ” SPEC: V3-SEC-JOB-TENANT-GUC (Solid Queue jobs в†’ tenant GUC)

- todo: СЃСЂРµР· A вЂ” `Rls::JobTenantContext` В· wrap order-scoped jobs В· audit FIXED + ops Р°Р±Р·Р°С†
- Parked: OTP-MERGE В· SHOP-API-KEYS WIP В· Next: `/sbr` RED
## 2026-09-09 вЂ” SPEC: V3-SEC-OTP-MERGE (OTP switch + card step-up)

- todo: MVP СЃСЂРµР· A вЂ” linker switch (РЅРµ absorb РєР°СЂС‚) В· BindingStepUp gate В· audit log
- Parked: `V3-SEC-SHOP-API-KEYS` GREEN WIP В· Next: `/sbr` RED
## 2026-09-09 вЂ” SPEC: V3-SEC-SHOP-API-KEYS (tenant-scoped shop API keys)

- todo: header-only `X-Shop-Api-Key` В· digest per-tenant В· rotation В· ENV fallback bootstrap
- Next: `/sbr` RED В· deploy/secrets вЂ” Р°РїСЂСѓРІ
## 2026-09-08 вЂ” Ops: РѕС‚РјРµРЅР°/РІРѕР·РІСЂР°С‚ Р·Р°РєР°Р·РѕРІ Point A (Р¶Р°Р»РѕР±Р° Aram)

- Card: `#202609-0022` / `#202609-0023` СѓР¶Рµ `refunded` (pid 9205922796 / 9205941727)
- Pending Р±РµР· charge в†’ cancelled/failed; SBP pending `9205846937` void РІ Рў-Р‘Р°РЅРєРµ
- Live pay РґР°Р»СЊС€Рµ вЂ” С‚РѕР»СЊРєРѕ РїРѕ СЏРІРЅРѕРјСѓ Р°РїСЂСѓРІСѓ
## 2026-09-08 вЂ” regress: UserCards/#26 zone PASS

- rails payments/user_cards/one_click: **20/84** В· node repeat_invalid_token: **23/0**
- Fly MCP v493 already PASS В· РєРѕРґ РЅРµ РјРµРЅСЏР»Рё (verify-only)
- Next: `/review`
## 2026-09-08 вЂ” UserCards / RebillId + #26 M2 MCP PASS (v493)

- Verify-first: P/U/O/M **PASS** В· Slice C **n/a** (РєРѕРґ РЅРµ РјРµРЅСЏР»Рё)
- Guest Aram В· MIR `*5953`/`*8782` RebillId В· one_click в†’ С‡РµРє В· M2 invalid token в†’ inline В«РЎР±РѕР№ Р±Р°РЅРєР°: РїРѕР·Р¶РµВ»
- РђСЂС‚РµС„Р°РєС‚: `repeat_order_invalid_token_payment_sheet/mcp/fly_v493_2026-09-08/`
- ISSUES UserCards/#26 в†’ рџџў

## 2026-09-08 вЂ” SBP Slice O PASS (v493): init в‰  3001

- Live Point A: `POST sbp/init` + `save_sbp_account` в†’ **200** в†’ `qr.nspk.ru`
- order `b87b63ea-1599-4455-8067-c24428d011f6` В· 179в‚Ѕ В· РєРѕРґ РЅРµ РјРµРЅСЏР»Рё
- РђСЂС‚РµС„Р°РєС‚: `tbank_sbp_autopayments_account_token/mcp/fly_v493_2026-09-08/`
- Next: Slice B (bind РІ Р±Р°РЅРєРµ) В· Z SKIP В· C n/a
## 2026-09-08 вЂ” #80 Slice V sync В«Р·РІРѕРЅСЋВ»: confirmed РЅРµ РїСЂРёС€С‘Р»

- Callcheck UI + poll 200 OK В· `confirmed:false` РґРѕ timeout в†’ SMS.ru 204
- Leave wizard РЅРµ РїСЂРѕРІРµСЂСЏР»Рё; РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё
- РђСЂС‚РµС„Р°РєС‚ MCP_RESULT РѕР±РЅРѕРІР»С‘РЅ (`fly_v492_2026-09-08`)

## 2026-09-08 вЂ” #80 Slice V live Callcheck: V1 PASS В· V2/V3 not verified

- Phone live Г—2: `init_callcheck` + В«Р–РґРµРј Р·РІРѕРЅРѕРєВ» + `tel:8-800вЂ¦` PASS
- РќРµС‚ `confirmed` РґРѕ auto SMS (~40СЃ); leave wizard РЅРµ РїСЂРѕРІРµСЂСЏР»Рё
- SMS fallback в†’ SMS.ru **204** (РѕРїРµСЂР°С‚РѕСЂ/РѕС‚РїСЂР°РІРёС‚РµР»СЊ) вЂ” ops, РЅРµ leave-wizard F
- РђСЂС‚РµС„Р°РєС‚: `registration_callcheck_cascade_ui_ux/mcp/fly_v492_2026-09-08/`

## 2026-09-08 вЂ” Follow-up Fly v493: B6 + Wallet simulate + plan seed

- `WALLET_SIMULATE=1` В· wallet stub `PKPASS_STUB` **PASS**
- Seed `SubscriptionPlan` `pilot_weekly` В· Charge **SKIP** (T-Bank ErrorCode **223** РЅР° СЃС‚Р°СЂС‹С… Rebill)
- Fix B6: menu `style`/`script` в†’ РІРЅСѓС‚СЂСЊ `content_for` (layout barista Р±РµР· yield)
- MCP: B2.2 **PASS** В· #38 simulate **PASS** В· #78 PARTIAL

## 2026-09-08 вЂ” SPEC: UserCards / RebillId + #26 M2 (verify-first)

- `todo.md`: slices **Pв†’Uв†’Oв†’M**, **C** С‚РѕР»СЊРєРѕ РїСЂРё FAIL РЅР°С€РµРіРѕ СЃР»РѕСЏ
- Hot-path: РќРµ Р»РѕРјР°С‚СЊ (webhook / save_card=false / card hash / session cards) В· РџСЂРѕРІРµСЂРєР° rails+node Р·РѕРЅС‹
- РљР°РЅРѕРЅ: UserCards РўР— В· #26 В· MCP_PLAN_STEP5 В· Point A
- Next: `/sbr` Slice P
## 2026-09-08 вЂ” #80 Slice V Callcheck leave wizard: BLOCKED (РЅРµС‚ С‚РµР»РµС„РѕРЅР°)

- Fly **v492** В· `SHOP_OTP_LOG_FALLBACK=false` (ssh)
- V0 PASS: checkout в†’ В«Р’С…РѕРґ РїРѕ С‚РµР»РµС„РѕРЅСѓВ»
- V1вЂ“V3 BLOCKED: РЅРµС‚ `+79вЂ¦` РІР»Р°РґРµР»СЊС†Р° вЂ” РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё
- РђСЂС‚РµС„Р°РєС‚: `registration_callcheck_cascade_ui_ux/mcp/fly_v492_2026-09-08/`

## 2026-09-08 вЂ” SPEC: РЎР‘Рџ 3001 + Zero-Click AccountToken

- Ops/bank-first SBR: primary **Oв†’Bв†’Z**, РєРѕРґ (**C**) С‚РѕР»СЊРєРѕ РїРѕСЃР»Рµ PASS РєР°Р±РёРЅРµС‚Р°
- `todo.md` В· РєР°РЅРѕРЅ `tbank.md` / #34 / ISSUES SBP 3001 рџџЎ
- Р—Р°РїСЂРµС‚ С„РёРєС‚РёРІРЅРѕРіРѕ GREEN Рё В«С‡РёРЅРёС‚СЊ 3001В» Р°РїРїРѕРј
- Next: `/sbr` Slice O
## 2026-09-08 вЂ” SPEC: #80 Callcheck в†’ leave wizard (verify-first)

- CBR #80 В· Slice V live first В· РєРѕРґ РЅРµ С‚СЂРѕРіР°С‚СЊ РґРѕ FAIL
- `todo.md`: Vв†’Fв†’R В· 6 С„Р°Р№Р»РѕРІ + 2 СЃРѕСЃРµРґР° В· РќРµ Р»РѕРјР°С‚СЊ / РџСЂРѕРІРµСЂРєР°
- РљР°РЅРѕРЅ Callcheck (РЅРµ FlashCall); Point A; Р°СЂС‚РµС„Р°РєС‚ `registration_callcheck_cascade_ui_ux/mcp/`

## 2026-09-08 вЂ” Deploy Fly v490 + MCP pack (#38/#71/B2.2/#78)

- CI tip green [34224737257](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34224737257) в†’ **fly deploy** v490
- MCP: #71 CRM **PASS** В· #38 Wallet **PARTIAL** (РЅРµС‚ SIMULATE/certs) В· B2.2 **PARTIAL** (B6 Turbo) В· #78 **PARTIAL** (РЅРµС‚ plan/RebillId)
- Fix: barista menu search `turbo:load` bind вЂ” Р¶РґС‘С‚ redeploy
- РђСЂС‚РµС„Р°РєС‚С‹: `вЂ¦/mcp/fly_v490_2026-09-08/` В· `b22_stage1_mcp_2026-09-08/`
- Sentry 24h unresolved **0**

## 2026-09-08 вЂ” REVIEW: #78 slice-5 Shop API

- bugbot high: reject POST if already `active`/`past_due`
- security medium: `resolve_payment_method!` requires `is_active: true`
- Local: subscriptions zone **13/0** В· Entire `01M1ZYPHF0EZYHM7C12W5PSPA7` РЅР° `1f433a75`
- CI [34224418988](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34224418988) **green** В· deploy вЂ” Р°РїСЂСѓРІ

## 2026-09-08 вЂ” REVIEW: B2.2 stage-1 CI green

## 2026-09-08 вЂ” REVIEW: B2.2 СЌС‚Р°Рї 1 CI green

- tip `f03a46e1` В· CI [34208612629](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34208612629) **green**
- bugbot search-fix `28cca017` В· security no medium+ В· Entire РЅР° `7c76a125`
- **deploy:** СЃС‚РѕРї РґРѕ Р°РїСЂСѓРІР° В· СЌС‚Р°Рї 2 вЂ” РѕС‚РґРµР»СЊРЅС‹Рј РЅР°РјРµСЂРµРЅРёРµРј

## 2026-09-08 вЂ” REVIEW: B2.2 СЌС‚Р°Рї 1 barista menu dual-pane

- bugbot low: search empty category headers в†’ `28cca017`
- security: no medium+ (auth/RLS/XSS/session cart display-only)
- Entire `01M1ZZXV23N5BFK4SGDQV0H4KG` РЅР° `7c76a125` В· push CI
- **deploy:** СЃС‚РѕРї РґРѕ Р°РїСЂСѓРІР°

## 2026-09-08 вЂ” regress: B2.2 СЌС‚Р°Рї 1 barista menu PASS

- Zone: tablet_regression + orders_controller + order_creation_service в†’ **62/0**
- Next: `/review`; Fly MCP вЂ” РЅРµ РѕР±СЏР·Р°С‚РµР»РµРЅ (СЌС‚Р°Рї 1 UI layout, РЅРµ shop pay)

## 2026-09-08 вЂ” GREEN: B2.2 СЌС‚Р°Рї 1 barista menu dual-pane

- `/barista/menu`: СЃРµС‚РєР° РєР°СЂС‚РѕС‡РµРє + РїР°РЅРµР»СЊ РєРѕСЂР·РёРЅС‹ (`session[:barista_cart]`); В«РћРїР»Р°С‚РёС‚СЊВ» disabled
- create-order / sidebar / POS / sold_out PATCH вЂ” РЅРµ С‚СЂРѕРіР°Р»Рё (СЌС‚Р°РїС‹ 2вЂ“5)
- Local: tablet+orders+OrderCreationService **62/0** В· Entire `01M1ZZXV23N5BFK4SGDQV0H4KG` РЅР° `7c76a125`
- Next: `/regress` в†’ `/review`

## 2026-09-08 вЂ” REVIEW: #71 CRM Brevo Contacts

- bugbot high: `retry_on` CrmContactSync::Error + StandardError (5 attempts) вЂ” `fecee7e3`
- security: no medium+ (ENV keys, consent/bounce, no PAN)
- CI tip fix: rubocop listIds spaces + B2.2 menu `@categories` grouping вЂ” `e247f9b1`
- Local 20/0 В· Entire `01M1ZZXV23N5BFK4SGDQV0H4KG` РЅР° `cb1e336d` В· CI [34207477722](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34207477722) **green**
- Next: deploy вЂ” Р°РїСЂСѓРІ; Fly MCP Point A РїРѕСЃР»Рµ deploy

## 2026-09-08 вЂ” regress: #71 CRM Brevo Contacts PASS

- Zone: CRM job+sync + receipt + orders_email в†’ **20/0** (12+8)
- Next: `/review`; Fly MCP Point A вЂ” РїРѕСЃР»Рµ deploy (live Brevo smoke РѕРїС†.)

## 2026-09-08 вЂ” regress: #78 slice-5 Shop API PASS

- Zone: `test/services/subscriptions/` + `subscriptions_api_test` в†’ **11/0**
- Regress #77: `profile_subscription_offer_test` в†’ **7/0**
- Next: `/review` (bugbot + security + push CI); Fly MCP Point A вЂ” РїРѕСЃР»Рµ deploy

## 2026-09-08 вЂ” REVIEW: Wallet PKCS7 bugbot/security fixes

- bugbot high: `paula.r@example.org` в†’ `icon@2x.png`
- security medium: OpenSSL details РІ Р»РѕРі; РєР»РёРµРЅС‚Сѓ СЃС‚Р°Р±РёР»СЊРЅС‹Р№ `PassKit signing failed`
- Local zone 21/0 В· Entire `01M1ZYPHF0EZYHM7C12W5PSPA7` В· push CI

## 2026-09-08 вЂ” GREEN: Apple Wallet PassKit PKCS7

- `PassSigner`: ZIP + SHA1 manifest + PKCS7 detached; `WALLET_WWDR_CERT_PEM` РІ `certs_configured?`
- `PassBuilder` prod path в†’ signed `.pkpass` (`storeCard`); simulate stub Р±РµР· СЂРµРіСЂРµСЃСЃРёРё
- Tests: apple_wallet 9 В· ready_push + wallet_pass 12 PASS В· Entire `01M1ZYPHF0EZYHM7C12W5PSPA7` РЅР° `f8cd57a8`
- OUT: APNs device register (СЃР»РµРґ. SBR)

## 2026-09-08 вЂ” SPEC: #71 Slice A CRM Brevo Contacts sync

- SBR #71 ST-9: СѓР±СЂР°С‚СЊ stub `SyncContactToCrmJob` в†’ `Shop::CrmContactSync` (Brevo Contacts upsert)
- Р РµС€РµРЅРёСЏ: С‚РѕС‚ Р¶Рµ `BREVO_API_KEY` В· Р±РµР· DDL В· raiseв†’retry В· kill-switch `CRM_SYNC_ENABLED` В· СѓРґР°Р»РёС‚СЊ РјС‘СЂС‚РІС‹Р№ RSpec
- todo: job + sync + Minitest + shop-api/INTEGRATIONS В· РќРµ Р»РѕРјР°С‚СЊ consent/receipt/bounce/pay В· РџСЂРѕРІРµСЂРєР°

## 2026-09-08 вЂ” SPEC: B2.2 СЌС‚Р°Рї 1 barista menu dual-pane

- SBR B2.2 СЌС‚Р°Рї 1: РµРґРёРЅС‹Р№ layout `/barista/menu` (СЃРµС‚РєР° РєР°СЂС‚РѕС‡РµРє + РїР°РЅРµР»СЊ РєРѕСЂР·РёРЅС‹)
- OUT: sold_out PATCH / POS / СѓРґР°Р»РµРЅРёРµ create-order / cash (СЌС‚Р°РїС‹ 2вЂ“5)
- todo: menu views + MenuController cart session В· РќРµ Р»РѕРјР°С‚СЊ B2.1/W1.4/create-order В· РџСЂРѕРІРµСЂРєР° tablet regress

## 2026-09-08 вЂ” SPEC: #78 slice-5 Shop API subscriptions

- SBR #78 РїРѕСЃР»Рµ slice-1: РїСѓР±Р»РёС‡РЅС‹Р№ Shop API (GET current + POST create)
- Р РµС€РµРЅРёСЏ: cancel/confirm в†’ **501** РґРѕ Slice 3/4; PATCH auto_renew real; PurchaseService РІС‹Р·РѕРІ only
- todo: routes + SubscriptionsController + integration test + shop-api.md В· РќРµ Р»РѕРјР°С‚СЊ / РџСЂРѕРІРµСЂРєР°

## 2026-09-08 вЂ” SPEC: Apple Wallet PassKit PKCS7

- SBR #38 / #35 B3 slice: prod `.pkpass` signing (APNs device register OUT)
- Р РµС€РµРЅРёСЏ: `storeCard` В· `WALLET_WWDR_CERT_PEM` В· OpenSSL + Zip (rubyzip РІ lock) В· Р±РµР· РЅРѕРІС‹С… gemвЂ™РѕРІ
- todo: С„Р°Р№Р»С‹ PassBuilder/Config/PassSigner + РќРµ Р»РѕРјР°С‚СЊ / РџСЂРѕРІРµСЂРєР°

## 2026-09-07 вЂ” deploy Fly v489 (RUBY-1G)

- GH Deploy [34130234929](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34130234929) green В· tip `3a579022`
- Image `deployment-01M1Y2J4PV5Z5SP7JWM317N8CC` В· `/up` 200 В· shop+categories Point A 200
- Fly: `deactivate_each!` + unique `revoked-{id}-{hex}` confirmed via runner
- Sentry unresolved 24h: **0** В· logs: boot OK (proxy refuse during release вЂ” transient)

## 2026-09-07 вЂ” Sentry RUBY-1G close

- Root: `rails runner` `update_all(refresh_token: "revoked-"+hex)` вЂ” РѕРґРёРЅ С‚РѕРєРµРЅ РЅР° N СЃС‚СЂРѕРє
- App: `MobileSession.deactivate_each!` + unique `deactivate!` (`revoked-{id}-{hex}`)
- Sentry: resolvedInNextRelease В· **deploy:** СЃС‚РѕРї РґРѕ Р°РїСЂСѓРІР°

## 2026-09-07 вЂ” CI: deactivate assertions + vite prebuild

- Root: `833cb113` rewrite `refresh_token` on deactivate вЂ” integration still `find_by(old)`
- Fix: `pwa_lk_api_test` / `session_refresh_test` expect nil old token + `revoked-вЂ¦` row
- CI: `bundle exec vite build --mode=test` before rails test (PwaManifest flake)
- Local PASS: unit 3 + failing 2 В· **deploy:** СЃС‚РѕРї

## 2026-09-07 вЂ” Sentry RUBY-1H / RUBY-1G

- [RUBY-1H](https://llc-manageengine.sentry.io/issues/RUBY-1H): Price в‰Ґ10 РЅР° `fly:release`/`demo:seed` вЂ” clamp РІ ProductTenantSync (СѓР¶Рµ v488)
- [RUBY-1G](https://llc-manageengine.sentry.io/issues/RUBY-1G): UniqueViolation `refresh_token` вЂ” `MobileSession#deactivate!` РїРёС€РµС‚ СѓРЅРёРєР°Р»СЊРЅС‹Р№ `revoked-{id}-{hex}`
- **deploy:** СЃС‚РѕРї РґРѕ Р°РїСЂСѓРІР°

## 2026-09-07 вЂ” min charge 10в‚Ѕ (T-Bank + catalog)

- `Payments::AmountLimits::MIN_CHARGE_RUB = 10`
- `ProductTenantSetting` / `ProductPriceHistory` в‰Ґ10 В· `TbankAdapter` + `SbpPaymentInitiator` reject below
- `ProductTenantSync` / demo markup clamp в‰Ґ10 (release `demo:seed` OK)
- rake `shop:catalog:bump_min_prices` В· Fly PTS below=0 after v488
- tip `0314c3be` В· Fly **v488** `deployment-01M1XWZAJMGWHW89JR7T43K07C` В· `/up` 200
- tests: amount_limits + PTS + sbp + tbank + growth + sync clamp

## 2026-09-07 вЂ” v486 В· #79 MCP PASS В· GH Deploy token fixed

- tip `d81990b4`: resume SBP GetQr if `provider_payment_id` set (T-Bank error 8)
- prior `fa1762c8`: cart в‰¤ promo в†’ no negative discount
- CI [34109574092](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34109574092) green
- `FLY_API_TOKEN` в†’ **org** token (deploy token + CRLF Р»РѕРјР°Р»Рё Authorization) В· GH Deploy [34117804689](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34117804689) **green** в†’ **v486**
- MCP #79 Point A: sbp_init 200 В· growth 11в‚Ѕ В· NSPK QR В· waiting UI PASS В· artifacts `вЂ¦/fly_v486_2026-09-07/`
- #80: `SHOP_OTP_LOG_FALLBACK=false` В· live call РІСЃС‘ РµС‰С‘ SKIP
- Backlog: demo cart в‰¤10в‚Ѕ + bind в†’ T-Bank 3016 (min 1000 РєРѕРї.)

## 2026-09-07 вЂ” deploy v482 + MCP Point A (#79/#80/#81/#82)

- tip `4f980e96` В· CI [34103028345](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34103028345) green
- GH Actions Deploy **fail** (`FLY_API_TOKEN` unauthorized) в†’ local `fly auth login` + `fly deploy --remote-only --depot=false` в†’ **v482**
- `/up` 200 В· SMS secrets OK В· Solid Queue OK В· Sentry 24h: 0 new
- Fly MCP: **#82 PASS** В· **#81 PASS** В· **#80 PARTIAL** (desktop KB + OTP log fallback) В· **#79 PARTIAL** (sbp_init 422 discount; R3 labels OK)
- РђСЂС‚РµС„Р°РєС‚С‹: `вЂ¦/mcp/fly_v482_2026-09-07/` РїРѕРґ РєР°Р¶РґС‹Рј CBR

## 2026-09-07 вЂ” REVIEW: #81 deniedв†’settings + chat Telegram

- bugbot: settings CTA С‚РѕР»СЊРєРѕ РїСЂРё `openSettings` (denied) В· fix `ffd48c6b`
- security: no medium+
- Entire: `01M1XF20DA5E0PXJ99E9DH2HM6` В· Local JS 21/0 В· CI [34102734432](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34102734432) green
- Next: deploy Р°РїСЂСѓРІ В· Fly MCP Point A

## 2026-09-07 вЂ” REVIEW: #82 hide-on-ready + cascade SMS

- bugbot: HIDE_REPEAT Р±РµР· `ready` (repeats РїРѕСЃР»Рµ hide) В· medium presence OK СЃ unsubscribe
- security: no medium+
- GREEN `8cae376d` В· fix `959f2fa` В· Entire `01M1XDGFW23WY77ZRW73D5KGT4`
- CI [34101618655](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34101618655) **green**
- deploy СЃС‚РѕРї В· Fly MCP Point A РїРѕСЃР»Рµ deploy

## 2026-09-07 вЂ” REVIEW: #80 registration Callcheck UI/UX CI green

- bugbot: clear poll error after success В· security: no medium+
- CI [34100150077](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34100150077) green (tip includes receipt test fix)
- Entire `01M1XDGFW23WY77ZRW73D5KGT4` В· deploy СЃС‚РѕРї РґРѕ Р°РїСЂСѓРІР° В· Fly MCP РїРѕСЃР»Рµ deploy

## 2026-09-07 вЂ” ops: /regress #81 PASS (deniedв†’settings + chat)

- JS: push_subscribe + support_chat + notify_actions в†’ **21/0**
- Next: `/review` В· Fly MCP Point A РїРѕСЃР»Рµ REVIEW/deploy (hot-path РІРёС‚СЂРёРЅР°)

## 2026-09-07 вЂ” ops: /regress #82 PASS (hide-on-ready + cascade)

- JS: order_status_sheet + active_poll в†’ **29/0**
- rails: cascade job + notifier + broadcaster + channel + active_orders в†’ **35/0**
- Next: `/review` В· Fly MCP Point A РїРѕСЃР»Рµ deploy

## 2026-09-07 вЂ” REVIEW: #80 registration Callcheck UI/UX

- bugbot: clear poll `localError` / checkout `err` after successful check_status
- security-review: no medium+
- Local regress PASS В· push в†’ CI В· Fly MCP РїРѕСЃР»Рµ deploy

## 2026-09-07 вЂ” ops: #79 REVIEW CI green 34098247173

- tip `e0c4d1a6` В· CI [34098247173](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34098247173) green
- Entire `01M1XCSZMTMDNJCCACY2GZPW71` В· deploy СЃС‚РѕРї РґРѕ Р°РїСЂСѓРІР° В· Fly MCP РїРѕСЃР»Рµ deploy

## 2026-09-07 вЂ” ops: /regress #80 PASS (phone auth / CartSheet)

- JS: cascade + wizard + webview в†’ **33/0**
- rails: phone_otp API + auth_funnel + phone_otp service в†’ **23/138/0**
- GREEN `61593bb2` В· next `/review` В· Fly MCP Point A РїРѕСЃР»Рµ deploy

## 2026-09-07 вЂ” feat: #80 registration UI/UX Callcheck [GREEN]

- Hide checkout `+Nв‚Ѕ` when keyboard open on `#/checkout`
- Callcheck hint + РЅРѕРјРµСЂ РІ РєРЅРѕРїРєРµ `phone-auth-tel-btn`
- Poll: `interpretCallcheckPoll` в†’ onVerified; РѕС€РёР±РєРё РЅРµ soft-swallow
- RED `cbd1d8a4` В· GREEN `61593bb2` В· Р¶РґС‘С‚ `/regress`

## 2026-09-07 вЂ” feat: #79 REVIEW вЂ” bugbot fixes (sync hash + SBP labels + waiting poll)

- Sync `location.hash` before nspk (`beginSbpBankRedirect`)
- SBP init fail: no rethrow into card `payFsmLabel`
- App recover polls on `status=waiting`
- security-review: no medium+ В· Local JS 54 В· rails 15/75

## 2026-09-07 вЂ” ops: /regress #79 PASS (SBP return + autopay)

- JS: `codeblack` + `shop_sbp_*` в†’ **54/0**
- rails: `sbp_payment_return_ui` + `sbp_autopay_charge` + `payment_status` в†’ **15/70/0**
- GREEN `5b3bc76e` В· next `/review` В· Fly MCP Point A РїРѕСЃР»Рµ deploy (hot-path)

## 2026-09-07 вЂ” docs: SPEC #82 cascade SMS + status sheet

- `todo.md`: hide-on-ready (`orderStatusSheet` + `#active` Р±РµР· ready) В· cascade presenceв†’SMS
- Р¤Р°Р№Р»С‹: orderStatusSheet В· orders#active В· OrderReadyCascadeJob В· GuestOrderChannel В· PaidNotifier В· Broadcaster
- РќРµ Р»РѕРјР°С‚СЊ: One-Click/SBP В· repeats РїРѕСЃР»Рµ ready В· С‚Р°Р±Р»Рѕ В· peek accepted/preparing
- РџСЂРѕРІРµСЂРєР°: JS order_status_sheet+poll В· rails cascade+notifier+broadcaster+channel+active_orders
- Р’РЅРµ slice: SMS URL-С€Р°Р±Р»РѕРЅ В· RSpec РёР· Google Doc

## 2026-09-07 вЂ” docs: SPEC #81 notifications gaps (deniedв†’settings + chat)

- `todo.md`: РєР»РёРєР°Р±РµР»СЊРЅС‹Р№ denied-Р±Р°РЅРЅРµСЂ в†’ РЅР°СЃС‚СЂРѕР№РєРё; chat в†’ `SUPPORT_TELEGRAM_URL`; #38 РІРЅРµ slice
- РЎРєСЂРёРЅ: `artifacts/вЂ¦/01_push_denied_browser_settings_2026-09-07.png`
- Р¤Р°Р№Р»С‹: orderStatusNotifyActions В· ActiveOrdersAccordion В· supportChatAdapter В· supportConfig + JS tests
- РќРµ Р»РѕРјР°С‚СЊ: Wallet В· push granted В· cancel В· #35 peek

## 2026-09-07 вЂ” docs: intake #82 cascade SMS + status sheet

- PHASE 0: РїСЂР°РІРєРё Рї.10 вЂ” SMS РїРѕСЃР»Рµ В«Р·Р°РєР°Р· РіРѕС‚РѕРІВ» РЅРµ СЂР°Р±РѕС‚Р°РµС‚; С€С‚РѕСЂРєР° СЃС‚Р°С‚СѓСЃР° РѕСЃС‚Р°С‘С‚СЃСЏ РЅР° РіР». СЌРєСЂР°РЅРµ
- РўР—: `customer_tasks/РљР°СЃРєР°Рґ SMS РїРѕСЃР»Рµ Р—Р°РєР°Р· РіРѕС‚РѕРІ Рё С€С‚РѕСЂРєР° СЃС‚Р°С‚СѓСЃР° РЅР° РіР»Р°РІРЅРѕРј.md`
- РђСЂС‚РµС„Р°РєС‚С‹: `artifacts/order_ready_cascade_sms_status_sheet_fix/`
- CBR #82 + reopen #39/#35 В· DEMO_FEEDBACK В· РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё В· Р¶РґС‘С‚ `/spec`

## 2026-09-07 вЂ” docs: SPEC #80 registration UI/UX + Callcheck

- `todo.md`: Callcheck РєР°РЅРѕРЅ (РЅРµ flash_call); P0 keyboard/CTA В· copy В· post-call; Г—2 backlog
- Р¤Р°Р№Р»С‹: CartSheet / shopWebViewLayout / Checkout / phoneAuthCascade / PhoneAuth{Wizard,CodeStep} / phone_otp
- РќРµ Р»РѕРјР°С‚СЊ: One-Click/SBP В· peek В· Callcheckв†’SMS@40s В· #35 status
- РџСЂРѕРІРµСЂРєР°: JS cascade+wizard+webview В· rails phone_otp + auth_funnel_wizard

## 2026-09-07 вЂ” docs: intake #81 notifications / Wallet / WebPush gaps

- PHASE 0: reopen #37/#38/#41 вЂ” deniedв†’РЅР°СЃС‚СЂРѕР№РєРё Р±СЂР°СѓР·РµСЂР°; С„РѕРЅРѕРІС‹Рµ FCM/Wallet В«РЅРµ СЂРµР°Р»РёР·РѕРІР°РЅРѕВ»; С‡Р°С‚ РїРѕРґРґРµСЂР¶РєРё РЅРµ РєР»РёРєР°РµС‚СЃСЏ
- РўР—: `customer_tasks/РљРѕСЃСЏРєРё СѓРІРµРґРѕРјР»РµРЅРёР№ Wallet WebPush С„РѕРЅРѕРІС‹Рµ Рё РєРЅРѕРїРєР° С‡Р°С‚.md`
- РђСЂС‚РµС„Р°РєС‚С‹: `artifacts/notifications_wallet_webpush_gaps_reopen/`
- CBR #81 (#80 = Registration) В· РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё В· Р¶РґС‘С‚ `/spec`

## 2026-09-07 вЂ” docs: intake #80 registration UI/UX + Callcheck cascade

- PHASE 0: РїСЂР°РІРєРё Рї.8 (РєР»Р°РІРёР°С‚СѓСЂР°/СЃСѓРјРјР°, РєРѕРїРёСЂР°Р№С‚ Callcheck, РЅРµС‚ РїРµСЂРµС…РѕРґР° РїРѕСЃР»Рµ Р·РІРѕРЅРєР°) + Google Doc РєР°СЃРєР°РґР° CallcheckГ—2в†’SMS
- РўР—: `customer_tasks/Р РµРіРёСЃС‚СЂР°С†РёСЏ PWA UI UX Рё РєР°СЃРєР°Рґ Callcheck x2 SMS.md`
- РђСЂС‚РµС„Р°РєС‚С‹: `artifacts/registration_callcheck_cascade_ui_ux/` (2 СЃРєСЂРёРЅР°)
- CBR #80 + ISSUES В· РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё В· Р¶РґС‘С‚ `/spec`

## 2026-09-07 вЂ” docs: SPEC #79 SBP return + autopay labels

- `todo.md`: waiting РґРѕ `redirectToSbp` В· wire `createSbpAutopayFsm` В· SMS РІРЅРµ slice
- Р¤Р°Р№Р»С‹: Checkout / App / PaymentResult / shopSbp{Pay,Autopay} / codeblackPendingOrder
- РќРµ Р»РѕРјР°С‚СЊ: card One-Click В· Repeat SBP В· #35 С€С‚РѕСЂРєР° В· webhook
- РџСЂРѕРІРµСЂРєР°: JS codeblack+sbp_* В· rails sbp_payment_return_ui + sbp_autopay_charge + payment_status

## 2026-09-07 вЂ” docs: intake #79 SBP return + autopay labels

- PHASE 0: РїСЂР°РІРєРё Рї.7 Р·Р°РєР°Р·С‡РёРєР° (СЃС‚Р°С‚СѓСЃС‹ Р°РІС‚РѕРїР»Р°С‚РµР¶Р°, СЌРєСЂР°РЅ РїРѕСЃР»Рµ Р±Р°РЅРєР°, 11/8 РЎР‘Рџ) + РїРѕРІС‚РѕСЂ CODE:BLACK РўР—
- РўР—: `customer_tasks/РќР°РґРїРёСЃРё Р°РІС‚РѕРїР»Р°С‚РµР¶Р° Рё СЌРєСЂР°РЅ РїРѕСЃР»Рµ РІРѕР·РІСЂР°С‚Р° РёР· Р±Р°РЅРєР° РЎР‘Рџ.md`
- РђСЂС‚РµС„Р°РєС‚С‹: `artifacts/sbp_return_status_screen_autopay_labels/`
- CBR + README РёРЅРґРµРєСЃ В· РєРѕРґ РЅРµ С‚СЂРѕРіР°Р»Рё В· Р¶РґС‘С‚ `/spec`

## 2026-09-07 вЂ” deploy v481 + MCP Point A (#35/#71/#26/РС‚РѕРіРѕ)

- Push `a9148d9b` В· CI [34088874139](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34088874139) green
- `fly deploy --remote-only --depot=false` в†’ **v481** В· `/up` 200
- MCP: #35 MUST PASS В· #71 PASS В· CartSheet РС‚РѕРіРѕ PASS В· #26 PARTIAL (РЅРµС‚ saved card РґР»СЏ M2)
- РђСЂС‚РµС„Р°РєС‚С‹: `вЂ¦/mcp/fly_v481_2026-09-07/`

## 2026-09-07 вЂ” docs: #71 MCP plan remember receipt email (post-deploy agent)

- РџР»Р°РЅ Point A R0вЂ“R6 В· hide С‚РѕР»СЊРєРѕ РїРѕСЃР»Рµ LS `shop_receipt_email` (РЅРµ profile)
- Р¤Р°Р№Р»: `artifacts/email_collection_after_payment/MCP_DEPLOY_CHECKLIST.md`
- Deploy СЌС‚РёРј Р°РіРµРЅС‚РѕРј РЅРµС‚ вЂ” РѕР±С‰РёР№ deploy + MCP РґСЂСѓРіРёРј

## 2026-09-07 вЂ” docs: #26 MCP plan step5 (post-deploy agent)

- РџР»Р°РЅ Point A M1вЂ“M6 В· P0 = M2 inline РЅР° РѕС‚РєР°Р·Рµ Р±Р°РЅРєР°
- Р¤Р°Р№Р»: `artifacts/repeat_order_invalid_token_payment_sheet/MCP_PLAN_STEP5_2026-09-07.md`
- Deploy СЌС‚РёРј Р°РіРµРЅС‚РѕРј РЅРµС‚ вЂ” РѕР±С‰РёР№ deploy + MCP РґСЂСѓРіРёРј

## 2026-09-06 вЂ” REVIEW: #26 step5 pay sheet inline

- GREEN `32c79960` В· regress `f5f73d3e` В· bugbot OK В· security OK
- Entire `01M1V1SBJ6NVZ0K0X3RQ0CSE4Z` В· CI GREEN `34025628548` / `34025794993`
- Next: deploy РїРѕ Р°РїСЂСѓРІСѓ В· Fly MCP Point A РґР»СЏ Р·Р°РєР°Р·С‡РёРєР°

## 2026-09-06 вЂ” REVIEW: #71 email remember / donвЂ™t re-ask

- bugbot: hide С‚РѕР»СЊРєРѕ РїРѕСЃР»Рµ LS save (РЅРµ profile) в†’ fix `0c17ee9f`
- security: no issues
- Local: JS 16 В· rails 10 PASS В· Entire `01M1V2FH9A8C7J6X35YF5RQSFE`
- Push develop В· CI (СЃРј. HANDOFF)
- Deploy / Fly MCP Point A вЂ” С‚РѕР»СЊРєРѕ РїРѕ Р°РїСЂСѓРІСѓ

## 2026-09-06 вЂ” regress: #71 email remember / donвЂ™t re-ask PASS

- JS: `email_collection_test` **16/0**
- rails: `checkout_acceptance_cbr` **10/0**
- Next: `/review` В· Fly MCP Point A РµС‰С‘ РґР»СЏ Р·Р°РєР°Р·С‡РёРєР°

## 2026-09-06 вЂ” REVIEW: #35 QA reopen compact status sheet

- bugbot: no bugs В· security: no issues
- Local: JS 60 В· rails 15 PASS В· Entire `01M1V0RTYSBYRP8NWWEAWR24W0` РЅР° `fa7d6d75`
- Push develop В· CI **green** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34026092095
- Deploy / Fly MCP Point A вЂ” С‚РѕР»СЊРєРѕ РїРѕ Р°РїСЂСѓРІСѓ

## 2026-09-06 вЂ” regress: #26 step5 pay inline PASS

- JS: payment_error + repeat_invalid_token **29/0**
- rails: repeat_invalid_token_payment **12/0**
- Next: `/review` В· Fly MCP Point A РµС‰С‘ РґР»СЏ Р·Р°РєР°Р·С‡РёРєР°

## 2026-09-06 вЂ” regress: #35 QA status sheet PASS

- JS: cancel/accordion/sheet/notify **60/0**
- rails: acceptance+mount **15/0** В· peek/expanded stack **9/0**
- Next: `/review` В· Fly MCP Point A РµС‰С‘ РґР»СЏ Р·Р°РєР°Р·С‡РёРєР°

## 2026-09-06 вЂ” REVIEW: CartSheet В«РС‚РѕРіРѕВ» (РїСЂР°РІРєР° 5)

- GREEN `7d7cfbec` В· fix thousands `91daaf19` В· Entire `01M1V145Z4ABQQM5APY2EXEG6N`
- bugbot: hidden total в†’ `formatThousands` В· security: no issues
- Local: cart zone 36/0 В· Next: deploy РїРѕ Р°РїСЂСѓРІСѓ

## 2026-09-06 вЂ” GREEN: #35 QA reopen compact status sheet

- RED `785fa2e3` В· GREEN `7ab3f3e6` В· Entire `01M1V0RTYSBYRP8NWWEAWR24W0`
- Post-pay в†’ `/` + compact sheet; status Р±РµР· receipt; cancel hint В«1вЂ“3 РґРЅСЏВ»; X = РЎРєСЂС‹С‚СЊ
- Local: JS zone 60 PASS В· rails acceptance/mount 15 PASS

## 2026-09-06 вЂ” SPEC: #71 QA reopen email remember / donвЂ™t re-ask

- РљР°РЅРѕРЅ: РїРѕСЃР»Рµ РїРµСЂРІРѕРіРѕ email РґР»СЏ С‡РµРєР° вЂ” Р±Р»РѕРє РЅРµ РїРѕРєР°Р·С‹РІР°С‚СЊ РЅР° СЃР»РµРґСѓСЋС‰РёС… Р·Р°РєР°Р·Р°С…
- `todo.md` в†’ #71 В· SPEC `[x]` В· RED `[ ]`
- Р РµС€РµРЅРёРµ: tenant LS receipt-email + hide `OrderSuccessEmailBlock` РІ `PaymentResult`

## 2026-09-06 вЂ” feat: CartSheet РІРёРґРёРјРѕРµ В«РС‚РѕРіРѕВ» (РїСЂР°РІРєР° 5) [GREEN]

- `checkoutBar`: СЃР»РµРІР° **РС‚РѕРіРѕ Nв‚Ѕ** (`shop-cart-order-total`), СЃРїСЂР°РІР° РєРЅРѕРїРєР° `+Nв‚Ѕ`
- Hidden: `shop-cart-hidden-total` Р±РµР· `sr-only`
- РўРµСЃС‚С‹: `cart_checkout_button_total_dynamic` + СЂРµРіСЂРµСЃСЃРёСЏ b113/quick_repeat PASS
- Next: `/review`

## 2026-09-06 вЂ” docs: #71 QA reopen (email remember, donвЂ™t re-ask)

- Р¤РёРґР±РµРє Р·Р°РєР°Р·С‡РёРєР°: РїРѕС‡С‚Сѓ РїРѕСЃР»Рµ РѕРїР»Р°С‚С‹ РґР»СЏ С‡РµРєР° вЂ” **Р·Р°РїРѕРјРЅРёС‚СЊ**, РЅР° СЃР»РµРґСѓСЋС‰РёС… Р·Р°РєР°Р·Р°С… **РЅРµ СЃРїСЂР°С€РёРІР°С‚СЊ**
- РўР— #71 Р±РµР· РїРµСЂРµР·Р°РїРёСЃРё; Р°СЂС‚РµС„Р°РєС‚ `вЂ¦/email_collection_after_payment/`
- CBR #71 в†’ QA reopen В· Next `/spec`
- РњРµС‚Р°: РїСЂР°РІРєРё Р·Р°РєР°Р·С‡РёРєР° вЂ” **РєР°Рє СЃРєР°Р·Р°РЅРѕ** (РѕС‡РµСЂРµРґСЊ 1вЂ“5 + СЌС‚Р°)

## 2026-09-06 вЂ” SPEC: #26 QA reopen step5 inline pay error

- Root: `resolveCheckoutSheetInlineError` в†’ null; G7 `$effect` СЃР±СЂР°СЃС‹РІР°РµС‚ FSM/selection
- Р РµС€РµРЅРёРµ: friendly label РІ СЃР»РѕС‚ sheet; selection СЃРѕС…СЂР°РЅРёС‚СЊ; CTA click в†’ new card
- `todo.md` в†’ #26 В· SPEC `[x]` В· RED `[ ]`

## 2026-09-06 вЂ” docs: #26 QA reopen (pay error inline copy)

- Р¤РёРґР±РµРє Р·Р°РєР°Р·С‡РёРєР°: РѕС‚РєР°Р· РєР°СЂС‚С‹ РµСЃС‚СЊ, **РЅРµС‚** РїРѕСЏСЃРЅРµРЅРёСЏ (В«РїРѕРїСЂРѕР±СѓР№С‚Рµ РґСЂСѓРіСѓСЋ РєР°СЂС‚СѓВ» / С‡С‚Рѕ РґРµР»Р°С‚СЊ)
- РўР— #26 Р±РµР· РїРµСЂРµР·Р°РїРёСЃРё; Р°СЂС‚РµС„Р°РєС‚ `вЂ¦/repeat_order_invalid_token_payment_sheet/screenshots/qa_2026-09-06/`
- CBR #26 в†’ QA reopen В· #35 РЅР° РїР°СѓР·Рµ В· Next `/spec`

## 2026-09-06 вЂ” SPEC: #35 reopen QA СЃС‚Р°С‚СѓСЃРЅРѕР№ С€С‚РѕСЂРєРё

- Р—Р°РєР°Р·С‡РёРє: 3 РїСЂР°РІРєРё (home post-pay full-screen; X/СЃРѕСЃС‚Р°РІ/cancel 1вЂ“3Рґ; UX СЂРµС„РµСЂРµРЅСЃ)
- `todo.md` в†’ #35 reopen В· SPEC `[x]` В· RED `[ ]`
- QA СЃРєСЂРёРЅС‹ в†’ `artifacts/order_status_compact_sheet_push/screenshots/qa_2026-09-06/`
- Р РµС€РµРЅРёСЏ: PaymentResult в†’ `/`; status row Р±РµР· receipt; CTA hint 1вЂ“3 РґРЅСЏ; X = dismiss

## 2026-09-05 вЂ” deploy v480 + Fly MCP Г—3 Point A PASS

- `git push` develop up-to-date В· CI green `33951901384`
- `fly deploy --remote-only --depot=false` в†’ **v480** `deployment-01M1R6VMAJFWR0VDA4V5TCGRJ7`
- MCP-1 offer rollback: РЈРљ OFF + config `enabled=false` + ready CTA tips В· PASS
- MCP-2 promo `amount_rub` 11в†’15в†’11 via `point_campaign_settings` В· PASS (live charge SKIP)
- MCP-3 #78: `subscription_*` tables on Fly В· shop smoke PASS В· purchase E2E SKIP (no API/UI)
- Sentry 24h new: none В· Fly logs: OK
- Artifacts: `вЂ¦/mcp/fly_v480_2026-09-05/` (offer / promo / subscription_billing)

## 2026-09-05 вЂ” review: #78 subscription slice-1

- bugbot: no bugs В· security HIGH в†’ fix webhook `subscription_intent` в†’ closed + PaymentFulfillment
- Local: purchase + PaymentStatusUpdater + qa_2_3/order_creator PASS
- Push `develop` в†’ CI **green** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/33951753636
- Entire: `01M1R4VQH6TPMM6SQ2RZ5JTM46` РЅР° `cb02d8b4`
- Deploy / Fly MCP: **С‚РѕР»СЊРєРѕ РїРѕ Р°РїСЂСѓРІСѓ**

## 2026-09-05 вЂ” REVIEW: promo amount from point_campaign_settings

- bugbot: no bugs В· security: no medium+ В· Local 43 runs PASS
- Push `develop` в†’ CI **green** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/33951212810
- Entire: `01M1R4VQH6TPMM6SQ2RZ5JTM46` В· impl GREEN `34a899d4`
- Deploy / Fly MCP Point A: **С‚РѕР»СЊРєРѕ РїРѕ Р°РїСЂСѓРІСѓ** (live Subtask 12)

## 2026-09-05 вЂ” ops: /regress #78 subscription PurchaseService PASS

- `purchase_service_test` 1/19 PASS
- `qa_section_2_3_payment_cart` + `order_creator` 23/44 PASS
- Next: `/review`; Fly MCP Point A вЂ” РїРѕСЃР»Рµ deploy

## 2026-09-05 вЂ” regress: promo amount from config PASS

- growth_promo 13 + point_campaign 4 + user_cards 3 + qa_2_3 2 + order_creator 21 вЂ” 0 failures
- Next: `/review`; Fly MCP Point A вЂ” РїРѕСЃР»Рµ deploy

## 2026-09-05 вЂ” REVIEW: emergency disable subscription offer Point A

- bugbot: no bugs В· security: no medium+ В· Local regress PASS
- Push `develop` в†’ CI **green** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/33950595431
- Entire: `01M1P2BSG7MY3C0VM0FXCSZXRK` В· Point A offer remains OFF (config, no deploy needed)
- Deploy: РЅРµ С‚СЂРµР±СѓРµС‚СЃСЏ РґР»СЏ СЌС‚РѕРіРѕ РѕС‚РєР°С‚Р° (СѓР¶Рµ РЅР° Fly v479)

## 2026-09-05 вЂ” feat: promo amount from point_campaign_settings [GREEN]

- `GrowthPromo.promo_amount_rub(tenant)` в†ђ `config["promo_amount_rub"]`; fallback `DEFAULT_PROMO_AMOUNT_RUB`
- `AMOUNT_RUB` alias РЅР° DEFAULT; UserCards API `amount_rub` СЃ С‚РѕРіРѕ Р¶Рµ helper
- Entire: `01M1R4VQH6TPMM6SQ2RZ5JTM46` (impl `34a899d4`); next `/regress`

## 2026-09-05 вЂ” docs: SPEC #78 subscription billing slice-1

- todo: plans/subscriptions + PurchaseService; backlog usage/renewal/API/UI
- РќРµ Р»РѕРјР°С‚СЊ: checkout, binding, webhook idempotency, #77 offer OFF
- Next: `/sbr` RED

## 2026-09-05 вЂ” docs: intake #78 РђСЂС…РёС‚РµРєС‚СѓСЂР° РїРѕРґРїРёСЃРєРё

- customer_tasks + CBR + artifacts `subscription_billing_architecture/`
- Scope: plans/subscriptions/usage, Purchase/Renewal/Cancel, Shop API, PWA, jobs; Р±РµР· РїСЂР°РІРѕРє `TbankAdapter`
- Next: `/spec`; Р—Р°РґР°С‡Р°-2 promo parked

## 2026-09-05 вЂ” regress: subscription offer zone PASS (post-rollback)

- Local: rails 20/79 PASS + CTA JS 16 PASS
- UK Point A recheck: `enabled=false`, `second_cta_mode=tips`
- CTA matrix: offerOff в†’ tips on ready (no subscription stub)

## 2026-09-05 вЂ” ops: emergency disable subscription offer (Point A) [GREEN]

- РЈРљ PATCH Point A: `enabled=false` + `second_cta_mode=tips` (Р±С‹Р»Рѕ subscription)
- Audit: РІ РЈРљ visible С‚РѕР»СЊРєРѕ Point A (SINGLE_POINT_A); РґСЂСѓРіРёС… risky РЅРµС‚
- Verify: `GET /shop/api/config` в†’ `subscription_offer.enabled=false`
- Artifact: `subscription_offer_eligibility/ops/rollback_point_a_2026-09-05.json`
- РљРѕРґ CTA/eligibility / `INTEGRATIONS.md` РЅРµ РјРµРЅСЏР»РёСЃСЊ; ready CTA E2E в†’ `/regress`

## 2026-09-05 вЂ” SPEC: promo amount from point_campaign_settings

- Р—Р°РґР°С‡Р°-2: `price!` / `charge_amount` / API `amount_rub` в†ђ `promo_amount_rub`; РґРµС„РѕР»С‚ РѕРґРёРЅ (`DEFAULT_PROMO_AMOUNT_RUB`)
- Scope: GrowthPromo + UserCardsController + С‚РµСЃС‚С‹; Tbank/antifraud/subscriptions РІРЅРµ
- Next: `/sbr` RED; subscription-offer rollback в†’ **done** (СЃРј. Р·Р°РїРёСЃСЊ РІС‹С€Рµ)

## 2026-09-05 вЂ” SPEC: emergency disable subscription offer (Point A)

- Config-only rollback plan: РЈРљ `subscription_offer_setting` в†’ `enabled=false`
- Point A `2fdee1ac-4674-41ee-b89e-87b45643f789`; РєРѕРґ CTA/eligibility РЅРµ С‚СЂРѕРіР°РµРј
- todo: Audit SELECT в†’ GREEN РЈРљ в†’ CTA verify в†’ DEMO_FEEDBACK

## 2026-09-04 вЂ” ops: clear stuck T-Bank pending (StuckPayments spam)

- Fly runner: mark `tbank` pending/processing `< 2026-09-01` в†’ `failed` (186); related `pending_payment` orders в†’ `cancelled` (182)
- Also cleared 2 Point A MCP leftovers from 2026-09-04 (live charge SKIP)
- `STUCK_ALERT_CANDIDATES_NOW=0` (Telegram StuckPaymentsCheckJob quiet)
- One-shot scripts under `tmp/` (not productized)

## 2026-09-04 вЂ” fix: Sentry RUBY-1F / RUBY-16 runner Current noise

- `SentryNoiseFilter`: `LocalJumpError` + `tags.source=runner` (РїСѓСЃС‚РѕР№ transaction)
- `Current.assign!` вЂ” assign Р±РµР· Р±Р»РѕРєР° (РІРјРµСЃС‚Рѕ РѕС€РёР±РѕС‡РЅРѕРіРѕ `set!` / `set` Р±РµР· `do`)
- Tests: noise filter + Current
- Fixes RUBY-1F В· Fixes RUBY-16

## 2026-09-04 вЂ” deploy: Fly v479 + MCP #75/#76/#77 Point A

- `fly deploy` в†’ **v479**; release: ConcurrentMigrationError в†’ soft-skip when schema current (`fly_release.rake`)
- MCP Point A: #76 PASS В· #75 UI PASS (live charge SKIP) В· #77 AвЂ“F PASS
- Artifacts: `вЂ¦/mcp/fly_v479_2026-09-04/`
- Next: Р°РїСЂСѓРІ Р·Р°РєР°Р·С‡РёРєР°

## 2026-09-04 вЂ” review: #77 subscription offer eligibility В· CI

- bugbot: no bugs В· security: no medium+
- follow-up: wire config/profile into OrderActionButtons + OrderStatus; subscription в†’ Р›Рљ
- docs: shop-api + pwa-realtime (#77)
- Entire: `01M1P2BSG7MY3C0VM0FXCSZXRK` РЅР° `4087ad4e`
- Next: deploy Р°РїСЂСѓРІ В· Fly MCP Point A

## 2026-09-04 вЂ” ops: /regress #77 PASS subscription offer zone

- eligibility + settings + profile/UK API: 20 runs / 79 assert PASS
- push_register + orders_email: 10 runs / 38 assert PASS
- Next: `/review` В· Fly MCP Point A РїРѕСЃР»Рµ deploy

## 2026-09-04 вЂ” fix+review: #76 kitchen disables promo В· REVIEW

- bugbot medium: СЃРјРµРЅР° С‚РёРїР° РЅР° `production_kitchen` РіР°СЃРёС‚ `card_binding_promo` (counter СЃРѕС…СЂР°РЅС‘РЅ)
- security-review: no medium+
- Entire GREEN: `01M1P2BSG7MY3C0VM0FXCSZXRK` РЅР° `6c1966d2`
- Next: CI green В· deploy Р°РїСЂСѓРІ В· Fly MCP Point A

## 2026-09-04 вЂ” ops: /regress #76 PASS

- Platform/promo: 31 runs / 96 assert PASS
- order_creator + user_cards_sbp: 23 runs / 50 assert PASS
- Next: `/review` В· Fly MCP Point A РїРѕСЃР»Рµ deploy

## 2026-09-04 вЂ” docs: SPEC #77 subscription offer eligibility

- todo.md: signals РЅР° mobile_customers В· settings per-point В· Eligibility service В· profile/config В· CTA + appinstalled
- Р РµС€РµРЅРёСЏ В§4: fallback=tips В· enum tips|subscription В· completed_orders query В· Р±РµР· РґРµРЅРѕСЂРјР°Р»РёР·Р°С†РёРё
- РќРµ Р»РѕРјР°С‚СЊ: orders_count В· CTA РїСЂРё enabled=false В· FCM/email В· PWA banner В· Tbank/С„РёСЃРєР°Р»/11в‚Ѕ/billing
- РџСЂРѕРІРµСЂРєР°: eligibility + settings + profile API; СЂРµРіСЂРµСЃСЃ push_register + orders_email

## 2026-09-04 вЂ” docs: intake #77 subscription offer eligibility

- РўР— 1:1: `customer_tasks/РЈРјРЅС‹Р№ РїРѕРєР°Р· РѕС„С„РµСЂР° РїРѕРґРїРёСЃРєРё вЂ” СЃРёРіРЅР°Р»С‹ С‚РѕР»РµСЂР°РЅС‚РЅРѕСЃС‚Рё Рё РЈРљ-РїРµСЂРµРєР»СЋС‡Р°С‚РµР»СЊ.md`
- Artifacts: `subscription_offer_eligibility/`
- CBR #77; #76 parked (SPEC done в†’ `/sbr`); С„РѕРєСѓСЃ СЃРµСЃСЃРёРё в†’ `/spec` #77

## 2026-09-04 вЂ” docs: SPEC #76 point_campaign_settings

- todo.md: Tenant=С‚РѕС‡РєР° В· РЈРљ form/show В· GrowthPromo.point_allows_promo? В· sync upsert
- РќРµ Р»РѕРјР°С‚СЊ: checkout full price В· attempts semantics В· РёР·РѕР»СЏС†РёСЏ С‚РѕС‡РµРє
- РџСЂРѕРІРµСЂРєР°: tenants_controller + growth_promo + order_creator / user_cards

## 2026-09-04 вЂ” docs: intake #76 РЈРљ point campaign promo 11в‚Ѕ

- РўР— 1:1: `customer_tasks/РЈРљ вЂ” РІРєР»СЋС‡РµРЅРёРµ РїСЂРѕРјРѕ 11в‚Ѕ РїСЂРё СЃРѕР·РґР°РЅРёРё С‚РѕС‡РєРё.md`
- Artifacts: `uk_point_campaign_promo_11rub/`
- CBR #76 + README customer_tasks; #75 СЃС‚Р°С‚СѓСЃ в†’ REVIEW+follow-up

## 2026-09-04 вЂ” fix(ci): soft-skip importmap audit on npm transport flake

- `scan_js`: retry Г—3; РїРѕСЃР»Рµ 3Г— `Net::ReadTimeout` в†’ warning + exit 0
- Р РµР°Р»СЊРЅС‹Рµ vuln findings РїРѕ-РїСЂРµР¶РЅРµРјСѓ РІР°Р»СЏС‚ job
- `config/ci.rb` вЂ” С‚РѕС‚ Р¶Рµ РєРѕРЅС‚СЂР°РєС‚

## 2026-09-04 вЂ” fix(ci): retry importmap audit on npm ReadTimeout

- `scan_js`: 3 РїРѕРїС‹С‚РєРё СЃ backoff РІРѕРєСЂСѓРі `bin/importmap audit` (С„Р»РµР№Рє `Net::ReadTimeout`)
- `config/ci.rb`: С‚РѕС‚ Р¶Рµ retry РґР»СЏ Р»РѕРєР°Р»СЊРЅРѕРіРѕ `bin/ci`
- Р РµР°Р»СЊРЅС‹Рµ СѓСЏР·РІРёРјРѕСЃС‚Рё РїРѕ-РїСЂРµР¶РЅРµРјСѓ РІР°Р»СЏС‚ job (Р±РµР· continue-on-error)

## 2026-09-04 вЂ” feat: #75 follow-up velocity phone_status Checkout PII

- `BindingVelocity` 15Рј (hash/phone/device/IP/BIN; BIN РЅРµ РґР»СЏ РЎР‘Рџ)
- `phone_status` enum + `BindingStepUp` (OTP С‚РѕР»СЊРєРѕ С‚РµР»РµС„РѕРЅ Р°РєРєР°СѓРЅС‚Р°)
- Checkout `promoEligible`/`cartTotalRub` + `growth_promo` РІ `/user/cards`
- `phone_digest` + `purge_expired!`; SBP `dedupe_active_sbp_method_hashes!`

## 2026-09-04 вЂ” fix: #75 REVIEW growth promo amounts + mark_used

- `GrowthPromo.price!` вЂ” discount РїРѕРґ `chk_order_amounts`
- `consume_from_payment!` РїРѕСЃР»Рµ СѓСЃРїРµС€РЅРѕР№ card/SBP bind
- SBP init РїСЂРёРјРµРЅСЏРµС‚ 11в‚Ѕ РїСЂРё `save_sbp_account`
- Receipt: РѕРґРЅР° РїРѕР·РёС†РёСЏ 11в‚Ѕ РїСЂРё `growth_promo_intent`

## 2026-09-04 вЂ” feat: stuck payments cron + channel order stats log

- `config/recurring.yml`: `Payments::StuckPaymentsCheckJob` every 15m (TelegramAlertJob Р±РµР· РґРµРґСѓРїР°)
- `Analytics::ChannelOrderStatsJob` + Collector вЂ” СЃС‡С‘С‚С‡РёРєРё `orders.source` / 15m / `open_now`, С‚РѕР»СЊРєРѕ Р»РѕРі `[ChannelOrderStats]`
- Р‘РµР· РїСЂР°РІРѕРє `Health::TenantChecker`; Р±РµР· Telegram РЅР° stats
- Local: analytics collector+job PASS

## 2026-09-04 вЂ” ops: /regress #75 binding+promo PASS

- payments+growth 28 runs PASS В· order_creator+qaВ§2.3 23 PASS В· i18n 4 PASS
- Р—РѕРЅР°: shop/РѕРїР»Р°С‚Р° В· Fly MCP Point A РµС‰С‘ РЅСѓР¶РµРЅ РґР»СЏ Р·Р°РєР°Р·С‡РёРєР°
- Next: `/review`

## 2026-09-04 вЂ” docs: SPEC #75 binding + promo 11в‚Ѕ

- `todo.md` вЂ” SBR С„Р°Р·С‹, 7 С„Р°Р№Р»РѕРІ (SavedCardStore / SbpAccountTokenStore / MPM / OrderCreator / PaymentMethodsSheet + net-new attempts + growth_promo)
- РќРµ Р»РѕРјР°С‚СЊ: РїРѕР»РЅР°СЏ РѕРїР»Р°С‚Р° В· UserCards/one-click В· РЎР‘Рџ bind В· callback
- РџСЂРѕРІРµСЂРєР°: saved_card_store + sbp_account_token_store; order_creator + qa В§2.3 cart
- Р–РґС‘С‚ `/sbr` RED

## 2026-09-04 вЂ” docs: intake #75 РџСЂРёРІСЏР·РєР° СЃРїРѕСЃРѕР±Р° РѕРїР»Р°С‚С‹ Рё РїСЂРѕРјРѕ 11в‚Ѕ

- РўР— 1:1: `customer_tasks/РџСЂРёРІСЏР·РєР° СЃРїРѕСЃРѕР±Р° РѕРїР»Р°С‚С‹ Рё РїСЂРѕРјРѕ 11в‚Ѕ.md`
- РђСЂС‚РµС„Р°РєС‚С‹: `artifacts/payment_method_binding_promo_11rub/` (СЃРєСЂРёРЅ С€С‚РѕСЂРєРё + P2 placeholder)
- CBR / README: СЃС‚СЂРѕРєР° #75 В· СЃС‚Р°С‚СѓСЃ intake В· Р¶РґС‘С‚ `/spec`
- Р—Р°РґР°С‡Р° 1 РёР· 3 (РґРІРµ СЃР»РµРґСѓСЋС‰РёРµ РµС‰С‘ РЅРµ РїСЂРёСЃР»Р°РЅС‹)

## 2026-09-02 вЂ” feat: РЈРљ single-point lists (UkCatalogScope)

- `Platform::UkCatalogScope` вЂ” РІ `DEMO_SINGLE_POINT` С‚РѕР»СЊРєРѕ Point A + org РІ `/admin`
- Р‘РµР· single-point: С‚РѕР»СЊРєРѕ `active` sales_point (inactive/prog10 СЃРєСЂС‹С‚С‹)
- РЎРєСЂС‹С‚С‹ В«РќРѕРІР°СЏ С‚РѕС‡РєР°/РѕСЂРіВ» РІ single-point; show/edit РїРѕ id РЅРµ С‚СЂРѕРіР°РµРј
- РўРµСЃС‚С‹: uk_catalog_scope + uk_single_point_dashboard (9 runs PASS РІ Р·РѕРЅРµ)

## 2026-09-02 вЂ” feat: single Point A prod (Fly cleanup + DEMO_SINGLE_POINT)

- `Platform::ProdSinglePointCleanup` вЂ” inactive Р»РёС€РЅРёС… sales_point, Р±РµР· DELETE
- `DEMO_SINGLE_POINT=true` + `SHOP_DEFAULT_TENANT_ID` РІ `fly.toml`
- `fly:release` в†’ `platform:prod_single_point` РїРѕСЃР»Рµ `demo:seed`
- Deploy **v474** В· release `[platform:prod_single_point] OK`
- РђРєС‚РёРІРЅС‹: **demo-point-a** + demo-prep-kitchen (backend)
- РђСЂС‚РµС„Р°РєС‚: `artifacts/single_point_a/cleanup_2026-09-02.json`
- РўРµСЃС‚С‹: platform cleanup + environment_setup + RLS (19 runs PASS)

## 2026-09-02 вЂ” ops: ctx-trim С‚РѕРєРµРЅРѕРІ (rules + todo + ISSUES)

- РЈРґР°Р»РµРЅС‹ 7 РґСѓР±Р»РµР№ `.cursor/rules/coffeeos-*.mdc` РІ РєРѕСЂРЅРµ (РєР°РЅРѕРЅ вЂ” `project/`)
- РЎР¶Р°С‚ always-Р±Р°РЅРґР»: `.cursorrules`, `coffeeos-index.mdc`, `coffeeos-agent-workflow.mdc`
- `todo.md` в†’ stub deploy pending; РїРѕР»РЅС‹Р№ SPEC в†’ `session/archive/todo-shift-close-2026-09.md`
- ISSUES рџ”ґ вЂ” РєРѕСЂРѕС‚РєР°СЏ С‚Р°Р±Р»РёС†Р° (ID / СЃС‚Р°С‚СѓСЃ / Р±Р»РѕРєРµСЂ)
- `coffeeos-performance` globs: СѓР±СЂР°РЅ `test/**`
- **~600 tok/С…РѕРґ** always rules В· **~650 tok/СЃС‚Р°СЂС‚** todo+ISSUES В· **~200 tok/edit** Р±РµР· РґСѓР±Р»РµР№ globs

## 2026-09-01 вЂ” chore: uploads gitignore (РјРµРЅСЊС€Рµ С€СѓРјР° РІ git status)

- `.gitignore`: СѓР±СЂР°РЅ `!/public/uploads/products/` вЂ” РєР°СЂС‚РёРЅРєРё Р»РѕРєР°Р»СЊРЅРѕ/Fly СЌС„РµРјРµСЂРЅС‹, РІ git С‚РѕР»СЊРєРѕ README
- РЈРґР°Р»РµРЅС‹ 15 С‚РµСЃС‚РѕРІС‹С… С„Р°Р№Р»РѕРІ РёР· `public/uploads/products/` (MCP/Р»РѕРєР°Р»СЊРЅС‹Рµ Р·Р°РіСЂСѓР·РєРё)

## 2026-09-01 вЂ” ops: ctx-trim + Р°СЂС…РёРІ Р°РІРіСѓСЃС‚Р°

- РљРѕРјРјРёС‚ `e929d3bd` В· ops ref `5b1519a5`
- РљРѕРјР°РЅРґР° `/ctx-trim` + РїСЂР°РІРёР»Рѕ `coffeeos-context-hygiene.mdc` (СЂСѓС‡РЅРѕР№ + weekly РїС‚вЂ“РІСЃ)
- РђСЂС…РёРІ: `handoff-2026-08.md`, `session_state-2026-08.md`, `CHANGELOG-2026-08.md`, `ISSUES-resolved-through-2026-08.md`
- Р–РёРІС‹Рµ HANDOFF/SESSION/CHANGELOG/ISSUES вЂ” С€Р°РїРєР° + СЃРµРЅС‚СЏР±СЂСЊ; **~4k tok** СЌРєРѕРЅРѕРјРёРё РЅР° СЃС‚Р°СЂС‚Рµ vs РїСЂРѕРіР»Р°С‚С‹РІР°РЅРёРµ Р°РІРіСѓСЃС‚Р°
