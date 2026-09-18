# todo — #93 TASK_93-A: Деньги ↔ заказ (склад + webhook)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-A** |
| **Статус** | **REVIEW done** · CI green `35326857443` · deploy = L |
| **RED** | `fc97a432` |
| **GREEN** | `bba068f9` |
| **FIX** | `77291dc6` (trigger no-op) |
| **Entire** | `01M2SSQXT1V67AK260SH1P9RAX` |
| **CI** | tip `7c34314a` · run `35326857443` SUCCESS |
| **GATES** | G1–G3 met · G4→L |

## SBR

- [x] RED/GREEN/regress/unlazy
- [x] `/review` local · bugbot→FIX · security · Entire · push · **CI green**
- [ ] deploy = TASK_93-L (апрув)

## Acceptance A1–A6

```
A1 T-A1a T-A1b     PASS
A2 T-A2a T-A2b T-A2c PASS
A3 T-A3a T-A3b     PASS
A4 T-A4a T-A4b     PASS
A5 T-A5a T-A5b T-A5c PASS
A6 T-A6a T-A6b     PASS
```

## Next

deploy — только по апруву (блок L)
