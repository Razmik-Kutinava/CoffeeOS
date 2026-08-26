# #71 — Email-сбор после оплаты (Callcheck-флоу)

**Задача:** [Email-сбор после оплаты (Callcheck-флоу)](../requirements/customer_tasks/Email-сбор%20после%20оплаты%20(Callcheck-флоу).md)

| Файл | Описание |
|------|----------|
| [`MCP_DEPLOY_CHECKLIST.md`](MCP_DEPLOY_CHECKLIST.md) | **Для агента после deploy:** что проверить через MCP Point A + API/bounce/пачка |
| `mcp/fly_vNNN_…/` | Скрины + `MCP_RESULT.md` — после приёмки |

**API:** `POST /shop/api/orders/:id/email` · bounce: `POST /callbacks/email/bounce` + HMAC  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Entire:** `01M0Z3E52ZCDTRECJT1F22G954` · CI green `32971396113`
