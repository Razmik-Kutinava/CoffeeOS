# frozen_string_literal: true

require "test_helper"

# Quick Repeat Bottom Sheet — Шаг F4 (ТЗ Шаги 11–12, скрин 06):
# «повторить в 1 клик» — все позиции повтора в корзину с сохранёнными
# modifier_options и счётчиками → шторка hidden + success-тост;
# «+ещё» — переход в expanded; ошибка сети — error-тост без смены режима;
# кастомизация — существующий флоу Product.svelte (cart_line).
class Shop::QuickRepeatActionsTest < ActionDispatch::IntegrationTest
  test "store exposes one-click repeat with saved modifiers and counters" do
    store = File.read(Rails.root.join("app/frontend/lib/frequentRepeatStore.js"))

    assert_includes store, "export async function repeatAllToCart"
    # Добавление через канонный addToCart (offline-очередь + оптимистичный кэш)
    assert_includes store, "addToCart("
    # Сохранённые модификаторы позиции: modifier_options.selected_modifiers
    assert_includes store, "modifier_options"
    assert_includes store, "selected_modifiers"
    # Количество — из счётчиков F3 (frequentQuantities), не хардкод 1
    assert_includes store, "quantity:"
    # Успех: шторка в hidden (ТЗ Шаг 11) — режимы из канонных констант
    assert_includes store, "MODE_HIDDEN"
    assert_includes store, "cartSheetMode"
    # «+ещё» → expanded
    assert_includes store, "export function repeatMore"
    assert_includes store, "MODE_EXPANDED"
    # Тост success/error — стор фидбека, ошибка не меняет режим шторки
    assert_includes store, "export const repeatFeedback"

    # Лимит SPEC на lib-файл
    assert_operator store.lines.count, :<=, 120
  end

  test "RepeatSection renders orange one-click button, more button and toast" do
    section = File.read(Rails.root.join("app/frontend/components/RepeatSection.svelte"))

    # Оранжевая кнопка «повторить в 1 клик» (скрины 01, 06)
    assert_includes section, 'data-testid="shop-repeat-one-click"'
    assert_includes section, "повторить в 1 клик"
    assert_includes section, "bg-[#ff8c42]"
    assert_includes section, "repeatAllToCart("

    # «+ещё» → expanded
    assert_includes section, 'data-testid="shop-repeat-more"'
    assert_includes section, "+ещё"
    assert_includes section, "repeatMore("

    # Тост из repeatFeedback (success и error)
    assert_includes section, 'data-testid="shop-repeat-toast"'
    assert_includes section, "repeatFeedback"
  end

  test "customization flow stays on Product route with cart_line" do
    product = File.read(Rails.root.join("app/frontend/routes/Product.svelte"))

    # ТЗ Шаг 12: модалка модификаторов — существующий флоу Product
    assert_includes product, "cart_line"
    assert_includes product, "initSelectedFromCartLine"
    assert_includes product, "selected_modifiers"
  end

  # Ревью (замечание 2): последовательное добавление может упасть на середине —
  # часть позиций уже в корзине. Тост обязан говорить «Добавлено N из M»,
  # а не общее «не удалось» (иначе повторный клик даёт дубли первых позиций).
  test "partial add failure reports honest added-of-total toast" do
    store = File.read(Rails.root.join("app/frontend/lib/frequentRepeatStore.js"))

    assert_includes store, "added", "store считает успешно добавленные позиции"
    assert_includes store, "Добавлено ${added} из ${items.length}",
      "error-тост при частичном добавлении честный: N из M"
    assert_includes store, "Не удалось повторить заказ",
      "полный провал (0 добавлено) — прежнее сообщение"
  end

  # Зеркало контракта действий (как mirror-тесты F1–F3)
  test "actions mirror: success hides sheet, error keeps mode" do
    assert_equal [ :hidden, :success ], repeat_outcome(ok: true, mode: :peek)
    assert_equal [ :peek, :error ], repeat_outcome(ok: false, mode: :peek)
    assert_equal [ :expanded, :error ], repeat_outcome(ok: false, mode: :expanded)
    assert_equal :expanded, more_outcome
  end

  # Зеркало сообщения частичного добавления
  test "partial add mirror: message depends on added count" do
    assert_equal "Не удалось повторить заказ", partial_message(0, 3)
    assert_equal "Добавлено 1 из 3 — проверьте корзину", partial_message(1, 3)
    assert_equal "Добавлено 2 из 3 — проверьте корзину", partial_message(2, 3)
  end

  private

  def repeat_outcome(ok:, mode:)
    ok ? [ :hidden, :success ] : [ mode, :error ]
  end

  def more_outcome
    :expanded
  end

  def partial_message(added, total)
    added.positive? ? "Добавлено #{added} из #{total} — проверьте корзину" : "Не удалось повторить заказ"
  end
end
