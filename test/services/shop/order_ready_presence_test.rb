# frozen_string_literal: true

require "test_helper"

# #39 шаг 2 [TDD-RED]: presence helper (Rails.cache order:{id}:online)
class Shop::OrderReadyPresenceTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @order_id = SecureRandom.uuid
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
  end

  test "#39 cache_key matches order:{id}:online" do
    assert_equal "order:#{@order_id}:online", Shop::OrderReadyPresence.cache_key(@order_id)
  end

  test "#39 mark_online! makes online? true" do
    Shop::OrderReadyPresence.mark_online!(@order_id)
    assert Shop::OrderReadyPresence.online?(@order_id)
  end

  test "#39 mark_offline! clears online flag" do
    Shop::OrderReadyPresence.mark_online!(@order_id)
    Shop::OrderReadyPresence.mark_offline!(@order_id)
    assert_not Shop::OrderReadyPresence.online?(@order_id)
  end

  test "#39 online? is false when key missing" do
    assert_not Shop::OrderReadyPresence.online?(@order_id)
  end

  # --- #82 Патч_1: SMS_GRACE suppress reconnect mark_online ---

  test "#82 P1 begin_sms_grace! marks offline and suppresses mark_online!" do
    Shop::OrderReadyPresence.mark_online!(@order_id)
    Shop::OrderReadyPresence.begin_sms_grace!(@order_id, duration: 15.seconds)

    assert Shop::OrderReadyPresence.in_sms_grace?(@order_id)
    assert_not Shop::OrderReadyPresence.online?(@order_id)

    Shop::OrderReadyPresence.mark_online!(@order_id)
    assert_not Shop::OrderReadyPresence.online?(@order_id),
               "Cable reconnect during SMS_GRACE must not set online"
  end

  test "#82 P1 mark_online! works again after grace key expires" do
    Shop::OrderReadyPresence.begin_sms_grace!(@order_id, duration: 1.second)
    travel 2.seconds do
      assert_not Shop::OrderReadyPresence.in_sms_grace?(@order_id)
      Shop::OrderReadyPresence.mark_online!(@order_id)
      assert Shop::OrderReadyPresence.online?(@order_id)
    end
  end
end
