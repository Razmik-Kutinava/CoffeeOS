# T-Bank webhook plain `OK` — Fly v459 MCP

**Дата:** 2026-08-27  
**Fly:** **v459** · image `deployment-01M11RD5W850BADA7T5CS7C5Q5`  
**GREEN code:** `0ee54a97` (+ CI fix `86ead973`) на develop, в образе deploy

| Проверка | Результат |
|----------|-----------|
| Local tests plain OK | **PASS** (`tbank_controller` + adapter + fiscal api: 56/0 в одном прогоне) |
| Endpoint `/callbacks/tbank` жив | **PASS** |
| Invalid Token → 401 | **PASS** `{"error":"invalid token"}` |
| Fly имеет GREEN webhook OK | **YES** · v459 · `render plain: "OK"` ×4 в контроллере на машине |
| Success body plain OK на Fly | **PASS** Rack MockRequest Status=NEW → `[200, "OK", "text/plain; charset=utf-8"]` |
| Point A shop smoke | **PASS** |
| Fiscal ветка не ломали (local) | **PASS** |
| Live bank webhook | **PASS*** bank REJECTED → Completed **200** (success path) |

**Local:** PASS  
**Fly MCP:** **PASS**  
**Deploy:** v459 (апрув владельца)
