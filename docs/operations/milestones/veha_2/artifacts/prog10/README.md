# Прогон 10 — артефакты QA (Fly)

Стенд: `https://coffeeos.fly.dev` · реестр точек: [`../../PROG10_TENANTS.md`](../../PROG10_TENANTS.md).

| Папка | Содержимое |
|-------|------------|
| [`_index/`](_index/) | Сводки, индекс, connectivity-отчёт, `tenant_ids.json` |
| [`smoke/`](smoke/) | Ранние полные прогоны: curl 9×, stress, kiosk batch, shop URLs |
| [`kiosk/`](kiosk/) | Киоск auth, kiosk→barista, CR-05, mock card |
| [`shop/`](shop/) | Витрина 5 точек: curl/MCP, SHP-03 |
| [`staff-rbac/`](staff-rbac/) | Изоляция 9 точек, MCP staff, RBAC матрица |
| [`connectivity/`](connectivity/) | CON-02 Fly (PTS demo-a/b) |
| [`platform-ent/`](platform-ent/) | Карточка точки УК (ENT-02/07/08) |
| [`warehouse/`](warehouse/) | Блок 12: barista ↔ цех |

**Главный индекс после блока 13:** [`_index/prog10_final_index.json`](_index/prog10_final_index.json).

**Скрипты:** `bin/prog10_*` в корне репо (пути OUT обновлены под эту структуру).
