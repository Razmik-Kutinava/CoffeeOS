# frozen_string_literal: true

require "test_helper"

# TASK_115: явное членство точек в сети CODE:BLACK.
class TenantCodeBlackNetworkTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org_a = create_organization!(name: "Франчайзи A")
    @org_b = create_organization!(name: "Франчайзи B")
  end

  test "S1 membership comes from the explicit flag, not organization, slug or name" do
    lookalike = create_tenant!(
      organization: @org_a,
      name: "CODE:BLACK Арбат",
      slug: "code-black-#{SecureRandom.hex(3)}"
    )
    member = create_tenant!(organization: nil, name: "Точка", code_black_member: true)

    ids = network_ids_among(lookalike, member)
    assert_equal [ member.id ], ids
  end

  test "S2 network includes flagged points of different organizations" do
    a = create_tenant!(organization: @org_a, code_black_member: true)
    b = create_tenant!(organization: @org_b, code_black_member: true)
    no_org = create_tenant!(organization: nil, code_black_member: true)

    assert_equal [ a.id, b.id, no_org.id ].sort, network_ids_among(a, b, no_org).sort
  end

  test "S3 CoffeeOS point without the flag is not in the network" do
    outsider = create_tenant!(organization: @org_a)

    assert_not outsider.code_black_member
    assert_empty network_ids_among(outsider)
  end

  test "S4 unknown value is not membership" do
    tenant = Tenant.new(
      organization: @org_a, name: "N", slug: "nil-flag-#{SecureRandom.hex(3)}",
      type: "sales_point", status: "active", country: "RU", currency: "RUB",
      code_black_member: nil
    )
    assert_not tenant.valid?
    assert tenant.errors[:code_black_member].any?

    saved = create_tenant!(organization: @org_a)
    assert_raises(ActiveRecord::NotNullViolation) do
      saved.update_column(:code_black_member, nil)
    end
  end

  test "S5 selection does not expand beyond explicit membership" do
    member = create_tenant!(organization: @org_a, code_black_member: true)
    same_org_outsider = create_tenant!(organization: @org_a)
    other_org_outsider = create_tenant!(organization: @org_b)

    assert_equal [ member.id ], network_ids_among(member, same_org_outsider, other_org_outsider)
  end

  test "S8 new point is not in the network by default" do
    assert_equal false, Tenant.new.code_black_member
    assert_equal false, create_tenant!(organization: @org_a).code_black_member
  end

  test "S11 production kitchen cannot be a member" do
    kitchen = create_tenant!(organization: @org_a, type: "production_kitchen")

    kitchen.code_black_member = true
    assert_not kitchen.valid?
    assert_includes kitchen.errors[:code_black_member].join, "только для точки продаж"

    assert_raises(ActiveRecord::StatementInvalid) do
      kitchen.update_column(:code_black_member, true)
    end
  end

  test "S12 closed point stays in the network regardless of status" do
    closed = (Tenant::STATUSES.values - [ "active" ] + [ "inactive" ]).map do |status|
      create_tenant!(organization: @org_a, status: status, code_black_member: true)
    end

    assert_equal closed.map(&:id).sort, network_ids_among(*closed).sort
  end

  test "S13 status change does not change membership" do
    tenant = create_tenant!(organization: @org_a, code_black_member: true)

    %w[suspended blocked frozen warning active].each do |status|
      tenant.update!(status: status)
      assert tenant.reload.code_black_member, "membership lost on status #{status}"
    end

    outsider = create_tenant!(organization: @org_a)
    outsider.update!(status: "frozen")
    assert_not outsider.reload.code_black_member
  end

  private

  def network_ids_among(*tenants)
    Tenant.code_black_network.where(id: tenants.map(&:id)).pluck(:id)
  end
end
