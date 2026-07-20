# Скрины — режим Hidden (карточки товаров)

**Папка:** `artifacts/product_card_hidden_mode/screenshots/`  
**Назначение:** визуальный канон заказчика для режима **hidden** каталога витрины (горизонтальные ряды категорий).

**ТЗ:** [`../../../requirements/customer_tasks/Исправление режима отображения Hidden для карточек товаров.md`](../../../requirements/customer_tasks/Исправление%20режима%20отображения%20Hidden%20для%20карточек%20товаров.md)

| Файл | Роль | Что видно |
|------|------|-----------|
| `01_target_hidden_crop_as_should_be.png` | **Эталон — как нужно** | Разделы «Черный», «Холодные», «Сезонные»: crop фото (верх/центр чашки), placeholder «Нет фото», одинаковая высота карточек, название + цена |
| `02_as_is_broken_hidden_sliver.png` | **Баг — как сейчас** | Подпись «как сейчас»: в hidden («Холодные») тонкая полоска вместо превью; broken-image / сжатый «Нет фото» |

Не путать с:

- `artifacts/product_card_peek_cart/screenshots/` — другой ТЗ (peek-корзина на карточке товара)
- `artifacts/demo-feedback/screenshots/` — общие прогоны PDF / MCP

Копии этих двух кадров вне `product_card_hidden_mode/` не держать.
