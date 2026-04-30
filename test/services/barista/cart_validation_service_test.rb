# frozen_string_literal: true

require "test_helper"

class Barista::CartValidationServiceTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant   = create_tenant!
    category  = create_category!
    @product  = create_product!(category: category)
    @setting  = enable_product_for_tenant!(tenant: @tenant, product: @product, price: 100)
  end

  def validate(items)
    Barista::CartValidationService.new(items, tenant_id: @tenant.id).call!
  end

  # ---------------------------------------------------------------------------
  # Empty / nil cart
  # ---------------------------------------------------------------------------

  test "empty array raises CartValidationError with корзина пуста message" do
    error = assert_raises(Barista::CartValidationService::CartValidationError) { validate([]) }
    assert_match "Корзина пуста", error.message
  end

  test "nil cart raises CartValidationError" do
    assert_raises(Barista::CartValidationService::CartValidationError) { validate(nil) }
  end

  # ---------------------------------------------------------------------------
  # Happy path
  # ---------------------------------------------------------------------------

  test "valid item returns array with product, quantity, price and total_price keys" do
    result = validate([{ product_id: @product.id, quantity: 2 }])
    assert_equal 1, result.size
    line = result.first
    assert_equal @product.id, line[:product].id
    assert_equal 2,           line[:quantity]
    assert_equal 100,         line[:price]
    assert_equal 200,         line[:total_price]
  end

  test "quantity defaults to 1 when not specified in item hash" do
    result = validate([{ product_id: @product.id }])
    assert_equal 1, result.first[:quantity]
  end

  test "total_price equals price multiplied by quantity" do
    result = validate([{ product_id: @product.id, quantity: 5 }])
    assert_equal 500, result.first[:total_price]
  end

  test "string product_id works as UUID comes as string from forms" do
    result = validate([{ product_id: @product.id.to_s, quantity: 1 }])
    assert_equal @product.id, result.first[:product].id
  end

  test "multiple items returns all validated lines" do
    category2 = create_category!
    product2  = create_product!(category: category2)
    enable_product_for_tenant!(tenant: @tenant, product: product2, price: 200)

    result = validate([
      { product_id: @product.id,  quantity: 1 },
      { product_id: product2.id, quantity: 3 }
    ])

    assert_equal 2,   result.size
    assert_equal 100, result[0][:total_price]
    assert_equal 600, result[1][:total_price]
  end

  # ---------------------------------------------------------------------------
  # RecordNotFound cases
  # ---------------------------------------------------------------------------

  test "unknown product_id raises ActiveRecord::RecordNotFound" do
    fake_id = SecureRandom.uuid
    assert_raises(ActiveRecord::RecordNotFound) do
      validate([{ product_id: fake_id, quantity: 1 }])
    end
  end

  test "product from different tenant raises CartValidationError because no setting exists" do
    other_tenant = create_tenant!
    category2    = create_category!
    other_product = create_product!(category: category2)
    # product exists globally but has no ProductTenantSetting for @tenant
    # The service will find the product in products_map but no matching setting
    assert_raises(Barista::CartValidationService::CartValidationError) do
      validate([{ product_id: other_product.id, quantity: 1 }])
    end
  end

  # ---------------------------------------------------------------------------
  # Disabled / sold-out products
  # ---------------------------------------------------------------------------

  test "disabled product (is_enabled false, no price) raises CartValidationError" do
    category2  = create_category!
    product2   = create_product!(category: category2)
    # Create setting with is_enabled: false explicitly, no price
    ProductTenantSetting.create!(
      tenant: @tenant,
      product: product2,
      is_enabled: false,
      is_sold_out: false,
      price: nil
    )

    assert_raises(Barista::CartValidationService::CartValidationError) do
      validate([{ product_id: product2.id, quantity: 1 }])
    end
  end

  test "sold_out product raises CartValidationError" do
    category2 = create_category!
    product2  = create_product!(category: category2)
    enable_product_for_tenant!(tenant: @tenant, product: product2, price: 50, is_enabled: true)
    ProductTenantSetting.find_by!(tenant: @tenant, product: product2)
                        .update_columns(is_sold_out: true, sold_out_reason: "manual")

    error = assert_raises(Barista::CartValidationService::CartValidationError) do
      validate([{ product_id: product2.id, quantity: 1 }])
    end
    assert_match "недоступен", error.message
  end

  test "product with is_enabled false raises CartValidationError even with price" do
    category2 = create_category!
    product2  = create_product!(category: category2)
    # Use the factory helper which accepts is_enabled kwarg
    enable_product_for_tenant!(
      tenant: @tenant,
      product: product2,
      price: 80,
      is_enabled: false
    )

    assert_raises(Barista::CartValidationService::CartValidationError) do
      validate([{ product_id: product2.id, quantity: 1 }])
    end
  end
end
