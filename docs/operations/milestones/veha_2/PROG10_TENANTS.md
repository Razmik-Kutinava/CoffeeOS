# Прогон 10 — реестр точек (Fly, 2026-06-01)

**Стенд:** `https://coffeeos.fly.dev`  
**Скрипт curl:** `ruby bin/prog10_fly_smoke.rb`  
**Отчёт JSON:** [`artifacts/prog10_curl_report.json`](artifacts/prog10_curl_report.json)  
**Retry (rate limit):** [`artifacts/prog10_curl_retry.json`](artifacts/prog10_curl_retry.json)

## 3 org × 3 точки (MCP УК + demo seed)

| Org | slug | Точки (slug → tenant_id) |
|-----|------|---------------------------|
| Demo CoffeeOS | `demo-coffeeos` | `demo-point-a` → `2fdee1ac-4674-41ee-b89e-87b45643f789`; `demo-point-b` → `655aaccb-004a-4bb9-a50a-ce618854dda3`; `demo-prep-kitchen` → `d47165db-81c9-4e9d-bc50-e37fe610d86c` |
| Prog10 Network Alpha | `prog10-net-alpha-0601` | `prog10-alpha-p1` → `1c064640-4301-4435-8ded-c92fb075e9cc`; `prog10-alpha-p2` → `edf8a0a9-38e7-4049-b9c6-3e08c6c23a76`; `prog10-alpha-p3` → `d29fcf3a-da72-4a95-9683-9cfa71a2d865` |
| Prog10 Network Beta | `prog10-net-beta-0601` | `prog10-beta-p1` → `03a4d457-e16f-4998-b764-69b3de083732`; `prog10-beta-p2` → `628a937b-f4e2-43b7-bd7f-9fa44f031460`; `prog10-beta-p3` → `b57c2a88-91a5-481e-b44f-29e29c77cfb5` |

Org IDs (УК): Alpha `83a6d574-e0cd-411f-add9-a5d8a08451ec`; Beta `efc04caf-ca79-4f2a-a231-eb82f02d2787`.

**Киоск (curl):** устройство «Prog10 Kiosk MCP» на Demo A — токен в manager/devices (не коммитить); curl `POST /kiosk/api/auth` → order **accepted** (см. отчёт).

## Curl TENANTS (9 точек продаж + smoke QA6)

```bash
export TENANTS="2fdee1ac-4674-41ee-b89e-87b45643f789,655aaccb-004a-4bb9-a50a-ce618854dda3,1c064640-4301-4435-8ded-c92fb075e9cc,edf8a0a9-38e7-4049-b9c6-3e08c6c23a76,d29fcf3a-da72-4a95-9683-9cfa71a2d865,03a4d457-e16f-4998-b764-69b3de083732,628a937b-f4e2-43b7-bd7f-9fa44f031460,b57c2a88-91a5-481e-b44f-29e29c77cfb5,d8e287c5-5524-423c-8e5a-605570c69517"
export DEVICE_TOKEN="<из manager/devices, Prog10 Kiosk MCP>"
ruby bin/prog10_fly_smoke.rb
```

Smoke org QA6: `d8e287c5-5524-423c-8e5a-605570c69517` (доп. точка, прогон 6).
