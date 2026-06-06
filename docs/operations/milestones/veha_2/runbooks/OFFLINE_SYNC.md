# Offline-first и синхронизация — **В3**

**Зачем документ:** зафиксировать scope **до кодирования** — POS barista при обрыве сети, очередь заказов, идемпотентность. **Чеклист:** [`CHECKLIST.md`](CHECKLIST.md) § G — перенос в **В3**.

**Когда наполнять:** **В3** (не блокирует закрытие В2).

**Сейчас:** только описание; реализации нет (В1 STOP: offline).

---

## Целевое (из продукта)

- IndexedDB буфер на Rails+Hotwire POS
- Статусы UI: Online / Offline / Syncing
- При online — отправка очереди FIFO
- `client_uuid` + idempotency — один заказ в БД при повторах
- `drift_offset` для времени заказа (ARCHITECTURE.md)

---

## QA

`docs/agents/AGENTS/qa_scenarios.md` — **[V2] O-1, O-2, O-3**.

---

## Связь

[`ORDER_ENTRY_AUDIT.md`](ORDER_ENTRY_AUDIT.md) — строка «Offline sync POST» перед кодом.

**Статус 2026-05-25:** заготовка.
