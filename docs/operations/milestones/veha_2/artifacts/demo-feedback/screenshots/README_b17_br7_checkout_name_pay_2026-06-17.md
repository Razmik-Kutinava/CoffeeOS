# B1.7 BR-7 — «Оплатить» при пустом «Имя» (2026-06-17)

**Задача:** [B1_7_checkout_order_screen.md](../../requirements/customer_tasks/B1_7_checkout_order_screen.md) § BR-7  
**Статус:** **CLOSED** · MCP 7/7 · deploy 2026-06-17 · апрув `[x]` 2026-06-04 (B1.7)

## До (баг)

| Файл | Содержание |
|------|------------|
| [`01_name_empty_email_verified_pay_disabled.png`](b17_br7_checkout_name_pay_2026-06-17/01_name_empty_email_verified_pay_disabled.png) | Пустое «Имя», email подтверждён, **«Оплатить →» серая** |
| [`02_contacts_no_name_pay_disabled.png`](b17_br7_checkout_name_pay_2026-06-17/02_contacts_no_name_pay_disabled.png) | Контакты без имени, **кнопка неактивна** |

## После (fix)

| Файл | Содержание |
|------|------------|
| [`01_empty_name_email_verified_pay_enabled.png`](b17_br7_checkout_name_pay_after_2026-06-17/01_empty_name_email_verified_pay_enabled.png) | Пустое «Имя», verify email, **«Оплатить →» активна** |

**Прогон:** `ruby bin/b17_br7_checkout_name_pay_prep_fly.rb` → `node bin/b17_br7_checkout_name_pay_mcp.mjs`  
**Артефакт:** [`b17_br7_checkout_name_pay_post_deploy_2026-06-17.json`](../b17_br7_checkout_name_pay_post_deploy_2026-06-17.json)
