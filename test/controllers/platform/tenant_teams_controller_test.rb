# frozen_string_literal: true

require "test_helper"

# Команда точки создаётся из карточки точки в УК (реальные аккаунты, пароль показывается один раз).
class Platform::TenantTeamsControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @org = create_organization!
    @point = create_tenant!(organization: @org, slug: "team-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: @point,
      role_codes: %w[ук_global_admin],
      email: "uk-team-#{SecureRandom.hex(4)}@test.local"
    )
    login_as!(@uk)
  end

  def member(role, email, name: "Сотрудник")
    { role: role, name: name, email: email, phone: "" }
  end

  test "new form is prefilled with point team roles" do
    get new_platform_tenant_team_path(@point)

    assert_response :success
    assert_includes response.body, "barista"
    assert_includes response.body, "general_manager"
    assert_includes response.body, "shift_manager"
  end

  test "creates real accounts with point roles and shows passwords once" do
    hex = SecureRandom.hex(3)
    members = {
      "0" => member("general_manager", "gm-#{hex}@test.local"),
      "1" => member("barista", "barista-#{hex}@test.local"),
      "2" => member("shift_manager", "shift-#{hex}@test.local")
    }

    assert_difference -> { User.where(tenant_id: @point.id).count }, +3 do
      post platform_tenant_team_path(@point), params: { members: members }
    end
    assert_redirected_to platform_tenant_path(@point)

    barista = User.find_by!(email: "barista-#{hex}@test.local")
    assert barista.active?
    assert barista.has_role_in_context?("barista", tenant_id: @point.id)

    follow_redirect!
    assert_includes response.body, "barista-#{hex}@test.local"
    assert_includes response.body, "Пароль"

    get platform_tenant_path(@point)
    assert_not_includes response.body, "Пароли сотрудников"
  end

  test "blank rows are skipped" do
    hex = SecureRandom.hex(3)
    members = {
      "0" => member("barista", "only-#{hex}@test.local"),
      "1" => member("shift_manager", "")
    }

    assert_difference -> { User.count }, +1 do
      post platform_tenant_team_path(@point), params: { members: members }
    end
  end

  test "duplicate email creates nobody" do
    existing = create_user!(tenant: @point, role_codes: [], email: "taken-#{SecureRandom.hex(3)}@test.local")
    members = {
      "0" => member("general_manager", "fresh-#{SecureRandom.hex(3)}@test.local"),
      "1" => member("barista", existing.email)
    }

    assert_no_difference -> { User.count } do
      post platform_tenant_team_path(@point), params: { members: members }
    end
    assert_response :unprocessable_entity
  end

  test "kitchen team gets prep kitchen roles; sales roles rejected" do
    kitchen = create_prep_kitchen_tenant!(organization: @org)
    hex = SecureRandom.hex(3)

    post platform_tenant_team_path(kitchen), params: {
      members: {
        "0" => member("prep_kitchen_manager", "pkm-#{hex}@test.local"),
        "1" => member("barista", "bad-#{hex}@test.local")
      }
    }

    assert_response :unprocessable_entity
    assert_not User.exists?(email: "pkm-#{hex}@test.local")

    post platform_tenant_team_path(kitchen), params: {
      members: { "0" => member("prep_kitchen_manager", "pkm-#{hex}@test.local") }
    }
    pkm = User.find_by!(email: "pkm-#{hex}@test.local")
    assert pkm.has_role_in_context?("prep_kitchen_manager", tenant_id: kitchen.id)
  end
end
