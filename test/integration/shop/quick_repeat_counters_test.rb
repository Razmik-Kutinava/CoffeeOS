# frozen_string_literal: true

require "test_helper"

# Quick Repeat Bottom Sheet — Шаг F3 (ТЗ Шаги 9–10):
# счётчики −1+ на карточках повтора мгновенно персистятся в localStorage
# (переживают перезагрузку страницы), минимум 1, состояние в store — не в
# локальном $state компонента. Клик по карточке каталога остаётся
# переходом в Product (ТЗ Шаг 12, канон кастомизации).
class Shop::QuickRepeatCountersTest < ActionDispatch::IntegrationTest
  test "frequent cache exposes dedicated qty storage" do
    cache = File.read(Rails.root.join("app/frontend/lib/shopFrequentCache.js"))

    # Отдельный ключ количеств: сброс данных секции не трогает счётчики
    assert_includes cache, 'FREQUENT_QTY_KEY = "coffeeos_shop_frequent_qty_v1"'
    assert_includes cache, "export function readFrequentQty"
    assert_includes cache, "export function writeFrequentQty"
  end

  test "store keeps quantities and persists them instantly" do
    store = File.read(Rails.root.join("app/frontend/lib/frequentRepeatStore.js"))

    # Store количеств + синхронная запись в localStorage при каждом изменении
    assert_includes store, "export const frequentQuantities"
    assert_includes store, "export function setFrequentQty"
    assert_includes store, "writeFrequentQty("

    # Минимум 1 — «−» на единице не уводит в 0 (удаления из повтора нет)
    assert_includes store, "Math.max(1,"

    # Восстановление счётчиков при init из кэша (перезагрузка страницы)
    assert_includes store, "readFrequentQty"

    # Лимит размера lib-файла из SPEC (≤ 120 строк)
    assert_operator store.lines.count, :<=, 120
  end

  test "RepeatSection wires counters to store instead of local state" do
    section = File.read(Rails.root.join("app/frontend/components/RepeatSection.svelte"))

    assert_includes section, "frequentQuantities"
    assert_includes section, "setFrequentQty"
    refute_includes section, "let quantities = $state",
      "количества живут в store + localStorage, не в локальном state компонента"
  end

  test "catalog card click stays on Product route" do
    catalog = File.read(Rails.root.join("app/frontend/components/CategorySection.svelte"))

    # ТЗ Шаг 9 (клик → сразу в корзину) противоречит Шагу 12 (клик → модалка
    # модификаторов); канон — переход в Product, вопрос заказчику записан
    assert_includes catalog, "push(`/product/${product.id}`)"
  end

  # Ревью (замечание 1): ключ счётчика не должен зависеть от позиции карточки —
  # после фонового refresh порядок топ-3 меняется (частота/свежесть),
  # и qty по индексному ключу «переезжает» на чужой товар.
  test "counter key is stable: product + modifiers, no positional index" do
    store = File.read(Rails.root.join("app/frontend/lib/frequentRepeatStore.js"))
    section = File.read(Rails.root.join("app/frontend/components/RepeatSection.svelte"))

    assert_includes store, "export function frequentCardKey(item)"
    assert_includes store, "modifier_options",
      "ключ различает одинаковый product_id с разными модификаторами"
    refute_includes store, "${item.product_id}-${i}",
      "индекс в ключе — qty переезжает на чужую карточку при смене порядка"

    # Компонент использует общий ключ из store, без локального дубля keyOf
    assert_includes section, "frequentCardKey"
    refute_includes section, "function keyOf", "дубль ключа в компоненте — рассинхрон со store"
  end

  # Зеркало чистой логики счётчика (как mirror-тесты F1/F2)
  test "qty mirror: clamp to minimum and default" do
    assert_equal 1, next_qty(1, -1), "минимум 1 — вниз с единицы не уходим"
    assert_equal 2, next_qty(1, +1)
    assert_equal 1, next_qty(nil, 0), "нет записи в localStorage → 1 по умолчанию"
    assert_equal 3, next_qty(4, -1)
  end

  # Зеркало стабильности ключа: перестановка карточек не меняет ключи
  test "stable key mirror: reorder keeps same key per item" do
    a = { product_id: "p1", modifier_options: { "selected_modifiers" => [ "m1" ] } }
    b = { product_id: "p1", modifier_options: { "selected_modifiers" => [ "m2" ] } }

    keys_before = [ a, b ].map { |i| stable_key(i) }
    keys_after = [ b, a ].map { |i| stable_key(i) }

    assert_equal keys_before.sort, keys_after.sort, "ключ зависит только от товара+модификаторов"
    refute_equal stable_key(a), stable_key(b), "разные модификаторы → разные ключи"
  end

  private

  def next_qty(current, delta)
    [ 1, (current || 1) + delta ].max
  end

  def stable_key(item)
    "#{item[:product_id]}:#{item[:modifier_options].to_json}"
  end
end
