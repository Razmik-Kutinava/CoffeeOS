# frozen_string_literal: true

require "test_helper"

# TASK_97 [TDD][RED] Subtask 4 / Проверка: idempotency push-оффера при параллельных вызовах.
# Транзакционные тесты шарят одно соединение между потоками (вызовы сериализуются) —
# здесь реальные отдельные соединения, поэтому записи чистим вручную в teardown.
module Subscriptions
  class OfferPushConcurrencyTest < ActiveSupport::TestCase
    include TestFactories

    self.use_transactional_tests = false

    THREADS = 4

    setup do
      @tenant = create_tenant!(slug: "offer-race-#{SecureRandom.hex(3)}")
      @customer = create_mobile_customer!(email: "opc-#{SecureRandom.hex(4)}@example.com")
      @customer.update!(push_enabled: true, push_token: "fcm-race-token", push_enabled_at: Time.current,
                        pwa_installed_at: Time.current)
      @setting = SubscriptionOfferSetting.create!(
        point_id: @tenant.id,
        enabled: true,
        second_cta_mode: "subscription",
        min_completed_orders: 1,
        required_signals_count: 1
      )
      Order.create!(
        tenant_id: @tenant.id,
        customer_id: @customer.id,
        customer_name: "Guest",
        order_number: "97-#{SecureRandom.hex(3)}",
        source: :mobile,
        status: :issued,
        total_amount: 100,
        discount_amount: 0,
        final_amount: 100
      )
    end

    teardown do
      next unless @customer

      MarketingEvent.where(customer_id: @customer.id).delete_all
      PushNotification.where(customer_id: @customer.id).delete_all
      SubscriptionOfferState.where(customer_id: @customer.id).delete_all
      Order.where(customer_id: @customer.id).delete_all
      @setting&.destroy
      MobileCustomer.where(id: @customer.id).delete_all
      @tenant&.destroy
    end

    def offer_pushes
      PushNotification.where(customer_id: @customer.id, notification_type: OfferPushNotifier::NOTIFICATION_TYPE)
    end

    def run_concurrently(count)
      ready = Queue.new
      go = Queue.new
      errors = Queue.new
      threads = Array.new(count) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            ready << true
            go.pop
            yield
          rescue StandardError => e
            errors << e
          end
        end
      end
      count.times { ready.pop }
      count.times { go << true }
      threads.each(&:join)
      failures = []
      failures << errors.pop until errors.empty?
      assert_empty failures.map { |e| "#{e.class}: #{e.message}" }
    end

    def with_slow_create
      original = PushNotification.method(:create!)
      PushNotification.define_singleton_method(:create!) do |*args, **kwargs, &blk|
        sleep 0.3
        original.call(*args, **kwargs, &blk)
      end
      yield
    ensure
      PushNotification.define_singleton_method(:create!, original)
    end

    test "parallel mark_shown for one guest → exactly one transition, one push, one banner_shown" do
      results = Queue.new
      run_concurrently(THREADS) do
        customer = MobileCustomer.find(@customer.id)
        results << OfferPresentationService.new(customer: customer, point: @tenant).mark_shown
      end

      outcomes = []
      outcomes << results.pop until results.empty?
      assert_equal 1, outcomes.count(true), "ровно один поток фиксирует переход, got=#{outcomes.inspect}"
      assert_equal 1, offer_pushes.count
      assert_equal 1, MarketingEvent.where(customer_id: @customer.id, event_type: "banner_shown").count
    end

    test "parallel OfferPushNotifier.call with the same transition_key → one push" do
      with_slow_create do
        run_concurrently(2) do
          customer = MobileCustomer.find(@customer.id)
          OfferPushNotifier.call(customer: customer, point: @tenant, transition_key: "race-key-1")
        end
      end

      assert_equal 1, offer_pushes.count
    end
  end
end
