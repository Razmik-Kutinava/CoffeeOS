class SeedBlackCoffeeCatalog < ActiveRecord::Migration[8.1]
  def up
    return say("Каталог уже есть — пропускаем") if Category.exists? && Product.exists?

    cat = Category.create!(
      name: "Черный",
      slug: "chernyj",
      sort_order: 0,
      is_active: true
    )
    say "Категория: #{cat.name}"

    # ── Фильтр-кофе Бразилия ──
    brazil = Product.create!(
      name: "Фильтр-кофе Бразилия",
      slug: "filtr-kofe-braziliya",
      category: cat,
      base_price: 179,
      description: "Фильтр-кофе — это не американо. Готовим через фильтр и батч-брю: без кофемашины, без давления, без горечи. Вкус раскрывается мягко и чисто — шоколад, орехи, карамель. Арабика из региона Серрадо, низкая кислотность, округлое тело. Можно пить сразу.",
      is_active: true,
      sort_order: 0
    )
    create_modifiers!(brazil, [
      { name: "Температура", required: true, options: [
        { name: "Со льдом", price: 0 }
      ]},
      { name: "Вкус", required: true, options: [
        { name: "Кардамон и корица — пряный акцент, без сладости", price: 0 },
        { name: "Яблочный с корицей — мягкий, с лёгкой фруктовостью", price: 0 },
        { name: "Пивной кордиал — сладкий, глубокий, насыщенный", price: 0 }
      ]},
      { name: "Интенсивность", required: true, options: [
        { name: "Сахар — мягкая сладость", price: 0 },
        { name: "Топинамбур — нейтральная сладость без послевкусия", price: 0 },
        { name: "Мёд — натуральная сладость с цветочным оттенком", price: 0 }
      ]}
    ])
    say "Товар: #{brazil.name} — #{brazil.base_price}₽"

    # ── Фильтр-кофе декаф Гватемала ──
    decaf = Product.create!(
      name: "Фильтр-кофе без кофеина (декаф) Гватемала",
      slug: "filtr-kofe-dekaf-gvatemala",
      category: cat,
      base_price: 295,
      description: "Тот же формат фильтра — без кофемашины, без горечи. Декофеинизация водой и воздухом сохраняет вкус зерна без химии. Арабика из Гватемалы: черешня, карамель, лёгкий зелёный чай с цитрусом. Для вечера, для паузы, для спокойного ритма.",
      is_active: true,
      sort_order: 1
    )
    create_modifiers!(decaf, [
      { name: "Температура", required: true, options: [
        { name: "Со льдом", price: 0 }
      ]},
      { name: "Вкус", required: true, options: [
        { name: "Кардамон и корица — пряный акцент, без сладости", price: 0 },
        { name: "Яблочный с корицей — мягкий, с лёгкой фруктовостью", price: 0 }
      ]},
      { name: "Интенсивность", required: true, options: [
        { name: "Сахар — мягкая сладость", price: 0 },
        { name: "Топинамбур — нейтральная сладость без послевкусия", price: 0 },
        { name: "Мёд — натуральная сладость с цветочным оттенком", price: 0 }
      ]}
    ])
    say "Товар: #{decaf.name} — #{decaf.base_price}₽"

    # ── PTS для всех тенантов ──
    tenants = Tenant.all.to_a
    [brazil, decaf].each do |product|
      tenants.each do |tenant|
        ActiveRecord::Base.transaction do
          conn = ActiveRecord::Base.connection
          conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant.id.to_s)}")
          ProductTenantSetting.create!(
            tenant_id: tenant.id,
            product_id: product.id,
            price: product.base_price,
            is_enabled: true,
            is_sold_out: false
          )
        end
      end
      say "PTS создан для #{product.name} × #{tenants.size} тенантов"
    end
  end

  def down
    %w[filtr-kofe-braziliya filtr-kofe-dekaf-gvatemala].each do |slug|
      Product.find_by(slug: slug)&.destroy
    end
    Category.find_by(slug: "chernyj")&.destroy
  end

  private

  def create_modifiers!(product, groups)
    groups.each_with_index do |gspec, gi|
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
end
