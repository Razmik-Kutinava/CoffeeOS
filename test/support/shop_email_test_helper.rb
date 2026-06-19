# frozen_string_literal: true

module ShopEmailTestHelper
  def shop_tenant_headers(tenant_id)
    { "X-Shop-Tenant" => tenant_id.to_s }
  end

  def verify_shop_email!(tenant_id:, email:, session: self)
    session.post "/shop/api/email_otp/send",
      headers: shop_tenant_headers(tenant_id),
      params: { email: email },
      as: :json
    assert_equal 200, session.response.status, session.response.body

    session.post "/shop/api/email_otp/verify",
      headers: shop_tenant_headers(tenant_id),
      params: { email: email, code: "123456" },
      as: :json
    assert_equal 200, session.response.status, session.response.body
  end

  def shop_order_params(email:, name: "Shop Guest", payment_method: "cash", **extra)
    { email: email, name: name, payment_method: payment_method, **extra }
  end
end
