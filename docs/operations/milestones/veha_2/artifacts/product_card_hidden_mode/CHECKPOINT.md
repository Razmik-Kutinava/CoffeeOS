# CHECKPOINT — Hidden cards + cart chips (принятое положение)

**Дата:** 2026-07-20  
**Ветка:** `develop`  
**Зачем:** зафиксировать рабочее UX на Fly, чтобы можно было **откатиться сюда** без угадываний.

## Откат (код)

```bash
git checkout fa4ae08   # ops-checkpoint (docs + этот скрин; код UI = a1abfa0)
git checkout a1abfa0   # только UI-фича (без последующих docs)
```

| Коммит | Что |
|--------|-----|
| **`fa4ae08`** | **RESTORE ops-checkpoint** (этот файл + скрин 04) |
| `a1abfa0` | catalog −15% · sheet vh prog26 · hidden chips |
| `8f74bac` | fly:release ConcurrentMigrationError |
| `b6b8927` | CartSheet onerror · `demo:catalog_images` |
| `7124c16` | docs WSL rolldown |

## Что принято (визуал Fly)

Скрин: [`screenshots/04_fly_accepted_hidden_chips_2026-07-20.png`](screenshots/04_fly_accepted_hidden_chips_2026-07-20.png)

- Hidden шторка: **ряд чипов с фото** + кнопка «+сумма» (не чип «только цена»).
- Каталог: меньшие карточки; crop / «Нет фото» на месте.
- После deploy: `fly ssh console -a coffeeos -C "bin/rails demo:catalog_images"` (HTTPS Unsplash для demo-point-a).

## Не трогаем при откате

Не придумывать новые высоты/раскладки — канон B1.13-S2 + этот скрин.
