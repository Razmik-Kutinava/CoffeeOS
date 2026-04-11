class RemoveMockCatalogData < ActiveRecord::Migration[8.1]
  def up
    mock_product_ids = Product.where("slug LIKE ?", "menu-prod-%").pluck(:id)
    if mock_product_ids.any?
      ProductTenantSetting.where(product_id: mock_product_ids).delete_all
      ProductModifierOption.where(group_id: ProductModifierGroup.where(product_id: mock_product_ids).pluck(:id)).delete_all
      ProductModifierGroup.where(product_id: mock_product_ids).delete_all
      Product.where(id: mock_product_ids).delete_all
      say "Удалено мок-товаров: #{mock_product_ids.size}"
    end

    mock_cat_ids = Category.where("slug LIKE ?", "menu-cat-%").pluck(:id)
    if mock_cat_ids.any?
      Category.where(id: mock_cat_ids).delete_all
      say "Удалено мок-категорий: #{mock_cat_ids.size}"
    end
  end

  def down
    # необратимо
  end
end
