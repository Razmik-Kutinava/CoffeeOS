# frozen_string_literal: true

require "test_helper"

class Platform::ProdSinglePointResetTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @real = create_tenant!(slug: "real-#{SecureRandom.hex(3)}")
    @kitchen = create_prep_kitchen_tenant!(slug: "kitchen-#{SecureRandom.hex(3)}")
    ActiveRecord::Base.connection.exec_insert(
      "INSERT INTO prep_kitchen_sales_point_links (prep_kitchen_tenant_id, sales_point_tenant_id, created_at, updated_at) " \
      "VALUES ('#{@kitchen.id}', '#{@real.id}', NOW(), NOW())"
    )
    @test_point = create_tenant!(slug: "test-cafe-#{SecureRandom.hex(3)}", status: "inactive")

    @owner = create_user!(tenant: @test_point, role_codes: %w[franchise_manager], email: "owner-#{SecureRandom.hex(3)}@gmail.test")
    @test_uk = create_user!(tenant: @test_point, role_codes: %w[ук_global_admin])
    @demo_barista = create_user!(tenant: @real, role_codes: %w[barista], email: "barista-#{SecureRandom.hex(3)}@demo.coffeeos.local")
    @kitchen_worker = create_user!(tenant: @kitchen, role_codes: %w[prep_kitchen_worker])
    @shift = open_cash_shift!(tenant: @real, opened_by: @demo_barista)

    @paid = Order.create!(
      tenant: @real, order_number: "RST-#{SecureRandom.hex(4)}", source: :mobile, status: :issued,
      total_amount: 10, discount_amount: 0, final_amount: 10, cash_shift_id: @shift.id
    )
    Payment.create!(order_id: @paid.id, tenant_id: @real.id, amount: 10, method: :card,
                    provider: "tbank", provider_payment_id: "pid-#{SecureRandom.hex(3)}", status: :succeeded)

    @aram = create_mobile_customer!(phone: "+79990000001").tap { |c| c.update!(first_name: "Aram") }
    @aram_in_pattern = create_mobile_customer!(phone: "+79990000002", email: "aram@coffeeos.dev")
    @mcp_guest = create_mobile_customer!.tap { |c| c.update!(first_name: "B112") }
    @key = ShopApiKey.create!(tenant: @real, name: "mcp-last", active: true,
                              token_digest: SecureRandom.hex(32), token_prefix: "abc")
  end

  test "dry_run changes nothing" do
    result = run_reset(dry_run: true)

    assert result.verification[:pass], result.verification.inspect
    assert_includes result.steps[:staff_deleted], @demo_barista.email
    assert User.exists?(@demo_barista.id)
    assert_equal @test_point.id, @owner.reload.tenant_id
    assert CashShift.exists?(@shift.id)
  end

  test "apply leaves owner as the only UK on the real point" do
    result = run_reset(dry_run: false)
    assert result.verification[:pass], result.verification.inspect

    @owner.reload
    assert_equal @real.id, @owner.tenant_id
    assert @owner.user_roles.joins(:role).where(roles: { code: "ук_global_admin" }).exists?
    assert_equal [ @owner.id ], User.where(tenant_id: @real.id).pluck(:id)
    assert_not User.exists?(@demo_barista.id)
    assert_not User.exists?(@test_uk.id)
    assert_not Tenant.exists?(@test_point.id)

    assert Tenant.exists?(@kitchen.id), "цех боевой точки не трогаем"
    assert User.exists?(@kitchen_worker.id)

    assert_not CashShift.exists?(@shift.id)
    assert_nil @paid.reload.cash_shift_id
    assert Payment.where(order_id: @paid.id).exists?, "банковские платежи сохраняются"

    assert MobileCustomer.exists?(@aram.id)
    assert MobileCustomer.exists?(@aram_in_pattern.id), "защищённый телефон не удаляется"
    assert_not MobileCustomer.exists?(@mcp_guest.id)
    assert_not @key.reload.active
  end

  private

  def run_reset(dry_run:)
    Platform::ProdSinglePointReset.call(
      owner_email: @owner.email, dry_run: dry_run, real_tenant_id: @real.id, protect_phones: [ "+79990000002" ]
    )
  end
end
