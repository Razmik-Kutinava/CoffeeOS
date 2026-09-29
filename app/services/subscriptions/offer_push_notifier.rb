# frozen_string_literal: true

module Subscriptions
  # TASK_96: push-оффер подписки на фактический переход состояния в shown.
  # Транспорт — существующий PushNotification + Shop::SendPushNotificationJob (FCM); registration flow не трогаем.
  # Один push на transition_key; ошибки не выходят наружу (presentation-flow и push статуса заказа не страдают).
  class OfferPushNotifier
    NOTIFICATION_TYPE = "subscription_offer"
    CHANNEL = "push"
    UTM_CAMPAIGN = "subscription_offer"
    UTM_CONTENT = "push_v1"
    TITLE = "Кофе по подписке"
    BODY = "Оформите подписку и экономьте на каждом заказе"
    # Экрана оформления подписки во frontend ещё нет (billing UI, Задача-3) — синхронно с OFFER_TARGET_PATH
    # в app/frontend/lib/subscriptionOffer.js.
    TARGET_URL = "/shop/#/profile"

    def self.call(customer:, point:, transition_key:)
      new(customer: customer, point: point, transition_key: transition_key).call
    end

    def initialize(customer:, point:, transition_key:)
      @customer = customer
      @point = point
      @transition_key = transition_key.to_s
    end

    def call
      return if @transition_key.blank?
      return if @customer.push_enabled_at.blank? || @customer.push_token.blank?
      return if purchased?

      notification = create_once
      return unless notification

      Shop::SendPushNotificationJob.perform_later(notification.id)
      notification
    rescue StandardError => e
      Rails.logger.warn("[Subscriptions::OfferPushNotifier] #{e.class}: #{e.message}")
      nil
    end

    private

    # Проверка already_sent? и create! сами по себе не атомарны: параллельные вызовы с одним
    # transition_key сериализуются advisory-локом до конца транзакции.
    def create_once
      PushNotification.transaction do
        conn = PushNotification.connection
        lock_key = "#{NOTIFICATION_TYPE}:#{@customer.id}:#{@transition_key}"
        conn.execute("SELECT pg_advisory_xact_lock(hashtext(#{conn.quote(lock_key)}))")
        next nil if already_sent?

        notification = PushNotification.create!(
          customer_id: @customer.id,
          tenant_id: @point.id,
          notification_type: NOTIFICATION_TYPE,
          title: TITLE,
          body: BODY,
          payload: {
            "type" => NOTIFICATION_TYPE,
            "offer_transition_key" => @transition_key,
            "tag" => "subscription-offer"
          },
          status: :pending
        )
        notification.update!(payload: notification.payload.merge("offer_url" => offer_url(notification.id)))
        notification
      end
    end

    def already_sent?
      PushNotification.where(customer_id: @customer.id, notification_type: NOTIFICATION_TYPE)
        .where("payload->>'offer_transition_key' = ?", @transition_key)
        .exists?
    end

    def purchased?
      return true if SubscriptionOfferState.find_by(customer_id: @customer.id)&.purchased?

      Subscription.for_customer(@customer.id).where(status: %i[active past_due]).exists?
    end

    def offer_url(notification_id)
      query = {
        offer_channel: CHANNEL,
        utm_campaign: UTM_CAMPAIGN,
        utm_content: UTM_CONTENT,
        push_notification_id: notification_id
      }.to_query
      "#{TARGET_URL}?#{query}"
    end
  end
end
