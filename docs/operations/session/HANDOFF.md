# HANDOFF вЂ” Р’РµС…Р° 2 (Р’РµС…Р° 1 **Р·Р°РєСЂС‹С‚Р°** 2026-06-19)

**Р”Р°С‚Р°:** 2026-07-02 (B1.13 S4 блок 2 — edit mode + replace_line)  
**Р’РµС‚РєР°:** `develop`  
**РџСЂРѕРґ:** https://coffeeos.fly.dev

### B1.14 вЂ” Р°РґСЂРµСЃ С‚РѕС‡РєРё + РІС‹Р±РѕСЂ С‚РѕС‡РєРё РІ С€Р°РїРєРµ РІРёС‚СЂРёРЅС‹

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| РўР— СЌС‚Р°Рї 0 | `[x]` 2026-06-23 вЂ” С‚РµРєСЃС‚ Р·Р°РєР°Р·С‡РёРєР° РґРѕСЃР»РѕРІРЅРѕ + РѕС‚РІРµС‚С‹ РІР»Р°РґРµР»СЊС†Р° Q1вЂ“Q10 |
| Р­С‚Р°Рї 0 JSON | [`b114_stage0_scope_2026-06-23.json`](../milestones/veha_2/artifacts/demo-feedback/b114_stage0_scope_2026-06-23.json) В· [`b114_screenshot_baseline_2026-06-23.json`](../milestones/veha_2/artifacts/demo-feedback/b114_screenshot_baseline_2026-06-23.json) |
| РЎРєСЂРёРЅС‹ В«РґРѕВ» | [`b114_shop_header_coffeeos_before_2026-06-23.png`](../milestones/veha_2/artifacts/demo-feedback/screenshots/b114_shop_header_coffeeos_before_2026-06-23.png) В· [`b114_uk_tenants_card_before_2026-06-23.png`](../milestones/veha_2/artifacts/demo-feedback/screenshots/b114_uk_tenants_card_before_2026-06-23.png) |
| РљРѕРґ | **B1.14-3d index map** `[x]` 2026-06-23 В· **B1.14-4** cart `[ ]` |
| **Deploy** | `bin/fly_deploy.sh` вЂ” WSL fix (`--remote-only`, staging `/mnt/c/`) В· РїРѕРІС‚РѕСЂРёС‚СЊ РґРµРїР»РѕР№ |
| **РЎР»РµРґСѓСЋС‰РёР№ С€Р°Рі** | **`go` B1.14-4** cart |
| **РђРіРµРЅС‚** | **СЃС‚РѕРї** вЂ” deploy РІР»Р°РґРµР»СЊС†Р° |

РўР—: [`B1_14_shop_tenant_address_header.md`](../milestones/veha_2/requirements/customer_tasks/B1_14_shop_tenant_address_header.md)

### B1.13 вЂ” РЅРѕРІР°СЏ РЅР°РІРёРіР°С†РёСЏ РІРёС‚СЂРёРЅС‹ (СЌРїРёРє S1вЂ“S4 + rev2)

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| **rev1** | S1 MCP `[x]` В· S2 MCP 9/9 `[x]` В· S3 РєРѕРґ `[x]` |
| **rev2 docs** | 4 С‚РµРєСЃС‚Р° РґРѕСЃР»РѕРІРЅРѕ: **S1-R1, S2a, S2b, S3-rev2** `[x]` 2026-06-25 |
| **S3-rev2** | РєРѕРґ `[x]` В· **Fly MCP 12/12** post-redeploy 2026-06-26 (bump-queue РЅР° СЃС‚РµРЅРґРµ) |
| **Q-rev1** | 2 РІРєР»Р°РґРєРё + РїСЂРѕС„РёР»СЊ РІ С€Р°РїРєРµ вЂ” **Р—РђРљР Р«РўРћ** |
| **Q-rev5** | minus @1 disabled вЂ” **Р—РђРљР Р«РўРћ** (S3-rev2) |
| **Q-rev2** | РїСѓСЃС‚Р°СЏ РєРѕСЂР·РёРЅР° вЂ” **РћРўРљР Р«РўРћ** |
| **Q-rev3,4** | **Р—РђРљР Р«РўРћ** 2026-06-26 |
| **S2b РїСЂРѕРіРѕРЅ 1** | СЃРєСЂРѕР»Р» 100/200 px вЂ” **РєРѕРґ `[x]`** |
| **S2b РїСЂРѕРіРѕРЅ 2** | localStorage СЂРµР¶РёРјР° вЂ” **РєРѕРґ `[x]`** |
| **S2a РїСЂРѕРіРѕРЅ 3** | РїСЂРёС‘РјРєР° СЃ С‚РѕРІР°СЂРѕРј вЂ” **РєРѕРґ `[x]`** |
| **B1.13 rev2** | S1-R1 + S2a/S2b/S3-rev2 · prog20 · MCP 22/22 | **`[x]` ЗАКРЫТ** апрув 2026-07-01 |
| **S4-канон** | docs `[x]` rev0b: tap вся карточка · edit только Product · PATCH · слияние | **`go` S4** (код) |
| **РђРіРµРЅС‚** | **СЃС‚РѕРї** |

РўР—: [`B1_13_shop_nav_profile_header.md`](../milestones/veha_2/requirements/customer_tasks/B1_13_shop_nav_profile_header.md)

### B1.13 rev1-S3 (Р°СЂС…РёРІ)

РљРѕРґ `6fcc9d8` вЂ” РїСЂРёС‘РјРєР° РїРµСЂРµРЅРµСЃРµРЅР° РІ В§ **S3-rev2** РІ [`B1_13`](../milestones/veha_2/requirements/customer_tasks/B1_13_shop_nav_profile_header.md).

### B1.12 вЂ” СЂРµРєСѓСЂСЂРµРЅС‚ + РѕРїР»Р°С‚Р° РІ 1 РєР»РёРє (Рў-Р‘Р°РЅРє, **rev2 nonPCI**)

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| **РўР— rev2** | **СЌС‚Р°Рї 0 docs** `[x]` 2026-06-24 вЂ” РґРѕСЃР»РѕРІРЅС‹Рµ 3 Р·Р°РґР°С‡Рё Р·Р°РєР°Р·С‡РёРєР° |
| **JSON СЌС‚Р°Рї 0** | [`b112_revision2_stage0_scope_2026-06-24.json`](../milestones/veha_2/artifacts/demo-feedback/b112_revision2_stage0_scope_2026-06-24.json) |
| **РЎРІРµСЂРєР° Рў-Р‘Р°РЅРє** | [`b112_tbank_nonpci_review_2026-06-24.json`](../milestones/veha_2/artifacts/demo-feedback/b112_tbank_nonpci_review_2026-06-24.json) |
| **РњР°РєРµС‚С‹** | [`1000008924.png`](../milestones/veha_2/artifacts/demo-feedback/screenshots/1000008924.png) R3 В· [`1000008925.png`](../milestones/veha_2/artifacts/demo-feedback/screenshots/1000008925.png) R2 |
| **Workflow** | **Р”РѕРєСѓРјРµРЅС‚ 1в†’R1в†’СЃС‚РѕРї в†’ РґРѕРєСѓРјРµРЅС‚ 2в†’R2в†’СЃС‚РѕРї в†’ РґРѕРєСѓРјРµРЅС‚ 3в†’R3** В· РѕРґРёРЅ `go` РЅР° R |
| **РљРѕРЅС„Р»РёРєС‚С‹** | Q-R2-1..3 **`[x]`** Р·Р°С„РёРєСЃРёСЂРѕРІР°РЅС‹ 2026-06-24 (С„Р°Р·Р° 0 gate R3) |
| **РљРѕРґ rev2** | R1+R2+R3 `[x]` OPS_PASS |
| **РљРѕРјРјРёС‚** | `c27eb7c` вЂ” С„Р°Р·Р° 3 MCP + С…РІРѕСЃС‚С‹ R2 |
| **Fly MCP** | [`b112_r3_fsm_ops_pass_2026-06-25.json`](../milestones/veha_2/artifacts/demo-feedback/b112_r3_fsm_ops_pass_2026-06-25.json) вЂ” **10/10** |
| **RSA Fly** | `[x]` `TBANK_RSA_PUBLIC_KEY` В· `card_data_ready: true` |
| **РҐРІРѕСЃС‚** | вЂ” |
| **РЎР»РµРґСѓСЋС‰РёР№ С€Р°Рі** | **Р°РїСЂСѓРІ Р·Р°РєР°Р·С‡РёРєР°** РЅР° СЌРїРёРє B1.12 rev2 |
| **РђРіРµРЅС‚** | **СЃС‚РѕРї** |

РўР—: [`B1_12_recurrent_payments.md`](../milestones/veha_2/requirements/customer_tasks/B1_12_recurrent_payments.md) В· runbook: [`TBANK_RECURRENT.md`](../milestones/veha_2/runbooks/TBANK_RECURRENT.md)

### B1.11 вЂ” СЂРµР¶РёРј СЂР°Р±РѕС‚С‹ С‚РѕС‡РєРё

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| РўР— СЌС‚Р°Рї 0 | `[x]` 2026-06-18 |
| РћС‚РІРµС‚С‹ Q1вЂ“Q10 + СЂР°СѓРЅРґ 2 | `[x]` 2026-06-19 В· [`b111_customer_answers_round2_2026-06-19.json`](../milestones/veha_2/artifacts/demo-feedback/b111_customer_answers_round2_2026-06-19.json) |
| **РЎС‚Р°С‚СѓСЃ** | **+ С€Р°РїРєР° РІРёС‚СЂРёРЅС‹** `schedule_display` В· demo A/B СЂР°Р·РЅРѕРµ СЂР°СЃРїРёСЃР°РЅРёРµ В· С‚РµСЃС‚С‹ 13/13 С€Р°РіР° |
| **Fly MCP** | `[x]` header A/B 2026-06-21 вЂ” [`b111_header_schedule_post_deploy_2026-06-21.json`](../milestones/veha_2/artifacts/demo-feedback/b111_header_schedule_post_deploy_2026-06-21.json) |
| **РЎР»РµРґСѓСЋС‰РёР№ С€Р°Рі** | **Р°РїСЂСѓРІ Р·Р°РєР°Р·С‡РёРєР°** В· В«РѕРєВ» РёР»Рё РїСЂР°РІРєРё |
| **РђРіРµРЅС‚** | **СЃС‚РѕРї** |

РўР—: [`B1_11_tenant_operating_hours.md`](../milestones/veha_2/requirements/customer_tasks/B1_11_tenant_operating_hours.md)

### B1.10 вЂ” СѓР±СЂР°С‚СЊ В«Р‘Р»РѕРіВ»

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| В«Р‘Р»РѕРіВ» СѓР±СЂР°РЅ РёР· С€Р°РїРєРё | `[x]` |
| РђРїСЂСѓРІ Р·Р°РєР°Р·С‡РёРєР° | `[x]` 2026-06-18 вЂ” [`b110_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b110_customer_approval_2026-06-18.json) |

РўР—: [`B1_10_remove_blog_nav.md`](../milestones/veha_2/requirements/customer_tasks/B1_10_remove_blog_nav.md)

### B1.7 вЂ” checkout (РІ С‚.С‡. BR-5)

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| BR-5 РІС‚РѕСЂРѕР№ С‚РѕРІР°СЂ РІ РєРѕСЂР·РёРЅСѓ | **Р·Р°РєСЂС‹С‚** В· Р°РїСЂСѓРІ `[x]` 2026-06-18 вЂ” [`b17_br5_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b17_br5_customer_approval_2026-06-18.json) |
| BR-6 РѕС‚РјРµРЅР° РЅР° `#/payment` | **Р·Р°РєСЂС‹С‚** В· Р°РїСЂСѓРІ `[x]` 2026-06-18 вЂ” [`b17_br6_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b17_br6_customer_approval_2026-06-18.json) |
| B1.9 toggle-РјРѕРґРёС„РёРєР°С‚РѕСЂС‹ | **Р·Р°РєСЂС‹С‚Р°** В· Р°РїСЂСѓРІ `[x]` 2026-06-18 вЂ” [`b19_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b19_customer_approval_2026-06-18.json) В· CC-2 РІ backlog |
| B1.7 С†РµР»РёРєРѕРј | **Р·Р°РєСЂС‹С‚Р°** В· Р°РїСЂСѓРІ `[x]` 2026-06-04 |

РўР—: [`B1_7_checkout_order_screen.md`](../milestones/veha_2/requirements/customer_tasks/B1_7_checkout_order_screen.md)

### B2.1 вЂ” С‚Р°Р±Р»Рѕ Р±Р°СЂРёСЃС‚Р°

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| MVP СЌС‚Р°РїС‹ 0вЂ“5 + СЂРµРІРёР·РёСЏ R0вЂ“R4 | `[x]` OPS_PASS |
| РђРїСЂСѓРІ Р·Р°РєР°Р·С‡РёРєР° | `[x]` 2026-06-18 вЂ” [`b21_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b21_customer_approval_2026-06-18.json) |
| Backlog С„Р°Р·Р° 2 | CBR В«Р‘Р»РѕРє 2 вЂ” backlogВ» (Р±СЂР°Рє, defect_reasons, Р·РІСѓРє РѕС‚РјРµРЅС‹, СЃРїРёСЃР°РЅРёРµ, prep_kitchen, СЌСЃРєР°Р»Р°С†РёСЏ) |
| **РЎР»РµРґСѓСЋС‰РёР№ С€Р°Рі** | **B2.2** СЌС‚Р°Рї 1 |

РўР—: [`B2_1_barista_order_board.md`](../milestones/veha_2/requirements/customer_tasks/B2_1_barista_order_board.md)

### B1.1 вЂ” СЌРєСЂР°РЅ СЃС‚Р°С‚СѓСЃР° Р·Р°РєР°Р·Р°

| Р­С‚Р°Рї | РЎС‚Р°С‚СѓСЃ |
|------|--------|
| 0 РњР°РїРїРёРЅРі + РјР°РєРµС‚С‹ | `[x]` вЂ” [`b11_stage0_mapping_2026-06-09.json`](../milestones/veha_2/artifacts/demo-feedback/b11_stage0_mapping_2026-06-09.json) |
| 1 РЎС‚Р°С‚РёС‡РµСЃРєРёР№ UI `/order/:id` | `[x]` вЂ” [`b11_stage1_static_ui_2026-06-09.json`](../milestones/veha_2/artifacts/demo-feedback/b11_stage1_static_ui_2026-06-09.json) |
| 2 WebSocket | `[x]` вЂ” [`b11_stage2_websocket_2026-06-09.json`](../milestones/veha_2/artifacts/demo-feedback/b11_stage2_websocket_2026-06-09.json) |
| 3 РћС‚РјРµРЅР° | `[x]` вЂ” [`b11_stage3_cancel_2026-06-09.json`](../milestones/veha_2/artifacts/demo-feedback/b11_stage3_cancel_2026-06-09.json) |
| 4 РўРµСЃС‚С‹ + MCP | `[x]` вЂ” [`b11_acceptance_2026-06-10.json`](../milestones/veha_2/artifacts/demo-feedback/b11_acceptance_2026-06-10.json) В· **deploy Fly** в†’ РїСЂРѕРіРѕРЅ Р·Р°РєР°Р·С‡РёРєР° |

РўР—: [`B1_1_order_status_progress.md`](../milestones/veha_2/requirements/customer_tasks/B1_1_order_status_progress.md)

### РЎРµСЃСЃРёСЏ 2026-06-08 вЂ” РїСЂР°РІРёР»Р° Cursor (СЃРёРЅС…СЂРѕРЅРёР·РёСЂРѕРІР°РЅРѕ)

**РљР°СЂС‚Р°:** `docs/operations/RULES_INDEX.md` В· РёРЅРґРµРєСЃ `.cursor/rules/coffeeos-index.mdc`

| Р§С‚Рѕ | Р“РґРµ |
|-----|-----|
| **РљРѕРјРјРёС‚ + ops (РєР°РЅРѕРЅ)** | `workflow/coffeeos-commit-ops.mdc` |
| **Р—Р°РґР°С‡Рё, go, РѕС‚С‡С‘С‚** | `workflow/coffeeos-task-workflow.mdc` |
| Workflow + project | `.cursor/rules/workflow/`, `.cursor/rules/project/` |
| Symlinks | `.cursor/rules/coffeeos-*.mdc` в†’ `project/` (СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚СЊ) |

**РљРѕРјРјРёС‚:** РІСЃРµРіРґР° РїРѕСЃР»Рµ С€Р°РіР° СЃ РїСЂР°РІРєР°РјРё, **РґРѕ РѕС‚С‡С‘С‚Р°**, Р±РµР· РІРѕРїСЂРѕСЃР°. **Push:** С‚РѕР»СЊРєРѕ РїРѕ СЏРІРЅРѕР№ РїСЂРѕСЃСЊР±Рµ. **РћС‚С‡С‘С‚:** С‚Р°Р±Р»РёС†Р° РЎРґРµР»Р°РЅРѕ | РќРµ СЃРґРµР»Р°РЅРѕ + `РљРѕРјРјРёС‚: <С…РµС€>`. **Scratch:** `scripts/scratch/`.

### РЎС‚Р°С‚СѓСЃ РІРµС… (РІР°Р¶РЅРѕ РґР»СЏ Р°РіРµРЅС‚Р°)

| Р’РµС…Р° | РћС„РёС†РёР°Р»СЊРЅРѕ | РџРѕ С„Р°РєС‚Сѓ |
|------|------------|----------|
| **Р’РµС…Р° 1** | **РќРµ Р·Р°РєСЂС‹С‚Р°** вЂ” РЅРµС‚ В§ I, H.3 Р¶РёРІРѕРіРѕ РґРµРјРѕ, РґР°С‚С‹/РїРѕРґРїРёСЃРё РІ С‡РµРєР»РёСЃС‚Рµ | РљРѕРґ AвЂ“G РЅР° `develop`, С‚РµСЃС‚С‹ Р·РµР»С‘РЅС‹Рµ, РґРµРїР»РѕР№ Fly РїРѕСЃР»Рµ v1.53 |
| **Р’РµС…Р° 2** | **РЎС‚Р°СЂС‚ СЂР°Р±РѕС‚** вЂ” РѕСЃРЅРѕРІРЅРѕР№ С„РѕРєСѓСЃ РЅРѕРІРѕРіРѕ РѕРєРЅР°/Р°РіРµРЅС‚Р° | Roadmap В§ В«Scale & StabilityВ» |

**Р РµР¶РёРј:** СЂР°Р·СЂР°Р±РѕС‚РєР° **Р’2 РёРґС‘С‚ РїР°СЂР°Р»Р»РµР»СЊРЅРѕ**. Р—Р°РєСЂС‹С‚РёРµ Р’1 вЂ” **Р·Р°РѕС‡РЅРѕ**, РєРѕРіРґР° РІР»Р°РґРµР»РµС† РїСЂРѕР№РґС‘С‚ H.3 Рё РєС‚Рѕ-С‚Рѕ РѕС‚РјРµС‚РёС‚ В§ I РІ `milestones/veha_1/checklists/CHECKLIST.md`. **РќРµ РїРёСЃР°С‚СЊ** РІ ops В«Р’РµС…Р° 1 Р·Р°РєСЂС‹С‚Р°В», РїРѕРєР° В§ I РЅРµ `[x]`.

---

## Р§С‚Рѕ СЃРґРµР»Р°РЅРѕ РІ СЌС‚РѕР№ СЃРµСЃСЃРёРё (РѕРїРµСЂР°С†РёРѕРЅРєР° + РєРѕРґ)

### РљРѕРґ (СѓР¶Рµ РЅР° `develop`)

| РћР±Р»Р°СЃС‚СЊ | Р§С‚Рѕ |
|---------|-----|
| **A** | Service Objects: `OrderCancellationService`, `OrderStatusUpdateService`, `PaymentStatusUpdater`, `MovementCreator` fix, СЂРµС„Р°РєС‚РѕСЂ РєРѕРЅС‚СЂРѕР»Р»РµСЂРѕРІ |
| **B** | MVP-РјРѕРґРµР»Рё, `Demo::EnvironmentSetup`, `demo:seed`, shop API, RLS-С‚РµСЃС‚С‹, РѕРЅР±РѕСЂРґРёРЅРі РЈРљ |
| **C** | RBAC integration-С‚РµСЃС‚С‹ РІСЃРµС… 7 СЂРѕР»РµР№ РїР°РЅРµР»РµР№ |
| **D** | MCP-РѕР±С…РѕРґ РїР°РЅРµР»РµР№ (Р¶СѓСЂРЅР°Р» РІ `PRACTICES.md` В§ Block D) |
| **E** | Svelte `/shop`: РєР°С‚Р°Р»РѕРі, РєРѕСЂР·РёРЅР°, РјРѕРґРёС„РёРєР°С‚РѕСЂС‹, mock-РѕРїР»Р°С‚Р°, РёСЃС‚РѕСЂРёСЏ |
| **F** | `Inventory::OrderRecipeDeduction`, РјРёРіСЂР°С†РёСЏ block F, prep_kitchen movements |
| **G** | Р“РёР±СЂРёРґ СЃРјРµРЅС‹: shop Р±РµР· СЃРјРµРЅС‹, barista С‚РѕР»СЊРєРѕ СЃ open shift; РѕС‚РјРµРЅР° СЃ reason + audit |
| **РРЅС„СЂР°** | `bin/ensure-server`, `lib/port_killer.rb`, `lib/dev_server.rb` |
| **РўРµСЃС‚С‹** | **479 runs, 0 failures** (2026-05-25) |
| **Review** | N+1 РІ `app/services/shop/order_creator.rb` вЂ” preload products |
| **Р”РµРїР»РѕР№** | РЈР±СЂР°РЅС‹ win32 npm bindings РёР· `package.json`; `Dockerfile`: `npm ci` (РєРѕРјРјРёС‚ `4a25187`) |

### Git (РїСѓС€Рё РЅР° develop)

1. **15 РєРѕРјРјРёС‚РѕРІ** вЂ” РїРѕР»РЅС‹Р№ РѕР±СЉС‘Рј Р’1 (db, services, frontend shop, tests, product docs, ops milestones РІ git, agents).
2. **1 РєРѕРјРјРёС‚** вЂ” fix Fly build (`fix(deploy): remove Windows-only npm bindingsвЂ¦`).

Р”РµРїР»РѕР№: `.github/workflows/deploy.yml` в†’ `flyctl deploy` РїСЂРё push РІ `develop`. РќРµ Р¶РґР°С‚СЊ Р°РІС‚РѕРґРµРїР»РѕР№ РѕС‚ РѕРґРЅРѕРіРѕ git Р±РµР· CI.

### Р”РѕРєСѓРјРµРЅС‚Р°С†РёСЏ РѕРїРµСЂР°С†РёРѕРЅРЅР°СЏ

| Р¤Р°Р№Р» | РЎС‚Р°С‚СѓСЃ |
|------|--------|
| `milestones/veha_1/checklists/CHECKLIST.md` | AвЂ“G, H.2 вЂ” `[x]`; H.3 РґРµРјРѕ вЂ” `[ ]`; В§ I вЂ” `[ ]` |
| `milestones/veha_1/reference/PRACTICES.md` | Р–СѓСЂРЅР°Р» Р±Р»РѕРєРѕРІ, С‚РµС…РґРѕР»Рі Р’1, QA H.2, code review |
| `milestones/veha_1/qa/QA_ACCEPTANCE_RUN.md` | РџСЂРѕС‚РѕРєРѕР» СЃСѓС…РѕР№ + MCP |
| `milestones/veha_1/qa/CODE_REVIEW.md` | CR-1 РёСЃРїСЂР°РІР»РµРЅ |
| `milestones/veha_1/reference/ORDER_ENTRY_AUDIT.md` | Р“РёР±СЂРёРґ A/B, СЂРµРµСЃС‚СЂ 8 РІС…РѕРґРѕРІ |
| `milestones/veha_1/reference/DEMO_LOGINS.md` | 9 РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№, РїР°СЂРѕР»СЊ `demo123456` |
| `milestones/veha_1/qa/LIVE_DEMO_SCENARIOS.md` | РўРµС…РЅРёС‡РµСЃРєРёРµ СЂСѓС‡РЅС‹Рµ СЃС†РµРЅР°СЂРёРё (**С„Р°Р№Р» РµСЃС‚СЊ Р»РѕРєР°Р»СЊРЅРѕ, РІ git РјРѕР¶РµС‚ РЅРµ Р±С‹С‚СЊ**) |
| `milestones/veha_1/qa/LIVE_DEMO_SCENARIOS_PLAIN.md` | РџСЂРѕСЃС‚РѕР№ СЏР·С‹Рє РґР»СЏ Р·Р°РєР°Р·С‡РёРєР° + URL РІРёС‚СЂРёРЅ (**С‚Рѕ Р¶Рµ**) |
| `docs/operations/journal/CHANGELOG.md` | v1.50вЂ“v1.54 |
| `docs/operations/session/SESSION_STATE.md` | РћР±РЅРѕРІР»С‘РЅ РїРѕРґ handoff |
| `.gitignore` | Р Р°Р·СЂРµС€С‘РЅ `docs/operations/milestones/**/*.md` |

### РџСЂРѕРґСѓРєС‚РѕРІС‹Рµ РґРѕРєРё (СЃРёРЅС…СЂРѕРЅ СЃ Р’1)

`01_Vision.md`, `02_functional.md`, `03_Business_Logic.md`, `ARCHITECTURE.md`, `development_roadmap.md` вЂ” **РєРѕРґ Р’1** РІ roadmap В«СЂРµР°Р»РёР·РѕРІР°РЅВ»; **ops-Р·Р°РєСЂС‹С‚РёРµ Р’1** вЂ” РѕС‚РґРµР»СЊРЅРѕ, СЃРј. С‡РµРєР»РёСЃС‚ В§ I.

---

## Р§С‚Рѕ **РЅРµ** Р·Р°РєСЂС‹С‚Рѕ (РѕСЃС‚Р°С‚РѕРє Р’1)

1. **H.3** вЂ” Р¶РёРІРѕРµ РґРµРјРѕ Р·Р°РєР°Р·С‡РёРєРѕРј РїРѕ `LIVE_DEMO_SCENARIOS_PLAIN.md` (РјРёРЅРёРјСѓРј 4 РёСЃС‚РѕСЂРёРё В§ 10).
2. **В§ I** С‡РµРєР»РёСЃС‚Р° вЂ” `SESSION_STATE` В«Р’РµС…Р° 1 Р·Р°РєСЂС‹С‚Р°В», Р·Р°РїРёСЃСЊ РІ CHANGELOG Рѕ Р·Р°РєСЂС‹С‚РёРё, С„РёРЅР°Р»СЊРЅС‹Р№ СЃРїРёСЃРѕРє С…РІРѕСЃС‚РѕРІ РІ `PRACTICES.md`.
3. **РљРѕРјРјРёС‚** С„Р°Р№Р»РѕРІ `LIVE_DEMO_SCENARIOS*.md` + Р°РєС‚СѓР°Р»СЊРЅС‹Р№ `CHECKLIST`/`README` РµСЃР»Рё РµС‰С‘ РЅРµ РІ СЂРµРїРѕР·РёС‚РѕСЂРёРё.
4. Р§РµРєР»РёСЃС‚ **B** Рї. QA 5.1 (РѕС‚РєР°С‚ РѕРЅР±РѕСЂРґРёРЅРіР° РїСЂРё РѕС€РёР±РєРµ) вЂ” `[ ]`, СЂСѓС‡РЅРѕР№ РЅРµРіР°С‚РёРІРЅС‹Р№ С‚РµСЃС‚.

---

## Р”Р»СЏ Р°РіРµРЅС‚Р° Р’РµС…Рё 2 вЂ” СЃ С‡РµРіРѕ РЅР°С‡Р°С‚СЊ

**Р¤РѕРєСѓСЃ:** Р’2. Р’1 РЅРµ РґРѕРґРµР»С‹РІР°С‚СЊ РІ СЌС‚РѕРј РѕРєРЅРµ, РєСЂРѕРјРµ СЏРІРЅРѕР№ РїСЂРѕСЃСЊР±С‹ (РґРµРјРѕ H.3, В§ I).

1. РџСЂРѕС‡РёС‚Р°С‚СЊ **`docs/product/development_roadmap.md`** В§ В«Р’Р•РҐРђ 2 (Scale & Stability)В».
2. РЎРѕР·РґР°С‚СЊ/РЅР°РїРѕР»РЅРёС‚СЊ **`docs/operations/milestones/veha_2/`** (СЃРµР№С‡Р°СЃ С‚РѕР»СЊРєРѕ `README.md`-Р·Р°РіРѕС‚РѕРІРєР°).
3. **РќРµ Р»РѕРјР°С‚СЊ** РіРёР±СЂРёРґ СЃРјРµРЅС‹ Р’1 Р±РµР· СЏРІРЅРѕРіРѕ РїСЂРѕРґСѓРєС‚Р° вЂ” РІ Р’2 РїР»Р°РЅРёСЂСѓРµС‚СЃСЏ СѓР¶РµСЃС‚РѕС‡РµРЅРёРµ (РµРґРёРЅР°СЏ СЃРјРµРЅР° РЅР° РІСЃРµС… РєР°РЅР°Р»Р°С…), СЃРј. `ORDER_ENTRY_AUDIT.md`.
4. РўРµС…РґРѕР»Рі Р’1 вЂ” С‚РѕР»СЊРєРѕ РІ **`milestones/veha_1/reference/PRACTICES.md`** В§ В«РўРµС…РґРѕР»Рі Р’1В», РЅРµ СЂР°Р·РјР°Р·С‹РІР°С‚СЊ РїРѕ Vision/Architecture.
5. РџСЂР°РІРёР»Р° РєРѕРґР°: `.cursor/rules/project/coffeeos-core.mdc`, `coffeeos-performance.mdc`, `coffeeos-services.mdc`; РєР°СЂС‚Р° вЂ” `RULES_INDEX.md`.

### РџСЂРёРѕСЂРёС‚РµС‚С‹ Р’2 (РёР· roadmap, РЅРµ РЅР°С‡Р°С‚Рѕ)

- Р РµР°Р»СЊРЅР°СЏ РѕРїР»Р°С‚Р° (`SHOP_SIMULATE_PAYMENT=0`, С€Р»СЋР·, callbacks).
- Offline-first / sync РґР»СЏ POS.
- Flutter + РєРёРѕСЃРє (Р·Р°РєР°Р·С‹ Р±РµР· СЃРјРµРЅС‹ РєР°Рє shop).
- Outbox (Solid Queue), Circuit Breaker (РєРѕРЅРµС† Р’2).
- Р Р°СЃС€РёСЂРµРЅРёРµ РєР°СЃСЃРѕРІРѕР№ РґРёСЃС†РёРїР»РёРЅС‹ РЅР° СЃРµС‚СЊ С‚РѕС‡РµРє.

### Р”РµРјРѕ-СЃС‚РµРЅРґ (develop в†’ Fly)

**URL РІРёС‚СЂРёРЅС‹:** РґРІР° СЂРµР¶РёРјР° вЂ” [`../dev/SHOP_URL_MODES.md`](../dev/SHOP_URL_MODES.md). РЎРµР№С‡Р°СЃ **СЂРµР¶РёРј B** (Fly): `?tenant_id=`. **Р РµР¶РёРј A** (РїСЂРѕРґ): `{slug}.shop.РґРѕРјРµРЅ` РїРѕСЃР»Рµ СЃРІРѕРµРіРѕ DNS/TLS.

**РџРѕСЃР»Рµ РґРµРїР»РѕСЏ** (H.3): `fly.toml` вЂ” `demo:seed` РІ release; **Р±РµР·** `SHOP_BASE_DOMAIN`.  
`fly ssh console -a coffeeos -C 'bin/rails demo:shop_urls'` вЂ” URL С‚РѕС‡РµРє A/B.

- РРЅСЃС‚СЂСѓРєС†РёСЏ: `FLY_DEMO_STAND.md`, С‡РµРєР»РёСЃС‚ В§ H.0 `veha_1/checklists/CHECKLIST.md`
- Р›РѕРіРёРЅС‹: `milestones/veha_1/reference/DEMO_LOGINS.md` (`demo123456`)
- **РџРµСЂРµРґР°С‚СЊ Р·Р°РєР°Р·С‡РёРєСѓ:** [`../demo/CUSTOMER_HANDOFF.md`](../demo/CUSTOMER_HANDOFF.md) + `LIVE_DEMO_SCENARIOS_PLAIN.md`
- РЎРІРѕР№ РґРѕРјРµРЅ: `veha_2/checklists/CHECKLIST.md` В§ **A-inf**

---

## Р‘Р»РѕРєРµСЂС‹

РќРµС‚ РґР»СЏ СЃС‚Р°СЂС‚Р° Р’2. Р”РµРїР»РѕР№ Fly РїРѕСЃР»Рµ v1.53 РґРѕР»Р¶РµРЅ СЃРѕР±РёСЂР°С‚СЊСЃСЏ; РїСЂРё РїР°РґРµРЅРёРё вЂ” СЃРјРѕС‚СЂРµС‚СЊ GitHub Actions в†’ Build Image в†’ `npm ci`.

---

## РћС‚РєСЂС‹С‚С‹Рµ РІРѕРїСЂРѕСЃС‹ (РЅР° РїСЂРѕРґСѓРєС‚/РІР»Р°РґРµР»СЊС†Р°)

- РџРѕРґС‚РІРµСЂР¶РґРµРЅРёРµ Р¶РёРІРѕРіРѕ РґРµРјРѕ H.3 Рё РґР°С‚Р° Р·Р°РєСЂС‹С‚РёСЏ Р’1.
- РџСЂРёРѕСЂРёС‚РµС‚ РІРЅСѓС‚СЂРё Р’2: РѕРїР»Р°С‚Р° vs offline vs Flutter.

---

**РџСЂРµРґС‹РґСѓС‰РёР№ РєРѕРЅС‚РµРєСЃС‚ (schema):** Р±Р°С‚С‡Рё B1вЂ“B5, `GAP_LIST_CORE_SCHEMA.md` вЂ” done; РЅРµ СЃРјРµС€РёРІР°С‚СЊ СЃ С‡РµРєР»РёСЃС‚РѕРј Р’1 Р±РµР· РЅРµРѕР±С…РѕРґРёРјРѕСЃС‚Рё.

