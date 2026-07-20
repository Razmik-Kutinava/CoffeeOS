# Скрины — режим Hidden (карточки товаров)

**Папка:** `artifacts/product_card_hidden_mode/screenshots/`  
**Назначение:** визуальный канон заказчика для режима **hidden** каталога витрины (горизонтальные ряды категорий).

**ТЗ:** [`../../../requirements/customer_tasks/Исправление режима отображения Hidden для карточек товаров.md`](../../../requirements/customer_tasks/Исправление%20режима%20отображения%20Hidden%20для%20карточек%20товаров.md)

| Файл | Роль | Что видно |
|------|------|-----------|
| `01_target_hidden_crop_as_should_be.png` | **Эталон — как нужно** | Разделы «Черный», «Холодные»: crop фото, placeholder «Нет фото», одинаковая высота |
| `02_as_is_broken_hidden_sliver.png` | **Баг — как сейчас** | Подпись «как сейчас»: тонкая полоска / broken-image |
| `03_local_mcp_mobile_hidden_crop_2026-07-20.png` | **Доказательство MCP local mobile** | Chrome DevTools `390×844 mobile+touch` · crop media |
| `04_fly_accepted_hidden_chips_2026-07-20.png` | **Принято на Fly** | Hidden-чипы + «+сумма»; каталог crop; точка отката → [`../CHECKPOINT.md`](../CHECKPOINT.md) |

Не путать с:

- `artifacts/product_card_peek_cart/screenshots/` — другой ТЗ (peek-корзина на карточке товара)
- `artifacts/demo-feedback/screenshots/` — общие прогоны PDF / MCP

Копии этих двух кадров вне `product_card_hidden_mode/` не держать.
