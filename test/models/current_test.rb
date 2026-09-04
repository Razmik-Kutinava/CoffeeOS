# frozen_string_literal: true

require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  setup { Current.reset }

  test "assign! sets attributes without a block" do
    tid = SecureRandom.uuid
    uid = SecureRandom.uuid

    Current.assign!(tenant_id: tid, user_id: uid, role_code: "uk_global_admin")

    assert_equal tid, Current.tenant_id
    assert_equal uid, Current.user_id
    assert_equal "uk_global_admin", Current.role_code
  end

  test "set still requires a block" do
    assert_raises(LocalJumpError) { Current.set(tenant_id: SecureRandom.uuid) }
  end
end
