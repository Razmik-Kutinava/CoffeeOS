# frozen_string_literal: true

require "test_helper"

# УК / владелец франшизы могут быть привязаны к точке (tenant_id) — «Персонал» точки их не редактирует.
class ManagerStaffAbovePointAccountsTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @tenant = create_tenant!
    @gm = create_user!(tenant: @tenant, role_codes: %w[general_manager], email: "gm-above-#{SecureRandom.hex(3)}@test.local")
    @uk = create_user!(tenant: @tenant, role_codes: %w[ук_global_admin], email: "uk-above-#{SecureRandom.hex(3)}@test.local")
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "b-above-#{SecureRandom.hex(3)}@test.local")
    login_as!(@gm)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "general manager does not see UK admin in point staff list" do
    get manager_staff_members_path
    assert_response :success
    assert_includes response.body, @barista.email
    assert_not_includes response.body, @uk.email
  end

  test "general manager cannot change UK admin credentials" do
    get edit_manager_staff_member_path(@uk)
    assert_response :redirect

    patch manager_staff_member_path(@uk), params: { user: { name: @uk.name, email: "pwn-#{@uk.email}", password: "hacked123" } }
    @uk.reload
    assert_not @uk.email.start_with?("pwn-")
    assert_not @uk.authenticate("hacked123")
  end

  test "general manager still edits point barista" do
    get edit_manager_staff_member_path(@barista)
    assert_response :success
  end
end
