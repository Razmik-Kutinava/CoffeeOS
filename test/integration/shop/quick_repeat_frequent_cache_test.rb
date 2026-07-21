# frozen_string_literal: true

require "test_helper"

# Quick Repeat Bottom Sheet — Шаг F1 (ТЗ Шаг 5):
# клиентский кэш частых товаров в localStorage (паттерн shopCartCache.js):
# мгновенная инициализация из кэша (< 50 мс, без сети) + фоновый GET
# /shop/api/frequent_products; при offline/500 — кэш без блокировки UI.
class Shop::QuickRepeatFrequentCacheTest < ActionDispatch::IntegrationTest
  test "shopFrequentCache follows shopCartCache localStorage pattern" do
    cache = File.read(Rails.root.join("app/frontend/lib/shopFrequentCache.js"))

    assert_includes cache, 'FREQUENT_CACHE_KEY = "coffeeos_shop_frequent_v1"'
    assert_includes cache, "readShopLocalStorage"
    assert_includes cache, "writeShopLocalStorage"
    assert_includes cache, "removeShopLocalStorage"
    assert_includes cache, "readFrequentCache"
    assert_includes cache, "writeFrequentCache"
    assert_includes cache, "clearFrequentCache"
  end

  test "frequentRepeatStore inits from cache synchronously and refreshes in background" do
    store = File.read(Rails.root.join("app/frontend/lib/frequentRepeatStore.js"))

    # Мгновенный старт из localStorage — без ожидания сети
    assert_includes store, "initFrequentFromCache"
    assert_includes store, "readFrequentCache"

    # Фоновая актуализация через существующий api-хелпер
    assert_includes store, "refreshFrequentProducts"
    assert_includes store, 'api("/frequent_products")'
    assert_includes store, "writeFrequentCache"

    # Svelte stores для секции «повторить» и каталога expanded
    assert_includes store, "frequentItems"
    assert_includes store, "frequentCategories"
  end

  test "refresh failure keeps cached data instead of clearing UI" do
    store = File.read(Rails.root.join("app/frontend/lib/frequentRepeatStore.js"))

    # offline/500: catch не должен чистить stores — кэшированные данные остаются
    assert_includes store, "catch"
    refute_includes store, "frequentItems.set([])\n  } catch",
      "ошибка сети не должна обнулять секцию «повторить»"
  end

  # Зеркало логики init/refresh (как b113_s2b mirror-тесты)
  test "init and refresh mirror: cache first, network overwrites, error keeps cache" do
    # Холодный старт с кэшем: items видны сразу, до сети
    state = init_mirror(cached: { items: [ "бамбл" ] })
    assert_equal [ "бамбл" ], state[:items]

    # Успешный фоновый fetch перезаписывает кэш и стор
    refresh_mirror(state, network: { ok: true, items: [ "бамбл", "тоник" ] })
    assert_equal [ "бамбл", "тоник" ], state[:items]
    assert_equal [ "бамбл", "тоник" ], state[:cached]

    # Ошибка сети: стор и кэш не трогаем
    refresh_mirror(state, network: { ok: false })
    assert_equal [ "бамбл", "тоник" ], state[:items]
    assert_equal [ "бамбл", "тоник" ], state[:cached]

    # Холодный старт без кэша: пусто, ждём фоновый fetch
    empty = init_mirror(cached: nil)
    assert_equal [], empty[:items]
  end

  private

  def init_mirror(cached:)
    items = cached ? cached[:items] : []
    { items: items, cached: cached ? cached[:items] : nil }
  end

  def refresh_mirror(state, network:)
    return state unless network[:ok]

    state[:items] = network[:items]
    state[:cached] = network[:items]
    state
  end
end
