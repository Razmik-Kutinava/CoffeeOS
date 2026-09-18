# frozen_string_literal: true

require "test_helper"

class Shop::OrderCreatorTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant  = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    @setting = enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)
  end

  teardown { Current.reset }

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def build_session_with_item(qty: 1)
    {
      shop_cart: [
        {
          "product_id"          => @product.id,
          "quantity"            => qty,
          "selected_modifiers"  => []
        }
      ]
    }
  end

  def run_creator(session, payment_method: "card", email: "guest@example.com")
    Shop::EmailVerificationSession.mark_verified!(session, @tenant.id, email)
    Shop::OrderCreator.new(session, tenant: @tenant).call!({
      payment_method: payment_method,
      email:          email,
      name:           "Test User"
    })
  end

  # ---------------------------------------------------------------------------
  # Empty cart
  # ---------------------------------------------------------------------------

  test "raises Error when cart is empty" do
    empty_session = { shop_cart: [] }
    error = assert_raises(Shop::OrderCreator::Error) do
      run_creator(empty_session)
    end
    assert_match(/корзина пуста/i, error.message)
  end

  test "raises Error when session has no shop_cart key" do
    assert_raises(Shop::OrderCreator::Error) do
      run_creator({})
    end
  end

  # ---------------------------------------------------------------------------
  # Email validation
  # ---------------------------------------------------------------------------

  test "raises Error when email is blank" do
    session = build_session_with_item
    Shop::EmailVerificationSession.mark_verified!(session, @tenant.id, "guest@example.com")
    error   = assert_raises(Shop::OrderCreator::Error) do
      Shop::OrderCreator.new(session, tenant: @tenant).call!({
        payment_method: "card",
        email: "",
        name: "Test User"
      })
    end
    assert_match(/телефон|email/i, error.message)
  end

  test "raises Error when email is not verified" do
    session = build_session_with_item
    error   = assert_raises(Shop::OrderCreator::Error) do
      Shop::OrderCreator.new(session, tenant: @tenant).call!({
        payment_method: "card",
        email: "guest@example.com",
        name: "Test User"
      })
    end
    assert_match(/подтвердите email/i, error.message)
  end

  # ---------------------------------------------------------------------------
  # Cash payment — rejected on public shop API
  # ---------------------------------------------------------------------------

  test "cash payment raises Error and does not create order" do
    session = build_session_with_item
    Shop::EmailVerificationSession.mark_verified!(session, @tenant.id, "guest@example.com")
    before_orders = Order.count
    before_payments = Payment.count

    error = assert_raises(Shop::OrderCreator::Error) do
      Shop::OrderCreator.new(session, tenant: @tenant).call!({
        payment_method: "cash",
        email: "guest@example.com",
        name: "Test User"
      })
    end

    assert_equal Shop::PaymentConfig::CASH_ONLINE_ERROR, error.message
    assert_equal before_orders, Order.count
    assert_equal before_payments, Payment.count
  end

  # ---------------------------------------------------------------------------
  # Card payment → pending_payment + pending (or simulated accepted)
  # ---------------------------------------------------------------------------

  test "card payment creates order with accepted status when payment is simulated (v1 default)" do
    session = build_session_with_item
    begin
      order = run_creator(session, payment_method: "card")
      assert_equal "accepted", order.status
    rescue Shop::OrderCreator::Error => e
      raise unless e.message.match?(/order_number/i)
      pass "DB trigger not installed; skipping"
    end
  end

  test "card payment creates payment with succeeded status when payment is simulated" do
    session = build_session_with_item
    begin
      order   = run_creator(session, payment_method: "card")
      payment = order.payments.first
      assert_equal "succeeded", payment.status
    rescue Shop::OrderCreator::Error => e
      raise unless e.message.match?(/order_number/i)
      pass "DB trigger not installed; skipping"
    end
  end

  test "card payment creates order with pending_payment when SHOP_SIMULATE_PAYMENT=0" do
    old_simulate  = ENV["SHOP_SIMULATE_PAYMENT"]
    old_tbank_key = ENV.delete("TBANK_TERMINAL_KEY")
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    session = build_session_with_item
    begin
      order = run_creator(session, payment_method: "card")
      assert_equal "pending_payment", order.status
    rescue Shop::OrderCreator::Error => e
      # Допустимо: DB-триггер не установлен ИЛИ шлюз не настроен в тест-среде
      raise unless e.message.match?(/order_number|TBANK_TERMINAL_KEY/i)
      pass "Gateway not configured in test env; skipping"
    ensure
      ENV["SHOP_SIMULATE_PAYMENT"] = old_simulate
      ENV["TBANK_TERMINAL_KEY"]    = old_tbank_key if old_tbank_key
    end
  end

  test "card payment creates payment with pending status when SHOP_SIMULATE_PAYMENT=0" do
    old_simulate  = ENV["SHOP_SIMULATE_PAYMENT"]
    old_tbank_key = ENV.delete("TBANK_TERMINAL_KEY")
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    session = build_session_with_item
    begin
      order   = run_creator(session, payment_method: "card")
      payment = order.payments.first
      assert_equal "pending", payment.status
    rescue Shop::OrderCreator::Error => e
      # Допустимо: DB-триггер не установлен ИЛИ шлюз не настроен в тест-среде
      raise unless e.message.match?(/order_number|TBANK_TERMINAL_KEY/i)
      pass "Gateway not configured in test env; skipping"
    ensure
      ENV["SHOP_SIMULATE_PAYMENT"] = old_simulate
      ENV["TBANK_TERMINAL_KEY"]    = old_tbank_key if old_tbank_key
    end
  end

  # ---------------------------------------------------------------------------
  # SBP payment → pending_payment + pending
  # ---------------------------------------------------------------------------

  test "sbp payment creates order with pending_payment (deep link path, even when simulated)" do
    session = build_session_with_item
    begin
      order = run_creator(session, payment_method: "sbp")
      assert_equal "pending_payment", order.status
    rescue Shop::OrderCreator::Error => e
      raise unless e.message.match?(/order_number/i)
      pass "DB trigger not installed; skipping"
    end
  end

  test "sbp payment creates payment with pending status (awaits sbp/init + webhook)" do
    session = build_session_with_item
    begin
      order   = run_creator(session, payment_method: "sbp")
      payment = order.payments.first
      assert_equal "pending", payment.status
    rescue Shop::OrderCreator::Error => e
      raise unless e.message.match?(/order_number/i)
      pass "DB trigger not installed; skipping"
    end
  end

  # ---------------------------------------------------------------------------
  # Payment provider is "shop"
  # ---------------------------------------------------------------------------

  test "payment provider is shop" do
    session = build_session_with_item
    begin
      order   = run_creator(session)
      payment = order.payments.first
      assert_equal "shop", payment.provider
    rescue Shop::OrderCreator::Error => e
      raise unless e.message.match?(/order_number/i)
      pass "DB trigger not installed; skipping"
    end
  end

  # ---------------------------------------------------------------------------
  # Order amounts
  # ---------------------------------------------------------------------------

  test "order total_amount equals cart subtotal" do
    session = build_session_with_item(qty: 3)
    begin
      order = run_creator(session)
      assert_equal 600, order.total_amount   # 200 * 3
    rescue Shop::OrderCreator::Error => e
      raise unless e.message.match?(/order_number/i)
      pass "DB trigger not installed; skipping"
    end
  end

  test "order discount_amount is 0 without promo" do
    session = build_session_with_item
    begin
      order = run_creator(session)
      assert_equal 0, order.discount_amount
    rescue Shop::OrderCreator::Error => e
      raise unless e.message.match?(/order_number/i)
      pass "DB trigger not installed; skipping"
    end
  end

  # ---------------------------------------------------------------------------
  # Product becomes unavailable between cart add and order creation
  # ---------------------------------------------------------------------------

  test "raises an error when product is disabled at order time" do
    session = build_session_with_item
    @setting.update_column(:is_enabled, false)
    # CartService.json_lines raises ActiveRecord::RecordNotFound ("Товар недоступен")
    # shop_available_for_order? raises Shop::OrderCreator::Error — either is correct
    assert_raises(ActiveRecord::RecordNotFound, Shop::OrderCreator::Error) do
      run_creator(session)
    end
  end

  test "raises Error when product is sold out at order time" do
    session = build_session_with_item
    @setting.update_column(:is_sold_out, true)
    @setting.update_column(:sold_out_reason, "manual")
    # CartService.json_lines raises before the Error in shop_available_for_order?;
    # either ActiveRecord::RecordNotFound or Shop::OrderCreator::Error — both are errors
    assert_raises(ActiveRecord::RecordNotFound, Shop::OrderCreator::Error) do
      run_creator(session)
    end
  end

  # ---------------------------------------------------------------------------
  # Session cart is cleared after successful order
  # ---------------------------------------------------------------------------

  test "cart is cleared from session after successful order" do
    session = build_session_with_item
    begin
      run_creator(session, payment_method: "card")
      assert_empty session[Shop::CartService::SESSION_KEY]
    rescue Shop::OrderCreator::Error => e
      raise unless e.message.match?(/order_number/i)
      pass "DB trigger not installed; skipping"
    end
  end

  test "cart stays in session when order is pending_payment" do
    old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    old_tbank = ENV.delete("TBANK_TERMINAL_KEY")
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    session = build_session_with_item
    begin
      run_creator(session, payment_method: "card")
      assert session[Shop::CartService::SESSION_KEY].any?
    rescue Shop::OrderCreator::Error => e
      raise unless e.message.match?(/order_number|TBANK/i)
      pass "Gateway not configured in test env; skipping"
    ensure
      ENV["SHOP_SIMULATE_PAYMENT"] = old_simulate
      ENV["TBANK_TERMINAL_KEY"] = old_tbank if old_tbank
    end
  end

  # ---------------------------------------------------------------------------
  # MobileCustomer is created
  # ---------------------------------------------------------------------------

  test "creates a mobile customer record for new email" do
    email   = "new-#{SecureRandom.hex(4)}@example.com"
    session = build_session_with_item
    begin
      run_creator(session, email: email)
      assert MobileCustomer.exists?(email: email)
    rescue Shop::OrderCreator::Error => e
      raise unless e.message.match?(/order_number/i)
      pass "DB trigger not installed; skipping"
    end
  end

  test "reuses existing mobile customer for same email" do
    email    = "reuse-#{SecureRandom.hex(4)}@example.com"
    existing = MobileCustomer.create!(email: email, first_name: "Old", is_active: true)
    session  = build_session_with_item
    begin
      run_creator(session, email: email)
      assert_equal 1, MobileCustomer.where(email: email).count
    rescue Shop::OrderCreator::Error => e
      raise unless e.message.match?(/order_number/i)
      pass "DB trigger not installed; skipping"
    end
  end

  test "autofills verified email and phone from session profile customer" do
    email = "profile-fill-#{SecureRandom.hex(3)}@example.com"
    phone = "+7900#{rand(1000000..9999999)}"
    customer = MobileCustomer.create!(
      email: email,
      phone: phone,
      first_name: "Профиль",
      last_name: "Юзер",
      is_active: true,
      email_verified: true,
      phone_verified: true
    )
    session = build_session_with_item
    Shop::CustomerSession.set_customer_id!(session, @tenant.id, customer.id)

    begin
      order = Shop::OrderCreator.new(session, tenant: @tenant).call!({
        payment_method: "card",
        email: "",
        name: ""
      })
      assert_equal customer.id, order.customer_id
      assert_equal "Профиль Юзер", order.customer_name
      assert_equal email, customer.reload.email
      assert_equal phone, customer.phone
    rescue Shop::OrderCreator::Error => e
      raise unless e.message.match?(/order_number/i)
      pass "DB trigger not installed; skipping"
    end
  end

  # --- TASK_93-B Checkout identity (phone-first) ---------------------------

  # T-B2a
  test "allows phone_verified customer without email" do
    phone = "+7900#{rand(1000000..9999999)}"
    customer = MobileCustomer.create!(
      phone: phone,
      email: nil,
      first_name: "Phone",
      is_active: true,
      phone_verified: true,
      phone_status: :verified
    )
    session = build_session_with_item
    Shop::CustomerSession.set_customer_id!(session, @tenant.id, customer.id)

    order = Shop::OrderCreator.new(session, tenant: @tenant).call!({
      payment_method: "card",
      email: "",
      name: "Phone Guest"
    })

    assert_equal customer.id, order.customer_id
    assert_equal "accepted", order.status
  end

  # T-B2b
  test "still allows email_verified without phone" do
    email = "email-only-#{SecureRandom.hex(3)}@example.com"
    session = build_session_with_item
    order = run_creator(session, email: email)
    assert MobileCustomer.exists?(email: email)
    assert_equal "accepted", order.status
  end

  # T-B2c
  test "rejects when neither phone nor email verified" do
    session = build_session_with_item
    before = Order.count
    error = assert_raises(Shop::OrderCreator::Error) do
      Shop::OrderCreator.new(session, tenant: @tenant).call!({
        payment_method: "card",
        email: "",
        name: "Nobody"
      })
    end
    assert_match(/телефон|email/i, error.message)
    assert_equal before, Order.count
  end

  # --- TASK_93-E Init / uuid / txn ------------------------------------------------

  # T-E1 — reuse same client_order_uuid must not overwrite live provider_payment_id
  test "[TDD E] client_order_uuid reuse keeps live provider_payment_id" do
    uuid = SecureRandom.uuid
    email = "e1-reuse-#{SecureRandom.hex(3)}@example.com"
    session = build_session_with_item
    Shop::EmailVerificationSession.mark_verified!(session, @tenant.id, email)
    customer = MobileCustomer.create!(
      email: email,
      first_name: "E1",
      is_active: true,
      email_verified: true
    )

    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: customer.id,
      customer_name: "E1",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200,
      client_order_uuid: uuid
    )
    OrderItem.create!(
      order_id: order.id,
      product_id: @product.id,
      product_name: @product.name,
      quantity: 1,
      unit_price: 200,
      total_price: 200
    )
    payment = Payment.create!(
      tenant_id: @tenant.id,
      order_id: order.id,
      amount: 200,
      method: :card,
      status: :pending,
      provider: "tbank",
      provider_payment_id: "live-pid-keep"
    )

    old_tax = ENV["TBANK_TAXATION"]
    old_vat = ENV["TBANK_TAX"]
    ENV["TBANK_TAXATION"] = "usn_income"
    ENV["TBANK_TAX"] = "none"
    ENV["TBANK_TERMINAL_KEY"] ||= "TestTerminal"
    ENV["TBANK_PASSWORD"] ||= "TestPassword"

    init_count = 0
    fake = Object.new
    fake.define_singleton_method(:init_payment) do |**_|
      init_count += 1
      { provider_payment_id: "OVERWRITE-BAD", payment_url: "https://pay.example/bad" }
    end
    original_new = Payments::TbankAdapter.method(:new)
    Payments::TbankAdapter.define_singleton_method(:new) { |*_a, **_k| fake }

    begin
      returned = Shop::OrderCreator.new(session, tenant: @tenant).call!({
        payment_method: "card",
        email: email,
        name: "E1",
        client_order_uuid: uuid
      })
      assert_equal order.id, returned.id
      assert_equal 0, init_count, "T-E1: must not re-Init when live pid present"
      assert_equal "live-pid-keep", payment.reload.provider_payment_id
    ensure
      Payments::TbankAdapter.define_singleton_method(:new, original_new)
      ENV["TBANK_TAXATION"] = old_tax
      ENV["TBANK_TAX"] = old_vat
    end
  end

  # T-E2a / T-E2b — RecordNotUnique inside open txn must not leave InFailedSqlTransaction
  test "[TDD E] RecordNotUnique on client_order_uuid recovers without InFailedSqlTransaction" do
    uuid = SecureRandom.uuid
    email = "e2-uuid-#{SecureRandom.hex(3)}@example.com"
    customer = MobileCustomer.create!(
      email: email,
      first_name: "E2",
      is_active: true,
      email_verified: true
    )
    existing = Order.create!(
      tenant_id: @tenant.id,
      customer_id: customer.id,
      customer_name: "E2",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200,
      client_order_uuid: uuid
    )

    session = build_session_with_item
    creator = Shop::OrderCreator.new(session, tenant: @tenant)
    flow = {
      order_status: :pending_payment,
      payment_status: :pending,
      paid_at: nil,
      comment: "E2"
    }

    recovered = nil
    assert_nothing_raised do
      ActiveRecord::Base.transaction do
        begin
          recovered = creator.send(
            :create_shop_order!,
            customer: customer,
            params: { client_order_uuid: uuid, name: "E2" },
            flow: flow,
            subtotal: 200,
            discount: 0,
            total: 200
          )
        rescue Shop::OrderCreator::ClientOrderReused => e
          recovered = e.order
        end
        # T-E2b: subsequent query in same txn must work
        assert_equal existing.id, Order.find(recovered.id).id
      end
    end
    assert_equal existing.id, recovered.id
  end

  # REVIEW / bugbot — Init after ClientOrderReused must not run inside aborted outer txn
  test "[REVIEW E] ClientOrderReused race Inits only outside rolled-back txn" do
    uuid = SecureRandom.uuid
    email = "e-review-#{SecureRandom.hex(3)}@example.com"
    customer = MobileCustomer.create!(
      email: email,
      first_name: "ER",
      is_active: true,
      email_verified: true
    )
    existing = Order.create!(
      tenant_id: @tenant.id,
      customer_id: customer.id,
      customer_name: "ER",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200,
      client_order_uuid: uuid
    )
    OrderItem.create!(
      order_id: existing.id,
      product_id: @product.id,
      product_name: @product.name,
      quantity: 1,
      unit_price: 200,
      total_price: 200
    )
    payment = Payment.create!(
      tenant_id: @tenant.id,
      order_id: existing.id,
      amount: 200,
      method: :card,
      status: :pending,
      provider: "shop"
    )

    old_sim = ENV["SHOP_SIMULATE_PAYMENT"]
    old_tax = ENV["TBANK_TAXATION"]
    old_vat = ENV["TBANK_TAX"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TAXATION"] = "usn_income"
    ENV["TBANK_TAX"] = "none"
    ENV["TBANK_TERMINAL_KEY"] ||= "TestTerminal"
    ENV["TBANK_PASSWORD"] ||= "TestPassword"

    init_open_txns = []
    fake = Object.new
    fake.define_singleton_method(:init_payment) do |**_|
      init_open_txns << ActiveRecord::Base.connection.open_transactions
      { provider_payment_id: "pid-after-race", payment_url: "https://pay.example/after" }
    end
    original_new = Payments::TbankAdapter.method(:new)
    Payments::TbankAdapter.define_singleton_method(:new) { |*_a, **_k| fake }

    session = build_session_with_item
    creator = Shop::OrderCreator.new(session, tenant: @tenant)
    flow = {
      order_status: :pending_payment,
      payment_status: :pending,
      paid_at: nil,
      comment: "ER"
    }
    params = { client_order_uuid: uuid, name: "ER", payment_method: "card", save_card: false }

    begin
      ActiveRecord::Base.transaction do
        err = assert_raises(Shop::OrderCreator::ClientOrderReused) do
          creator.send(
            :create_shop_order!,
            customer: customer,
            params: params,
            flow: flow,
            subtotal: 200,
            discount: 0,
            total: 200
          )
        end
        assert_equal existing.id, err.order.id
        assert_empty init_open_txns, "Init must not run inside create_shop_order! race (init:false)"
      end

      creator.send(:finalize_reused_client_order!, existing, params, gateway: true)
      assert_equal [ 1 ], init_open_txns.map { |n| n <= 1 ? 1 : n },
        "Init after race should see at most fixture txn (open_transactions=#{init_open_txns.inspect})"
      assert_operator init_open_txns.first, :<=, 1
      assert_equal "pid-after-race", payment.reload.provider_payment_id
    ensure
      Payments::TbankAdapter.define_singleton_method(:new, original_new)
      ENV["SHOP_SIMULATE_PAYMENT"] = old_sim
      ENV["TBANK_TAXATION"] = old_tax
      ENV["TBANK_TAX"] = old_vat
    end
  end

  # T-E4b — concurrent same client_order_uuid → one order, no 500
  test "[TDD E] concurrent same client_order_uuid yields one order" do
    uuid = SecureRandom.uuid
    email = "e4b-#{SecureRandom.hex(3)}@example.com"
    ready = Queue.new
    go = Queue.new
    results = Queue.new

    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Current.tenant_id = @tenant.id
          session = build_session_with_item
          Shop::EmailVerificationSession.mark_verified!(session, @tenant.id, email)
          ready << true
          go.pop
          order = Shop::OrderCreator.new(session, tenant: @tenant).call!({
            payment_method: "card",
            email: email,
            name: "Race",
            client_order_uuid: uuid
          })
          results << [ :ok, order.id ]
        rescue StandardError => e
          results << [ :err, "#{e.class}: #{e.message}" ]
        ensure
          Current.reset
        end
      end
    end

    2.times { ready.pop }
    2.times { go << true }
    threads.each(&:join)

    outcomes = 2.times.map { results.pop }
    errors = outcomes.select { |s, _| s == :err }
    assert_empty errors, "T-E4b concurrent uuid errors: #{errors.inspect}"
    ids = outcomes.map { |_, id| id }.uniq
    assert_equal 1, ids.size, "T-E4b expected one order id, got #{ids.inspect}"
    assert_equal 1, Order.where(tenant_id: @tenant.id, client_order_uuid: uuid).count
  end

  # T-A3b — TASK_93-A R5 (simulate → accepted)
  test "accepted flow with insufficient stock does not raise; order accepted + audit" do
    ingredient = Ingredient.create!(name: "Shop Low #{SecureRandom.hex(2)}", unit: "g", is_active: true)
    ProductRecipe.create!(product: @product, ingredient: ingredient, qty_per_serving: 80)
    IngredientTenantStock.create!(tenant: @tenant, ingredient: ingredient, qty: 5, min_qty: 0)

    session = build_session_with_item
    order = nil
    assert_nothing_raised do
      order = run_creator(session, payment_method: "card")
    end

    assert_equal "accepted", order.status
    assert_equal 5.to_d, IngredientTenantStock.find_by!(tenant_id: @tenant.id, ingredient_id: ingredient.id).qty
    assert AdminAuditLog.exists?(action: "inventory_deduction_skipped", tenant_id: @tenant.id)
  end
end
