# MCP — B2.2 stage-1 · Fly v493 · 2026-09-08

**Вердикт: PASS** (Fly **v493**)

| Check | Result |
|-------|--------|
| B1–B5 | PASS (v490) |
| B6 search hides empty categories | **PASS** v493 — categories `display:none`, 0 cards |
| C1–C3 | PASS |

**Root cause B6:** `style`/`script` были вне `content_for`; `layouts/barista` без `yield` их отбрасывал. Исправлено: скрипт внутри `content_for` + `turbo:load`.

Скрины: `barista_menu_after_stage1.png`, `create_order_alive.png`
