# frozen_string_literal: true

module Platform
  class MenuController < BaseController
    before_action :load_categories, only: :index

    def index
      @new_category = Category.new
      @new_product = Product.new
      @new_group = ProductModifierGroup.new
      @new_option = ProductModifierOption.new
      pref = params[:prefill_category_id].presence
      @prefill_category_id = pref if pref.present? && Category.exists?(id: pref)
    end

    def create_category
      category = Category.new(category_params)
      category.slug = unique_slug(Category, category_params[:slug], category.name)
      category.created_by = current_user
      so = category_params[:sort_order].to_i
      # По умолчанию в форме 0 — ставим в конец списка, чтобы новая категория не терялась среди нулей.
      category.sort_order = (so == 0 ? (Category.maximum(:sort_order).to_i + 1) : so)
      if category.save
        redirect_to "#{platform_menu_path(prefill_category_id: category.id)}#new-product",
                    notice: "Категория добавлена. В форме «Новый товар» уже выбрана эта категория — добавьте товар."
      else
        redirect_to platform_menu_path, alert: category.errors.full_messages.join(", ")
      end
    end

    def update_category
      category = Category.find(params[:id])
      attrs = category_params
      if attrs[:slug].present?
        attrs[:slug] = unique_slug(Category, attrs[:slug], category.name, skip_id: category.id)
      end

      if category.update(attrs)
        redirect_to platform_menu_path, notice: "Категория обновлена"
      else
        redirect_to platform_menu_path, alert: category.errors.full_messages.join(", ")
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to platform_menu_path, alert: "Категория не найдена"
    end

    def create_product
      image_file = params.dig(:product, :image)
      attrs = normalized_product_attrs
      product = Product.new(attrs)
      product.slug = unique_slug(Product, product_params[:slug], product.name)
      product.created_by = current_user
      ActiveRecord::Base.transaction do
        product.save!
        ensure_tenant_settings!(product)
      end
      img_msg = apply_product_image_upload!(product, image_file)
      notice = "Товар добавлен и разослан по точкам. Ниже можно добавить ещё товар в эту категорию."
      notice = "#{notice} #{img_msg}" if img_msg.present?
      redirect_to "#{platform_menu_path(prefill_category_id: product.category_id)}#new-product",
                  notice: notice
    rescue ActiveRecord::RecordInvalid => e
      msg = e.record&.errors&.full_messages&.presence&.join(", ") || e.message
      redirect_to platform_menu_path, alert: msg
    end

    def update_product
      image_file = params.dig(:product, :image)
      product = Product.find(params[:id])
      attrs = normalized_product_attrs(product: product)
      if attrs[:slug].present?
        attrs[:slug] = unique_slug(Product, attrs[:slug], product.name, skip_id: product.id)
      end
      ActiveRecord::Base.transaction do
        product.update!(attrs)
        ensure_tenant_settings!(product)
      end
      img_msg = apply_product_image_upload!(product, image_file)
      notice = "Товар обновлён"
      notice = "#{notice} #{img_msg}" if img_msg.present?
      redirect_to platform_menu_path, notice: notice
    rescue ActiveRecord::RecordNotFound
      redirect_to platform_menu_path, alert: "Товар не найден"
    rescue ActiveRecord::RecordInvalid => e
      msg = e.record&.errors&.full_messages&.presence&.join(", ") || e.message
      redirect_to platform_menu_path, alert: msg
    end

    def create_modifier_group
      group = ProductModifierGroup.new(modifier_group_params)
      if group.save
        redirect_to platform_menu_path, notice: "Группа модификаторов добавлена"
      else
        redirect_to platform_menu_path, alert: group.errors.full_messages.join(", ")
      end
    end

    def update_modifier_group
      group = ProductModifierGroup.find(params[:id])
      if group.update(modifier_group_params)
        redirect_to platform_menu_path, notice: "Группа модификаторов обновлена"
      else
        redirect_to platform_menu_path, alert: group.errors.full_messages.join(", ")
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to platform_menu_path, alert: "Группа модификаторов не найдена"
    end

    def create_modifier_option
      option = ProductModifierOption.new(modifier_option_params)
      if option.save
        redirect_to platform_menu_path, notice: "Опция модификатора добавлена"
      else
        redirect_to platform_menu_path, alert: option.errors.full_messages.join(", ")
      end
    end

    def update_modifier_option
      option = ProductModifierOption.find(params[:id])
      if option.update(modifier_option_params)
        redirect_to platform_menu_path, notice: "Опция модификатора обновлена"
      else
        redirect_to platform_menu_path, alert: option.errors.full_messages.join(", ")
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to platform_menu_path, alert: "Опция модификатора не найдена"
    end

    def destroy_product
      product = Product.find(params[:id])
      ActiveRecord::Base.transaction { product.destroy! }
      redirect_to platform_menu_path, notice: "Товар удалён из базы"
    rescue ActiveRecord::RecordNotFound
      redirect_to platform_menu_path, alert: "Товар не найден"
    rescue StandardError => e
      log_destroy_failure("product", e)
      redirect_to platform_menu_path, alert: destroy_blocked_message
    end

    def destroy_category
      category = Category.find(params[:id])
      ActiveRecord::Base.transaction do
        category.products.order(:id).find_each do |product|
          product.destroy!
        end
        category.reload.destroy!
      end
      redirect_to platform_menu_path, notice: "Категория и все её товары удалены из базы"
    rescue ActiveRecord::RecordNotFound
      redirect_to platform_menu_path, alert: "Категория не найдена"
    rescue StandardError => e
      log_destroy_failure("category", e)
      redirect_to platform_menu_path, alert: destroy_blocked_message
    end

    private

    def load_categories
      @categories = Category
        .includes(products: { product_modifier_groups: :product_modifier_options })
        .ordered
        .limit(500)
    end

    def category_params
      params.require(:category).permit(:name, :slug, :description, :sort_order, :is_active)
    end

    def product_params
      params.require(:product).permit(:category_id, :name, :slug, :description, :base_price, :image_url, :sort_order, :is_active)
    end

    # sort_order в форме может прийти пустой строкой, а в БД колонка NOT NULL.
    # Правило: пусто/0 => в конец категории; иначе используем переданное значение.
    def normalized_product_attrs(product: nil)
      attrs = product_params.to_h.symbolize_keys
      raw = attrs[:sort_order].to_s.strip
      requested = raw.present? ? raw.to_i : 0

      attrs[:sort_order] =
        if requested.positive?
          requested
        else
          base_scope = Product.where(category_id: attrs[:category_id])
          base_scope = base_scope.where.not(id: product.id) if product
          base_scope.maximum(:sort_order).to_i + 1
        end

      attrs
    end

    def modifier_group_params
      params.require(:product_modifier_group).permit(:product_id, :name, :is_required, :sort_order)
    end

    def modifier_option_params
      params.require(:product_modifier_option).permit(:group_id, :name, :price_delta, :is_active, :sort_order)
    end

    def unique_slug(model, requested_slug, fallback_name, skip_id: nil)
      base = requested_slug.presence || fallback_name.to_s.parameterize
      base = "item" if base.blank?
      slug = base
      idx = 2
      scope = model.where(slug: slug)
      scope = scope.where.not(id: skip_id) if skip_id
      while scope.exists?
        slug = "#{base}-#{idx}"
        idx += 1
        scope = model.where(slug: slug)
        scope = scope.where.not(id: skip_id) if skip_id
      end
      slug
    end

    # Для каждой точки — PTS с валидной ценой. Явный SET LOCAL в транзакции: RLS на pts требует контекст PostgreSQL.
    def ensure_tenant_settings!(product)
      uid = current_user.id
      fallback = product.base_price.presence&.to_d
      fallback = BigDecimal("1") if fallback.blank? || fallback <= 0

      Tenant.select(:id).find_each do |tenant|
        ActiveRecord::Base.transaction do
          conn = ActiveRecord::Base.connection
          conn.execute("SET LOCAL app.current_user_id = #{conn.quote(uid.to_s)}")
          conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant.id.to_s)}")

          Current.tenant_id = tenant.id

          pts = ProductTenantSetting.find_or_initialize_by(tenant_id: tenant.id, product_id: product.id)
          pts.price = product.base_price.presence&.to_d || pts.price || fallback
          pts.price = fallback if pts.price.blank? || pts.price <= 0
          pts.is_enabled = true
          pts.is_sold_out = false
          pts.sold_out_reason = nil
          pts.save!
        end
      end
    ensure
      Current.tenant_id = nil
    end

    def destroy_blocked_message
      "Не удалось удалить: товар уже есть в заказах (ограничение БД). " \
        "Снимите с продажи (is_active) или оставьте запись для истории заказов."
    end

    def log_destroy_failure(kind, err)
      Rails.logger.warn("[platform/menu] destroy #{kind}: #{err.class} — #{err.message}")
    end

    # Загрузка файла перезаписывает image_url (в т.ч. вместо ссылки из поля).
    def apply_product_image_upload!(product, image_file)
      return if image_file.blank?

      path = Platform::ProductImageStorage.save!(image_file, product: product)
      product.update_column(:image_url, path)
      nil
    rescue ArgumentError => e
      Rails.logger.warn("[platform/menu] product image: #{e.message}")
      "(Фото не сохранено: #{e.message})"
    end
  end
end
