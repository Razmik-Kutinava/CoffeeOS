# Артефакты Веха 2

**Для агента:** здесь лежат только **отчёты QA/прогонов** (JSON, MD), не исходный код. Прогон 10 на Fly полностью под [`prog10/`](prog10/). Сводка после блока 13: [`prog10/_index/prog10_final_index.json`](prog10/_index/prog10_final_index.json). Реестр 9 точек: [`../PROG10_TENANTS.md`](../PROG10_TENANTS.md). Журнал прогона: [`../QA_ACCEPTANCE_RUN.md`](../QA_ACCEPTANCE_RUN.md) § «Прогон 10».

**Миграция (2026-06-02):** старые пути вида `artifacts/prog10_curl_full.json` заменены на `artifacts/prog10/smoke/prog10_curl_full.json`. Если в сессии встречается старый путь — смотреть [`prog10/README.md`](prog10/README.md).

| Папка | Зачем |
|-------|--------|
| [`demo-feedback/`](demo-feedback/) | PDF/скрины фидбека заказчика (§E). Цепочка с [`veha_1/artifacts`](../../veha_1/artifacts/). |
| [`prog10/`](prog10/) | Прогон 10 — curl/MCP отчёты на Fly. См. [`prog10/README.md`](prog10/README.md). |

**Не в git:** токены киосков (`/tmp/prog10_kiosk_tokens.json`), реальные секреты.
