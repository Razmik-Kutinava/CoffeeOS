# MCP Point A — #71 remember receipt email · Fly **v481** · 2026-09-07

**App:** https://coffeeos.fly.dev  
**Release:** **v481** · tip `a9148d9b`  
**Tenant:** Point A `2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Путь:** forced `#/payment-result?status=ok&order_id=379472aa-…` (заказ переведён в `accepted` для finalize)  
**Вердикт:** **PASS** (R0–R6)

| # | Сценарий | Результат | Evidence |
|---|----------|-----------|----------|
| R0 | чистая LS receipt | **PASS** | ключ `shop_receipt_email:…` отсутствует |
| R1 | первый success — блок есть | **PASS** | `r1_first_success_email_block.png` · `order-success-email-block` |
| R2 | submit → LS | **PASS** | email `mcp71-remember-20260907@example.com` в LS · redirect `#/` |
| R3 | второй success — блока нет | **PASS** | `r3_second_success_no_email_block.png` · CTA `payment-result-continue` |
| R4 | Skip не запоминает | **PASS** | после Skip LS пуст · повторный success снова с блоком (нужен remount/cache-bust URL) |
| R5 | profile email ≠ hide | **PASS** | prefill из profile, блок всё равно есть |
| R6 | tenant key | **PASS** | ключ scoped `shop_receipt_email:{tenant_id}` · чужой tenant пуст |

**Fly MCP:** **PASS**
