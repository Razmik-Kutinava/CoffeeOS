# MCP #82 — Fly v482 — 2026-09-07

Point A: `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
Release: **v482** · tip `4f980e96` · image `deployment-01M1XHPPYGV4M7QBCGZAZK4CQB`

| Check | Result | Notes |
|-------|--------|-------|
| 0.1 Fly version | PASS | v482 |
| 0.2 `/up` + shop | PASS | 200 |
| 0.3 SMS secrets | PASS | `SMS_RU_API_ID` + `SMS_RU_FROM` present |
| 0.4 Solid Queue | PASS | cascade job ran |
| 1.1 hide-on-ready | PASS | sheet gone after ready (no «Готов» widget) |
| 1.2 reload / active | PASS | home without status sheet after ready |
| 1.3 accepted/preparing sheet | PASS | before screenshot with sheet |
| 1.4 repeat after hide | PASS | cart/CTA usable (not stuck empty+0) |
| 2.1 enqueue cascade | PASS | `GuestOrderBroadcaster` + job |
| 2.2 offline SMS | PASS | `order_notification_logs` channel=`sms` status=`sent` id=`cd93b9f2…` |
| 2.3 online skip | SKIP | hide-on-ready unsubscribed → SMS path (expected) |
| 2.4 dedupe | PASS | second `perform_now` → `SMS skipped: already sent` |

**SMOKE_OK:** yes  
**Local:** skip (CI green `34103028345`)  
**Fly MCP:** **PASS**

Screens: `01_before_accepted_sheet.png`, `02_after_ready_sheet_gone.png`  
SMS evidence: log id only (no full phone in artifact).
