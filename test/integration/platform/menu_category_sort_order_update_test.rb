# frozen_string_literal: true

require "test_helper"

# Sentry RUBY-1K: PATCH category с пустым sort_order → NotNullViolation.
class Platform::MenuCategorySortOrderUpdateTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "cat-so-org-#{SecureRandom.hex(3)}")
    @tenant = create_tenant!(organization: @org, name: "Cat SO", slug: "cat-so-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: @tenant,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-cat-so-#{SecureRandom.hex(3)}@test.local"
    )
    @category = create_category!(name: "Filter #{SecureRandom.hex(3)}")
    @category.update!(sort_order: 3)
    login_as!(@uk)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "update_category with blank sort_order keeps existing and does not 500" do
    patch platform_menu_category_path(@category), params: {
      category: {
        name: @category.name,
        slug: @category.slug,
        description: "",
        is_active: true,
        sort_order: ""
      }
    }

    assert_response :redirect
    assert_redirected_to platform_menu_path
    follow_redirect!
    assert_match(/Категория обновлена/, flash[:notice].to_s)

    @category.reload
    assert_equal 3, @category.sort_order
    assert_not_nil @category.sort_order
  end

  test "update_category with sort_order 0 appends to end" do
    other = create_category!(name: "Other #{SecureRandom.hex(3)}")
    other.update!(sort_order: 10)

    patch platform_menu_category_path(@category), params: {
      category: {
        name: @category.name,
        slug: @category.slug,
        is_active: true,
        sort_order: "0"
      }
    }

    assert_response :redirect
    @category.reload
    assert_equal other.sort_order + 1, @category.sort_order
  end
end
