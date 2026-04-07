# frozen_string_literal: true

# Рабочий каталог CoffeeOS (категории, товары, модификаторы, PTS).
# Стабильные slug: menu-cat-*, menu-prod-*.
# PTS создаётся для всех существующих тенантов — ничего нового не создаём.

# ── Лёгкая очистка при обычном db:seed ──────────────────────────────────────
puts "[shop] Очистка seed-shop-* ..."
Product.where("slug LIKE ?", "seed-shop-%").find_each(&:destroy!)
Category.where("slug LIKE ?", "seed-shop-%").find_each(&:destroy!)

ActiveRecord::Base.transaction do

  # ── КАТЕГОРИИ ──────────────────────────────────────────────────────────────
  cat_filter = Category.find_or_initialize_by(slug: "menu-cat-filter")
  cat_filter.assign_attributes(name: "Фильтр-кофе", sort_order: 1, is_active: true)
  cat_filter.save!

  cat_cold = Category.find_or_initialize_by(slug: "menu-cat-cold")
  cat_cold.assign_attributes(name: "Холодные", sort_order: 2, is_active: true)
  cat_cold.save!

  # ── ХЕЛПЕР: создать группу модификаторов с опциями ────────────────────────
  upsert_modifier_groups = ->(product, groups_spec) do
    group_ids = product.product_modifier_groups.pluck(:id)
    ProductModifierOption.where(group_id: group_ids).delete_all if group_ids.any?
    product.product_modifier_groups.delete_all
    groups_spec.each_with_index do |gspec, gi|
      grp = product.product_modifier_groups.create!(
        name: gspec[:name],
        is_required: gspec[:required],
        sort_order: gi
      )
      gspec[:options].each_with_index do |ospec, oi|
        ProductModifierOption.create!(
          group_id: grp.id,
          name: ospec[:name],
          price_delta: ospec[:price].to_d,
          is_active: true,
          sort_order: oi
        )
      end
    end
  end

  # ── БАЗОВЫЕ ГРУППЫ ДЛЯ ХОЛОДНЫХ (товары 6-9) ──────────────────────────────
  cold_base_modifiers = [
    {
      name: "Температура", required: true,
      options: [{ name: "Убрать лёд", price: 0 }]
    },
    {
      name: "Сладость", required: true,
      options: [
        { name: "Сахар - умеренно сладко",       price: 0  },
        { name: "Топинамбур - умеренно сладко",  price: 30 },
        { name: "Мёд - умеренно сладко",          price: 30 }
      ]
    },
    {
      name: "Как получить", required: false,
      options: [{ name: "В машине", price: 0 }]
    }
  ].freeze

  # ── ПРОДУКТЫ ───────────────────────────────────────────────────────────────
  products = [

    # ─── Фильтр-кофе ─────────────────────────────────────────────────────────

    {
      slug: "menu-prod-guatemala-decaf",
      name: "Фильтр-кофе Гватемала, без кофеина",
      category: cat_filter,
      price: 295,
      stock: 26,
      description: <<~DESC.strip,
        Альтернативный кофе без кофемашины. Готовим фильтром и батч-брю — вкус мягче, чище, без горечи.

        Фильтр без кофеина — для паузы без стимуляции. Тот же насыщенный аромат и тело, что у классического фильтра, но без эффекта бодрости. Подходит для вечера или спокойного ритма дня.

        Арабика из Гватемалы, декофеинизация водой и воздухом — бережный метод сохраняет вкус. Вкус: черешня, карамель, зелёный чай с лимоном. Лёгкий и сбалансированный профиль.

        Объём: 250 мл

        Состав: заваренный кофе (декофеинизированная арабика 100%)

        Может содержать: молоко (лактоза), глютен, орехи, злаки, соя, цитрусовые, какао, специи

        Пищевая ценность на 250 мл: белки 0,04 г · жиры 0 г · углеводы 0,06 г
      DESC
      modifiers: [
        {
          name: "Температура", required: true,
          options: [
            { name: "Горячий, как американо (вкус станет мягче)", price: 0 },
            { name: "Со льдом",  price: 0 },
            { name: "Стандарт", price: 0 }
          ]
        },
        {
          name: "Вкус", required: true,
          options: [
            { name: "Кардамон и корица", price: 0  },
            { name: "Яблоко и корица",   price: 30 },
            { name: "Пряный",            price: 30 }
          ]
        },
        {
          name: "Сладость", required: true,
          options: [
            { name: "Сахар - умеренно сладко",      price: 0  },
            { name: "Топинамбур - умеренно сладко", price: 30 },
            { name: "Мёд - умеренно сладко",         price: 30 }
          ]
        },
        {
          name: "Текстура", required: false,
          options: [{ name: "Сливки", price: 30 }]
        },
        {
          name: "Как получить", required: false,
          options: [{ name: "В машине", price: 0 }]
        }
      ]
    },

    {
      slug: "menu-prod-brazil",
      name: "Фильтр-кофе Бразилия",
      category: cat_filter,
      price: 179,
      stock: 8,
      description: <<~DESC.strip,
        Альтернативный кофе без кофемашины. Готовим фильтром и батч-брю — вкус мягче, чище, без горечи.

        Классический чёрный кофе, но не американо. Фильтр раскрывает вкус глубже и мягче — можно пить сразу, без ожидания.

        Арабика из региона Серрадо (Бразилия). Низкая кислотность, округлое тело. Вкус: шоколад, орехи, карамель.

        Объём: 250 мл

        Состав: заваренный кофе

        Может содержать: молоко (лактоза), глютен, орехи, злаки, соя, цитрусовые, какао, специи

        Пищевая ценность на 250 мл: белки 0,04 г · жиры 0 г · углеводы 0,06 г
      DESC
      modifiers: [
        {
          name: "Температура", required: true,
          options: [
            { name: "Горячий, как американо (вкус станет мягче)", price: 0 },
            { name: "Со льдом",  price: 0 },
            { name: "Стандарт", price: 0 }
          ]
        },
        {
          name: "Вкус", required: true,
          options: [
            { name: "Кардамон и корица", price: 0 }
          ]
        },
        {
          name: "Сладость", required: true,
          options: [
            { name: "Сахар - умеренно сладко",      price: 0  },
            { name: "Топинамбур - умеренно сладко", price: 30 },
            { name: "Мёд - умеренно сладко",         price: 30 }
          ]
        },
        {
          name: "Текстура", required: false,
          options: [{ name: "Сливки", price: 30 }]
        },
        {
          name: "Как получить", required: false,
          options: [{ name: "В машине", price: 0 }]
        }
      ]
    },

    # ─── Холодные ────────────────────────────────────────────────────────────

    {
      slug: "menu-prod-bumble",
      name: "Бамбл",
      category: cat_cold,
      price: 315,
      stock: 9,
      description: <<~DESC.strip,
        Альтернативный кофе без кофемашины. Готовим cold brew — мягкий вкус, без горечи, с естественной сладостью.

        Кофе с ярким цитрусовым акцентом. Холодное заваривание подчёркивает сочные апельсиновые ноты, а карамель добавляет лёгкую сливочность и баланс.

        Фруктовый · освежающий · бодрящий. Отличный выбор, когда хочется кофе, но не классического вкуса.

        Объём: 290 мл

        Состав: cold brew кофе, апельсиновое пюре, карамельный сироп

        Аллергены: цитрусовые (апельсин), карамель (содержит сахар, возможно молочные компоненты)

        Может содержать: молоко (лактоза), глютен, орехи, злаки, соя, цитрусовые, какао, специи

        Пищевая ценность на 290 мл: белки 0,2 г · жиры 0,1 г · углеводы 28,5 г
      DESC
      modifiers: [
        {
          name: "Температура", required: true,
          options: [{ name: "Убрать лёд", price: 0 }]
        },
        {
          name: "Сладость", required: true,
          options: [
            { name: "Сахар - умеренно сладко",      price: 0  },
            { name: "Топинамбур - умеренно сладко", price: 30 },
            { name: "Мёд - умеренно сладко",         price: 30 }
          ]
        },
        {
          name: "Вкус", required: true,
          options: [{ name: "Ярче кофе", price: 30 }]
        },
        {
          name: "Как получить", required: false,
          options: [{ name: "В машине", price: 0 }]
        }
      ]
    },

    {
      slug: "menu-prod-coffee-tonic",
      name: "Кофе-тоник",
      category: cat_cold,
      price: 295,
      stock: 8,
      description: <<~DESC.strip,
        Альтернативный кофе без кофемашины. Готовим на основе cold brew — без лишней горечи.

        Освежающий и лёгкий кофе-тоник. Лимонные ноты и хининовая горчинка тоника подчёркивают чистый кофейный вкус.

        Идеален для жаркого дня и быстрого перерыва.

        Объём: 290 мл

        Состав: cold brew кофе, тоник лимон

        Аллергены: цитрусовые (лимон)

        Может содержать: молоко (лактоза), глютен, орехи, злаки, соя, цитрусовые, какао, специи

        Пищевая ценность на 290 мл: белки 0,108 г · жиры 0 г · углеводы 15,8 г
      DESC
      modifiers: [
        {
          name: "Температура", required: true,
          options: [{ name: "Убрать лёд", price: 0 }]
        },
        {
          name: "Сладость", required: true,
          options: [
            { name: "Сахар - умеренно сладко",      price: 0  },
            { name: "Топинамбур - умеренно сладко", price: 30 },
            { name: "Мёд - умеренно сладко",         price: 30 }
          ]
        },
        {
          name: "Вкус", required: true,
          options: [{ name: "Ярче кофе", price: 30 }]
        },
        {
          name: "Как получить", required: false,
          options: [{ name: "В машине", price: 0 }]
        }
      ]
    },

    {
      slug: "menu-prod-matcha-tonic",
      name: "Матча тоник",
      category: cat_cold,
      price: 195,
      stock: 10,
      description: <<~DESC.strip,
        Готовим вручную, без автоматики — контролируем вкус на каждом этапе.

        Освежающий матча с лимонной яркостью. Цитрусовая свежесть тоника подчёркивает травянистые ноты зелёного чая и добавляет лёгкую горчинку.

        Лёгкий · цитрусовый · бодрящий. Идеален для жаркой погоды и быстрого перерыва.

        Объём: 290 мл

        Состав: матча, лимонный тоник

        Аллергены: лимон (цитрусовые)

        Может содержать: молоко (лактоза), глютен, орехи, злаки, соя, цитрусовые, какао, специи

        Пищевая ценность на 290 мл: белки 0,6 г · жиры 0,1 г · углеводы 9,5 г
      DESC
      modifiers: [
        {
          name: "Температура", required: true,
          options: [{ name: "Убрать лёд", price: 0 }]
        },
        {
          name: "Сладость", required: true,
          options: [
            { name: "Сахар - умеренно сладко",      price: 0  },
            { name: "Топинамбур - умеренно сладко", price: 30 },
            { name: "Мёд - умеренно сладко",         price: 30 }
          ]
        },
        {
          name: "Вкус", required: true,
          options: [{ name: "Ярче матча", price: 30 }]
        },
        {
          name: "Как получить", required: false,
          options: [{ name: "В машине", price: 0 }]
        }
      ]
    },

    {
      slug: "menu-prod-cold-brew-beer-cordial",
      name: "Cold Brew + пивной кордиал + сливки + лёд",
      category: cat_cold,
      price: 385,
      stock: 110,
      description: "Необычный пряный колд брю с пивным кордиалом и нежными сливками.\n\nОбъём: 290 мл",
      modifiers: cold_base_modifiers
    },

    {
      slug: "menu-prod-cold-brew-cream",
      name: "Cold Brew + сливки + лёд",
      category: cat_cold,
      price: 275,
      stock: 110,
      description: "Классический колд брю с бархатистыми сливками — лёгкая шоколадно-ореховая горчинка.\n\nОбъём: 270 мл",
      modifiers: cold_base_modifiers
    },

    {
      slug: "menu-prod-cold-brew-mango",
      name: "Cold Brew + пряный манго + сливки + лёд",
      category: cat_cold,
      price: 375,
      stock: 110,
      description: "Тропический колд брю с пряным манго и нежными сливками.\n\nОбъём: 270 мл",
      modifiers: cold_base_modifiers
    },

    {
      slug: "menu-prod-cold-brew-cranberry",
      name: "Cold Brew + клюква + имбирь + лёд",
      category: cat_cold,
      price: 335,
      stock: 110,
      description: "Освежающий колд брю с терпкой клюквой и имбирём.\n\nОбъём: 290 мл",
      modifiers: cold_base_modifiers
    }

  ]

  all_tenants = Tenant.all.to_a

  products.each_with_index do |spec, i|
    product = Product.find_or_initialize_by(slug: spec[:slug])
    product.assign_attributes(
      category_id: spec[:category].id,
      name: spec[:name],
      base_price: spec[:price].to_d,
      description: spec[:description],
      image_url: nil,
      is_active: true,
      sort_order: i
    )
    product.save!

    all_tenants.each do |tenant|
      Current.tenant_id = tenant.id
      pts = ProductTenantSetting.find_or_initialize_by(tenant_id: tenant.id, product_id: product.id)
      pts.assign_attributes(
        price: spec[:price].to_d,
        is_enabled: true,
        is_sold_out: false,
        sold_out_reason: nil,
        stock_qty: spec[:stock]
      )
      pts.save!
    end
    Current.tenant_id = nil

    upsert_modifier_groups.call(product, spec[:modifiers])
  end

end

puts "\n[shop] Каталог CoffeeOS загружен: tenant(s)=#{Tenant.count} | Категории: Фильтр-кофе, Холодные | Товаров: 9\n"
