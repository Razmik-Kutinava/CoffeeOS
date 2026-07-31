# MCP Fly v416 — Quick Repeat ревизия (2026-07-31)

**Deploy:** Fly **v416** · `deployment-01KYWA7WEKGMXXYRJSNYQ59PDN`  
**Push:** `develop` → `0b71d5f9`  
**URL:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789

## Сверка (ревизия)

| Критерий | Эталон | Fly MCP | Вердикт |
|---|---|---|---|
| API hide | `has_active_order:true` + `frequent_items:[]` | CDP fetch 200 | **PASS** |
| UI hide «повторить» | скрин 07 / ТЗ NEW | `bodyHasRepeat=false`, нет pay 1-клик | **PASS** |
| Status full-width | feedback 07 (не inset) | `left/right=0`, `width=390=vw`, `z=60` | **PASS** |
| Канон 01–06 (повтор виден) | скрины `*_2026-07-31` | Aram с кучей active (#36) | **SKIP** |

## Доказательства

- `01_peek_status_full_width_no_repeat_v416.png`
- `02_catalog_cart_peek_active_no_repeat_v416.png` — cart peek, без «повторить»
- `03_catalog_active_no_repeat_v416.png` / `03b_…` — каталог без секции повтора
- `MCP_RESULT.json`

## Notes

- «Потеряно соединение…» Cable — как #35/#36, не блокер hide/width.
- Visible-repeat UI (01–06) — после выдачи/закрытия залипших active у Aram или отдельный MCP-клиент без active.
