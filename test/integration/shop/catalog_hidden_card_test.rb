# frozen_string_literal: true

require "test_helper"

# Hidden mode catalog cards — SBR PHASE 2 RED
# ТЗ: customer_tasks/Исправление режима отображения Hidden для карточек товаров.md
# Эталон: artifacts/product_card_hidden_mode/screenshots/01_target_hidden_crop_as_should_be.png
# As-is:  artifacts/product_card_hidden_mode/screenshots/02_as_is_broken_hidden_sliver.png
#
# Намеренный RED [TDD] — не ISSUES. Падают, пока нет контракта crop/placeholder/режимов.
class Shop::CatalogHiddenCardTest < ActionDispatch::IntegrationTest
  def category_section
    @category_section ||= File.read(Rails.root.join("app/frontend/components/CategorySection.svelte"))
  end

  def cart_sheet
    @cart_sheet ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  # --- S1: hidden + image → crop center/top, фиксированный media-box ------------

  test "S1 Then: catalog card has media box testid and fixed aspect so crop is not a sliver" do
    src = category_section

    assert_includes src, 'data-testid="shop-catalog-card"',
      "S1: у карточки каталога нужен data-testid=\"shop-catalog-card\""

    assert_includes src, 'data-testid="shop-catalog-card-media"',
      "S1: контейнер превью data-testid=\"shop-catalog-card-media\" (фиксированная высота/aspect)"

    assert_includes src, 'data-testid="shop-catalog-card-image"',
      "S1: img превью data-testid=\"shop-catalog-card-image\""

    assert_match(/object-cover/, src,
      "S1: изображение должно обрезаться (object-cover)")

    crop_anchor =
      src.match?(/object-top|object-center|object-\[center_top\]|object-position/) ||
      src.include?("objectPosition")
    assert crop_anchor,
      "S1: нужен crop center или top (object-top / object-center / object-position) — эталон заказчика"

    fixed_box =
      src.match?(/aspect-\[|aspect-video|min-h-28|min-h-\[|catalog-card-media/) ||
      src.include?("aspect-ratio")
    assert fixed_box,
      "S1: media-box должен фиксировать высоту/aspect (не схлопываться в полоску как на as-is)"
  end

  # --- S2: без изображения → placeholder «Нет фото» ---------------------------

  test "S2 Then: missing image shows Нет фото placeholder with testid" do
    src = category_section

    assert_includes src, "Нет фото",
      "S2: placeholder текст «Нет фото»"

    assert_includes src, 'data-testid="shop-catalog-card-no-photo"',
      "S2: placeholder data-testid=\"shop-catalog-card-no-photo\" на тёмном фоне"
  end

  # --- S3: hidden ↔ peek/expanded — не ломать CartSheet; карточки знают mode --

  test "S3 Then: CategorySection reacts to cart sheet mode for hidden density" do
    src = category_section

    mode_aware =
      src.include?("cartSheetMode") ||
      src.include?("MODE_HIDDEN") ||
      src.match?(/data-catalog-card-mode|data-card-density/)
    assert mode_aware,
      "S3: CategorySection должен учитывать режим шторки (cartSheetMode / MODE_HIDDEN / data-catalog-card-mode), " \
      "чтобы hidden→peek→expanded не скакал без контракта плотности"
  end

  test "S3 Guard: CartSheet peek and expanded markers stay intact" do
    sheet = cart_sheet

    assert_includes sheet, 'data-testid="shop-cart-peek-list"'
    assert_includes sheet, 'data-testid="shop-cart-grid-card"'
    assert_includes sheet, 'data-testid="shop-cart-hidden-chip"'
    assert_includes sheet, "MODE_PEEK"
    assert_includes sheet, "MODE_EXPANDED"
    assert_includes sheet, "MODE_HIDDEN"
  end

  # --- S4: горизонтальный ряд — равная высота, имя, цена ---------------------

  test "S4 Then: horizontal row cards share equal media height and show name+price" do
    src = category_section

    assert_match(/overflow-x-auto/, src,
      "S4: горизонтальный скролл категории")

    assert_includes src, 'data-testid="shop-catalog-card-name"',
      "S4: название data-testid=\"shop-catalog-card-name\""

    assert_includes src, 'data-testid="shop-catalog-card-price"',
      "S4: цена data-testid=\"shop-catalog-card-price\""

    # Одинаковая высота media у всех карточек ряда — общий класс/aspect, не «полоска».
    assert_match(/shop-catalog-card-media|catalog-card-media|aspect-\[/, src,
      "S4: общий media-box / aspect для равной высоты карточек в ряду")

    # −15%: карточки уже w-40 (10rem) → ~8.5rem
    assert_match(/w-\[8\.5rem\]|w-36/, src,
      "S4: карточки каталога уменьшены (~15% от w-40)")
  end

  # --- Edge: 404 → fallback; длинное имя → одна строка с ellipsis -------------

  test "Edge: image onerror falls back to Нет фото placeholder" do
    src = category_section

    assert_match(/onerror|on:error|onError|imgError|imageBroken|image_failed/i, src,
      "Edge: при 404/ошибке загрузки — fallback на placeholder «Нет фото» (не broken-icon)")
  end

  test "Edge: long product name truncates to single line with ellipsis" do
    src = category_section

    single_line =
      src.match?(/line-clamp-1|truncate/) ||
      src.include?("text-overflow: ellipsis")
    assert single_line,
      "Edge: длинное имя в hidden — одна строка с … (line-clamp-1 / truncate), не вылезает за карточку"
  end
end
