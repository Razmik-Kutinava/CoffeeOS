# CoffeeOS — Information Security (ИБ)

Папка фиксирует контур доступа: **RBAC (staff)** → **tenant + RLS** → **ownership (shop)** → **ABAC-lite (будущее)**.

Документы по фазам; код приложения меняется только в фазах 1+ (отдельные SBR-задачи).

## Фазы

| Фаза | Папка | Статус | Deliverables |
|------|-------|--------|--------------|
| **0** | [`phase_0_baseline/`](phase_0_baseline/) | **baseline docs** (апрув владельца) | актёры, Shop API matrix, Staff RBAC matrix |
| **1** | [`phase_1_rbac_closure/`](phase_1_rbac_closure/) | **done** 2026-08-30 | shop ownership в коде, IDOR fixes |
| **2** | [`phase_2_abac_layer/`](phase_2_abac_layer/) | **done** 2026-08-30 | staff Pundit, role×tenant |
| **3** | [`phase_3_tenant_rls/`](phase_3_tenant_rls/) | **done** 2026-08-30 · апрув | RLS/GUC audit, device runbook, franchise/UK tests |
| 4–5 | [`00_ROADMAP_RBAC_ABAC.md`](00_ROADMAP_RBAC_ABAC.md) | roadmap | DoD RBAC, ABAC-lite |

## Phase 3 — что читать

| Документ | ID | Назначение |
|----------|-----|------------|
| [RLS_TENANT_AUDIT.md](phase_3_tenant_rls/RLS_TENANT_AUDIT.md) | IB-3-1 | GUC / row_security inventory |
| [DEVICE_TOKENS.md](phase_3_tenant_rls/DEVICE_TOKENS.md) | IB-3-4 | Создание/отзыв устройств |

## Phase 0 — что читать

| Документ | ID | Назначение |
|----------|-----|------------|
| [ACTORS_AND_ACCESS.md](phase_0_baseline/ACTORS_AND_ACCESS.md) | IB-0-1 | Все актёры: AuthN, tenant, AuthZ, RLS |
| [SHOP_API_ACCESS_MATRIX.md](phase_0_baseline/SHOP_API_ACCESS_MATRIX.md) | IB-0-2 | 100% `/shop/api/*`: ownership, IDOR, Phase 1 backlog |
| [STAFF_RBAC_MATRIX.md](phase_0_baseline/STAFF_RBAC_MATRIX.md) | IB-0-3 | Роли × панели, Pundit, Prog10 vs code |

## Связанные документы (вне папки)

- `docs/architecture/ROLES_AND_PERMISSIONS.md`
- `docs/stack/Authorization.md`
- `docs/guides/RLS_AND_TENANT_CONTEXT.md`
- Prog10: `docs/operations/milestones/veha_2/artifacts/prog10/staff-rbac/`

## Roadmap

Полная дорожная карта фаз 0→5: [00_ROADMAP_RBAC_ABAC.md](00_ROADMAP_RBAC_ABAC.md).
