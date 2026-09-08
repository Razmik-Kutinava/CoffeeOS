# MCP / post-deploy — B2.2 этап 1 (только)

| | |
|---|---|
| **Задача** | единый layout `/barista/menu` (сетка + панель корзины) |
| **GREEN** | `7c76a125` · tip REVIEW CI `f03a46e1` |
| **CI** | [34208612629](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34208612629) green |
| **Логин** | `barista-a@demo.coffeeos.local` / `demo123456` |
| **Артефакт** | `b22_stage1_mcp_<date>/` · `mcp_result.json` + PNG |

**НЕ этапы 2–5:** модификаторы/qty · sold_out · POS · убрать cash/create-order.

## DoD этап 1

| # | PASS |
|---|------|
| B1 | `/barista/menu` 200 |
| B2 | `#menu-pos-layout` · `#menu-product-grid` · `#menu-cart-panel` |
| B3 | карточки `data-menu-product-card` + цена |
| B4 | «Корзина» / «Корзина пуста» |
| B5 | `#menu-pay-btn` disabled |
| B6 | поиск скрывает пустые категории |
| C1 | sidebar: Меню **и** Создать |
| C2 | `/barista/create-order` жив |
| C3 | `/barista` табло OK |

## Вердикт

Этап 1 закрыт на стенде: B1–B6 + C1–C3 PASS + артефакт. CBR `[x]` — только после «ок» владельца.
