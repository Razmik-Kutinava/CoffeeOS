# frozen_string_literal: true

require "test_helper"

class ManagerStaffDuplicateEmailTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @tenant = create_tenant!
    @gm = create_user!(
      tenant: @tenant,
      role_codes: %w[general_manager],
      email: "gm-dup-staff-#{SecureRandom.hex(3)}@test.local"
    )
    @existing = create_user!(
      tenant: @tenant,
      role_codes: %w[barista],
      email: "existing-barista-#{SecureRandom.hex(3)}@test.local"
    )
    login_as!(@gm)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "duplicate email on staff create returns 422 not 500" do
    assert_no_difference -> { User.count } do
      post manager_staff_members_path, params: {
        user: {
          name: "Duplicate Barista",
          email: @existing.email,
          password: "pass123",
          password_confirmation: "pass123"
        },
        role_codes: [ "barista" ]
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "уже занят"
  end
end
