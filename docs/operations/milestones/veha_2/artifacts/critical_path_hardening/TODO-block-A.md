# todo — #93 TASK_93-A: Деньги ↔ заказ (склад + webhook)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-A** |
| **Тип** | SBR · hot-path оплата / склад |
| **Статус** | **GATES G1–G3 met** · Next: `/review` |
| **RED** | `fc97a432` |
| **GREEN** | `bba068f9` |
| **Entire** | `01M2SSQXT1V67AK260SH1P9RAX` |
| **GATES** | [`GATES-block-A.md`](GATES-block-A.md) · G1–G3 met · G4 abandoned→L |
| **Ветка** | `develop` |

## SBR

- [x] PHASE 0–2 · RED · GREEN
- [x] `/regress` G1 40/0 · G2 139/0
- [x] `/unlazy` --approve/--reverify G1–G3 met · G4→L
- [ ] PHASE 3 `/review` — таблица A1–A6 · push · **без deploy**

## Next

`/review`
