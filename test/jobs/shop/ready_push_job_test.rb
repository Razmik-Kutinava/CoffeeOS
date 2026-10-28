# frozen_string_literal: true

require "test_helper"

# #35 B3 — ReadyPushJob: FCM + Apple Wallet (simulate / fallback) [TDD]
class Shop::ReadyPushJobTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(
      phone: "+79001113503",
      email: "ready-job-#{SecureRandom.hex(3)}@example.com"
    )
    @customer.update!(push_enabled: true, push_token: "fcm-ready-job")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Ready Job",
      order_number: "202607-3503",
      source: :mobile,
      status: :ready,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200,
      ready_notified_at: nil
    )
    ENV["WALLET_SIMULATE"] = "1"
    ENV["FCM_SIMULATE"] = "1"
  end

  teardown do
    ENV.delete("WALLET_SIMULATE")
    ENV.delete("FCM_SIMULATE")
    ENV.delete("WALLET_FORCE_UNAVAILABLE")
    ENV.delete("WALLET_FORCE_GEN_ERROR")
  end

  test "#35 B3 job delivers FCM and upserts wallet pass when simulated" do
    assert_difference -> { PushNotification.count } => 1,
                      -> { OrderWalletPass.count } => 1 do
      Shop::ReadyPushJob.perform_now(@order.id, "preparing")
    end

    note = PushNotification.order(created_at: :desc).first
    assert_equal "Заказ готов", note.title
    assert_match(/готов/i, note.body)
    assert_equal "sent", note.status

    pass = OrderWalletPass.find_by!(order_id: @order.id)
    assert_equal "ready", pass.status_label
    assert pass.serial_number.present?
    assert pass.authentication_token.present?
  end

  test "#35 B2 ready push body matches customer spec (order, not coffee)" do
    Shop::ReadyPushJob.perform_now(@order.id, "preparing")

    note = PushNotification.order(created_at: :desc).first
    progress = note.payload["progress"]

    assert_equal "#{progress} Ваш заказ готов, заберите на кассе!", note.body
  end

  test "#35 C1 ReadyPushJob claims ready_notified_at and sends push once" do
    @order.update!(ready_notified_at: nil)

    assert_difference -> { PushNotification.count } => 1 do
      Shop::ReadyPushJob.perform_now(@order.id, "preparing")
    end

    assert @order.reload.ready_notified_at.present?, "job must claim ready_notified_at"

    assert_no_difference -> { PushNotification.count } do
      Shop::ReadyPushJob.perform_now(@order.id, "preparing")
    end
  end

  test "#35 B3 wallet unavailable falls back to FCM only" do
    ENV["WALLET_FORCE_UNAVAILABLE"] = "1"

    assert_difference -> { PushNotification.count } => 1 do
      assert_no_difference -> { OrderWalletPass.count } do
        Shop::ReadyPushJob.perform_now(@order.id, "preparing")
      end
    end
  end

  test "TASK_92 P1 S4c pass generation error does not block FCM" do
    ENV["WALLET_FORCE_GEN_ERROR"] = "1"

    assert_difference -> { PushNotification.count } => 1 do
      Shop::ReadyPushJob.perform_now(@order.id, "preparing")
    end
    assert_equal "sent", PushNotification.order(created_at: :desc).first.status
  end

  test "#35 notifier enqueues ReadyPushJob on first ready" do
    fresh = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Fresh Ready",
      order_number: "202607-3503b",
      source: :mobile,
      status: :ready,
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150
    )

    assert_enqueued_with(job: Shop::ReadyPushJob, args: [ fresh.id, "preparing" ]) do
      Shop::OrderStatusPushNotifier.call(order: fresh, old_status: "preparing")
    end
    assert_nil fresh.reload.ready_notified_at
  end

  test "#35 notifier skips ReadyPushJob when already claimed" do
    assert Shop::ReadyPushClaim.claim!(@order.reload), "test precondition: must be claimed already"

    assert_no_enqueued_jobs(only: Shop::ReadyPushJob) do
      Shop::OrderStatusPushNotifier.call(order: @order.reload, old_status: "preparing")
    end
  end

  # --- #38 шаг 1 [TDD-RED]: ready FCM тоже с tag/actions/unicode ---

  test "#38 ready push payload has tag chat tips and unicode progress" do
    Shop::ReadyPushJob.perform_now(@order.id, "preparing")

    note = PushNotification.order(created_at: :desc).first
    assert_equal "order-#{@order.id}", note.payload["tag"]
    assert_equal %w[chat tips], note.payload["actions"]
    assert_equal "🟩🟩🟩", note.payload["progress"]
    assert_match(/\A🟩🟩🟩/, note.body)
  end

  # --- #38 шаг 4 [TDD-RED]: не дублировать Wallet hard на ready ---

  test "#38 ReadyPushJob skips PassUpdater when pass already at ready" do
    OrderWalletPass.create!(
      order_id: @order.id,
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      serial_number: "ser-#{SecureRandom.hex(8)}",
      authentication_token: SecureRandom.hex(16),
      pass_type_identifier: "pass.ru.coffeeos.order",
      status_label: "ready",
      revision: 3
    )

    Shop::ReadyPushJob.perform_now(@order.id, "preparing")

    pass = OrderWalletPass.find_by!(order_id: @order.id)
    assert_equal 3, pass.revision
    assert_equal "ready", pass.status_label
    assert PushNotification.order(created_at: :desc).first.present?
  end

  # --- TASK_92 Патч 1: ready-пуш не теряется при сбое доставки ---

  CLAIM_TIME = Time.zone.parse("2026-10-28 10:00:00")

  test "TASK_92 P1 S4 transient FCM error releases claim and re-enqueues with backoff" do
    travel_to(CLAIM_TIME) do
      with_fcm_raising(Shop::FcmClient::TransientError.new("FCM v1 503: unavailable")) do
        assert_enqueued_with(
          job: Shop::ReadyPushJob,
          args: [ @order.id, "preparing", { attempt: 2, claimed_at: CLAIM_TIME } ],
          at: CLAIM_TIME + 10.seconds
        ) do
          Shop::ReadyPushJob.perform_now(@order.id, "preparing")
        end
      end
    end

    assert_nil @order.reload.ready_notified_at, "claim must be released for retry"
    assert_equal "failed", last_ready_note.status
  end

  test "TASK_92 P1 S4 backoff grows with attempt number" do
    travel_to(CLAIM_TIME) do
      with_fcm_raising(Shop::FcmClient::TransientError.new("FCM v1 429: quota")) do
        assert_enqueued_with(
          job: Shop::ReadyPushJob,
          args: [ @order.id, "preparing", { attempt: 4, claimed_at: CLAIM_TIME } ],
          at: CLAIM_TIME + 2.minutes
        ) do
          Shop::ReadyPushJob.perform_now(@order.id, "preparing", attempt: 3, claimed_at: CLAIM_TIME)
        end
      end
    end
  end

  test "TASK_92 P1 S4 retries stop after last attempt and claim keeps original time" do
    with_fcm_raising(Shop::FcmClient::TransientError.new("FCM v1 503")) do
      assert_no_enqueued_jobs(only: Shop::ReadyPushJob) do
        Shop::ReadyPushJob.perform_now(
          @order.id, "preparing",
          attempt: Shop::ReadyPushJob::MAX_ATTEMPTS, claimed_at: CLAIM_TIME
        )
      end
    end

    assert_equal CLAIM_TIME, @order.reload.ready_notified_at
    assert_equal "failed", last_ready_note.status
  end

  test "TASK_92 P1 S4f retry re-claims with original time (SMS link anchor unchanged)" do
    travel_to(CLAIM_TIME + 3.minutes) do
      assert_difference -> { PushNotification.count } => 1 do
        Shop::ReadyPushJob.perform_now(@order.id, "preparing", attempt: 2, claimed_at: CLAIM_TIME)
      end
    end

    assert_equal CLAIM_TIME, @order.reload.ready_notified_at
    assert_equal "sent", last_ready_note.status
  end

  test "TASK_92 P1 S4e retry skips when another job already claimed" do
    Shop::ReadyPushJob.perform_now(@order.id, "preparing")

    assert_no_difference -> { PushNotification.count } do
      Shop::ReadyPushJob.perform_now(@order.id, "preparing", attempt: 2, claimed_at: CLAIM_TIME)
    end
  end

  test "TASK_92 P1 S4b permanent FCM error: no retry, failed, claim stays" do
    with_fcm_raising(Shop::FcmClient::Error.new("FCM v1 404: UNREGISTERED")) do
      assert_no_enqueued_jobs(only: Shop::ReadyPushJob) do
        Shop::ReadyPushJob.perform_now(@order.id, "preparing")
      end
    end

    assert @order.reload.ready_notified_at.present?
    assert_equal "failed", last_ready_note.status
  end

  test "TASK_92 P1 S4c APNs error does not block FCM" do
    original = Shop::AppleWallet::PassUpdater.method(:call!)
    Shop::AppleWallet::PassUpdater.define_singleton_method(:call!) do |**_kw|
      raise Shop::AppleWallet::ApnsClient::Error, "APNs Wallet push not configured"
    end

    assert_difference -> { PushNotification.count } => 1 do
      Shop::ReadyPushJob.perform_now(@order.id, "preparing")
    end
    assert_equal "sent", last_ready_note.status
  ensure
    Shop::AppleWallet::PassUpdater.singleton_class.send(:define_method, :call!, original)
  end

  test "TASK_92 P1 S4d unexpected delivery error leaves no pending notification" do
    with_fcm_raising(RuntimeError.new("boom")) do
      assert_raises(RuntimeError) do
        Shop::ReadyPushJob.perform_now(@order.id, "preparing")
      end
    end

    assert_equal "failed", last_ready_note.status
    assert @order.reload.ready_notified_at.present?
  end

  test "TASK_92 P1 S4g network error to FCM is retried (real FcmClient)" do
    with_real_fcm! do |client_email|
      Rails.cache.write("fcm:oauth:#{client_email}", "oauth-cached", expires_in: 1.hour)
      with_net_http_raising(SocketError.new("getaddrinfo: Temporary failure")) do
        assert_enqueued_with(job: Shop::ReadyPushJob) do
          Shop::ReadyPushJob.perform_now(@order.id, "preparing")
        end
      end
    end

    assert_nil @order.reload.ready_notified_at
    assert_equal "failed", last_ready_note.status
  end

  test "TASK_92 P1 S4g OAuth failure is retried (real FcmClient)" do
    with_real_fcm! do
      with_net_http_raising(Net::OpenTimeout.new("oauth2.googleapis.com")) do
        assert_enqueued_with(job: Shop::ReadyPushJob) do
          Shop::ReadyPushJob.perform_now(@order.id, "preparing")
        end
      end
    end

    assert_nil @order.reload.ready_notified_at
    assert_equal "failed", last_ready_note.status
  end

  private

  def last_ready_note
    PushNotification.where(customer_id: @customer.id).order(created_at: :desc).first
  end

  def with_fcm_raising(error)
    original = Shop::FcmClient.method(:deliver!)
    Shop::FcmClient.define_singleton_method(:deliver!) { |**_kw| raise error }
    yield
  ensure
    Shop::FcmClient.singleton_class.send(:define_method, :deliver!, original)
  end

  def with_net_http_raising(error)
    original = Net::HTTP.method(:start)
    Net::HTTP.define_singleton_method(:start) { |*_args, **_kw, &_blk| raise error }
    yield
  ensure
    Net::HTTP.singleton_class.send(:define_method, :start, original)
  end

  def with_real_fcm!
    saved = ENV.to_h.slice("FIREBASE_SERVICE_ACCOUNT_JSON", "FIREBASE_PROJECT_ID")
    client_email = "fcm-p1@coffeeos-test.iam.gserviceaccount.com"
    ENV.delete("FCM_SIMULATE")
    ENV["FIREBASE_SERVICE_ACCOUNT_JSON"] = JSON.generate(
      "client_email" => client_email,
      "private_key" => OpenSSL::PKey::RSA.generate(2048).to_pem,
      "project_id" => "coffeeos-test"
    )
    ENV["FIREBASE_PROJECT_ID"] = "coffeeos-test"
    Shop::FirebaseConfig.reset_cache!
    Rails.cache.clear
    yield client_email
  ensure
    %w[FIREBASE_SERVICE_ACCOUNT_JSON FIREBASE_PROJECT_ID].each do |key|
      saved.key?(key) ? ENV[key] = saved[key] : ENV.delete(key)
    end
    Shop::FirebaseConfig.reset_cache!
    Rails.cache.clear
  end
end
