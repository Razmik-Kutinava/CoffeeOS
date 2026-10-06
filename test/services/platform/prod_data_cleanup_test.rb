# frozen_string_literal: true

require "test_helper"

class Platform::ProdDataCleanupTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @real = create_tenant!(slug: "real-#{SecureRandom.hex(3)}")
    @junk = create_tenant!(slug: "junk-#{SecureRandom.hex(3)}", status: "inactive")
    @money = create_tenant!(slug: "money-#{SecureRandom.hex(3)}", status: "inactive")

    @paid_ready = order!(@real, status: :ready, created_at: 40.days.ago, pay: [ :succeeded, "pid-1" ])
    @failed_ready = order!(@real, status: :ready, created_at: 40.days.ago, pay: [ :failed, "pid-2" ])
    @bank_cancelled = order!(@real, status: :cancelled, created_at: 40.days.ago, pay: [ :failed, "pid-3" ])
    @mock_cancelled = order!(@real, status: :cancelled, created_at: 40.days.ago, pay: [ :succeeded, nil ])
    @mock_this_month = order!(@real, status: :cancelled, created_at: Time.current, pay: [ :pending, nil ])
    @junk_order = order!(@junk, status: :cancelled, created_at: 40.days.ago, pay: [ :failed, "pid-4" ])
    @money_order = order!(@money, status: :issued, created_at: 40.days.ago, pay: [ :succeeded, "pid-5" ])

    @junk_user = create_user!(tenant: @junk, role_codes: %w[barista])
    @test_barista = create_user!(tenant: @real, role_codes: %w[barista], email: "iso-#{SecureRandom.hex(3)}@prog10.local")
    @real_barista = create_user!(tenant: @real, role_codes: %w[barista])

    @old_key = api_key!("mcp-old", last_used_at: 10.days.ago)
    @new_key = api_key!("mcp-new", last_used_at: 1.day.ago)
    @prod_key = api_key!("vitrina-prod", last_used_at: 1.day.ago)

    @mcp_guest = create_mobile_customer!.tap { |c| c.update!(first_name: "MCP") }
    @mcp_guest_with_bank = create_mobile_customer!.tap { |c| c.update!(first_name: "MCP") }
    @paid_ready.update!(customer_id: @mcp_guest_with_bank.id)

    category = create_category!
    @w12 = create_product!(category: category, name: "W12-PLAIN-001")
    @real_product = create_product!(category: category, name: "Латте")
  end

  test "dry_run reports steps and changes nothing" do
    result = run_cleanup(dry_run: true)

    assert result.verification[:pass], result.verification.inspect
    assert_includes result.steps[:tenants_deleted], @junk.slug
    assert_includes result.steps[:board_orders][:issued], @paid_ready.order_number
    assert_equal "ready", @paid_ready.reload.status
    assert Tenant.exists?(@junk.id)
    assert Order.exists?(@mock_cancelled.id)
    assert @old_key.reload.active
    assert @w12.reload.is_active
  end

  test "apply keeps bank history and removes demo/mock data" do
    result = run_cleanup(dry_run: false)
    assert result.verification[:pass], result.verification.inspect

    assert_equal "issued", @paid_ready.reload.status
    assert_equal "cancelled", @failed_ready.reload.status
    assert Order.exists?(@bank_cancelled.id)
    assert_not Order.exists?(@mock_cancelled.id), "имитация оплаты без банка удаляется"
    assert Order.exists?(@mock_this_month.id), "текущий месяц не трогаем (номера заказов)"

    assert_not Tenant.exists?(@junk.id)
    assert_not Order.exists?(@junk_order.id)
    assert_not User.exists?(@junk_user.id)
    assert Tenant.exists?(@money.id), "точка с успешной банковской оплатой остаётся"
    assert Order.exists?(@money_order.id)

    assert_equal "blocked", @test_barista.reload.status
    assert_equal "active", @real_barista.reload.status

    assert_not @old_key.reload.active
    assert @new_key.reload.active, "последний mcp-ключ остаётся до тестовой точки"
    assert @prod_key.reload.active

    assert_not MobileCustomer.exists?(@mcp_guest.id)
    assert MobileCustomer.exists?(@mcp_guest_with_bank.id)

    assert_not @w12.reload.is_active
    assert @real_product.reload.is_active
  end

  private

  def run_cleanup(dry_run:)
    Platform::ProdDataCleanup.call(dry_run: dry_run, real_tenant_id: @real.id)
  end

  def order!(tenant, status:, created_at:, pay:)
    order = Order.create!(
      tenant: tenant, order_number: "CLN-#{SecureRandom.hex(4)}", source: :mobile, status: status,
      total_amount: 10, discount_amount: 0, final_amount: 10, created_at: created_at
    )
    pay_status, pid = pay
    Payment.create!(
      order_id: order.id, tenant_id: tenant.id, amount: 10, method: :card,
      provider: pid ? "tbank" : "shop", provider_payment_id: pid, status: pay_status, created_at: created_at
    )
    order
  end

  def api_key!(name, last_used_at:)
    ShopApiKey.create!(
      tenant: @real, name: name, active: true, last_used_at: last_used_at,
      token_digest: SecureRandom.hex(32), token_prefix: SecureRandom.hex(3)
    )
  end
end
